resource "vsphere_folder" "cluster_folder" {
  path          = "${var.datasource.vsphere_folder_base}/${upper(var.cluster_data.platform)}/${var.cluster_data.name}"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "master" {
  depends_on = [
    vsphere_folder.cluster_folder
  ]

  count = var.vm.master.network_cidr == null ? var.cluster_data.master_node_count : 0

  resource_pool_id     = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
  folder               = "${var.datasource.vsphere_folder_base}/${upper(var.cluster_data.platform)}/${var.cluster_data.name}"

  name     = format("${var.cluster_data.name}-${var.manager_node_suffix}%02d", count.index + 1)
  num_cpus = var.vm.master.cpu_count
  memory   = var.vm.master.memory_size
  guest_id = data.vsphere_virtual_machine.template.guest_id

  cpu_hot_add_enabled    = true
  memory_hot_add_enabled = true

  disk {
    label            = "disk0"
    size             = var.vm.master.disk_size
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  vapp {
    properties = {
      "user-data" = base64encode(data.template_file.userdata-master.rendered)
      "hostname"  = format("${var.cluster_data.name}-${var.manager_node_suffix}%02d", count.index + 1)
    }
  }
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
    connection {
      host        = format("${var.cluster_data.name}-${var.manager_node_suffix}%02d.${var.cluster_data.domain}", count.index + 1)
      type        = "ssh"
      user        = var.ssh_username
      private_key = base64decode(var.tf_sshkey)
    }
  }

  lifecycle {
    ignore_changes = [
      clone[0].template_uuid,
      vapp[0].properties,
      num_cpus,
      memory,
      guest_id,
      disk[0].size,
      disk[0].thin_provisioned
    ]
  }
}


resource "vsphere_virtual_machine" "master_fix_ip" {
  depends_on = [
    vsphere_folder.cluster_folder
  ]

  count = var.vm.master.network_cidr != null ? var.cluster_data.master_node_count : 0

  resource_pool_id     = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
  folder               = "${var.datasource.vsphere_folder_base}/${upper(var.cluster_data.platform)}/${var.cluster_data.name}"

  name     = format("${var.cluster_data.name}-${var.manager_node_suffix}%02d", count.index + 1)
  num_cpus = var.vm.master.cpu_count
  memory   = var.vm.master.memory_size
  guest_id = data.vsphere_virtual_machine.template.guest_id

  cpu_hot_add_enabled    = true
  memory_hot_add_enabled = true

  disk {
    label            = "disk0"
    size             = var.vm.master.disk_size
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      network_interface {
        ipv4_address = cidrhost(var.vm.master.network_cidr, var.vm.master.start_ip_count + count.index + 1)
        ipv4_netmask = regex("(?:/([0-9][0-9]))", var.vm.master.network_cidr)[0]
      }
      ipv4_gateway    = cidrhost(var.vm.master.network_cidr, 1)
      dns_server_list = ["10.72.115.222", "10.73.115.222"]
      linux_options {
        domain    = var.cluster_data.domain
        host_name = format("${var.cluster_data.name}-${var.manager_node_suffix}%02d", count.index + 1)
      }
    }
  }

  vapp {
    properties = {
      "user-data" = base64encode(data.template_file.userdata-master.rendered)
      "hostname"  = format("${var.cluster_data.name}-${var.manager_node_suffix}%02d", count.index + 1)
    }
  }
  provisioner "remote-exec" {
    inline = [
      <<-EOT
      # --- use sudo if we are not already root ---
      [ $(id -u) -eq 0 ] || exec sudo -n $0 $@
      rm -rf /etc/netplan/50-cloud-init.yaml
      cloud-init status --wait
      EOT
    ]
    connection {
      host        = format("${var.cluster_data.name}-${var.manager_node_suffix}%02d.${var.cluster_data.domain}", count.index + 1)
      type        = "ssh"
      user        = var.ssh_username
      private_key = base64decode(var.tf_sshkey)
    }
  }

  lifecycle {
    ignore_changes = [
      clone[0].template_uuid,
      clone[0].customize[0],
      vapp[0].properties,
      num_cpus,
      memory,
      guest_id,
      disk[0].size,
      disk[0].thin_provisioned
    ]
  }
}

resource "vsphere_virtual_machine" "worker" {
  depends_on = [
    vsphere_folder.cluster_folder
  ]

  count = var.cluster_data.worker_node_count

  resource_pool_id     = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_cluster_id = data.vsphere_datastore_cluster.datastore_cluster.id
  folder               = "${var.datasource.vsphere_folder_base}/${upper(var.cluster_data.platform)}/${var.cluster_data.name}"

  name     = format("${var.cluster_data.name}-${var.worker_node_suffix}%02d", count.index + 1)
  num_cpus = var.vm.worker.cpu_count
  memory   = var.vm.worker.memory_size
  guest_id = data.vsphere_virtual_machine.template.guest_id

  cpu_hot_add_enabled    = true
  memory_hot_add_enabled = true

  disk {
    label            = "disk0"
    size             = var.vm.worker.disk_size
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  vapp {
    properties = {
      "user-data" = base64encode(data.template_file.userdata-worker.rendered)
      "hostname"  = format("${var.cluster_data.name}-${var.worker_node_suffix}%02d", count.index + 1)
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
    connection {
      host        = format("${var.cluster_data.name}-${var.worker_node_suffix}%02d.${var.cluster_data.domain}", count.index + 1)
      type        = "ssh"
      user        = var.ssh_username
      private_key = base64decode(var.tf_sshkey)
    }
  }

  lifecycle {
    ignore_changes = [
      clone[0].template_uuid,
      vapp[0].properties,
      num_cpus,
      memory,
      guest_id,
      disk[0].size,
      disk[0].thin_provisioned
    ]
  }
}

resource "null_resource" "salt_key_worker_nodes" {
  depends_on = [vsphere_virtual_machine.worker]
  count      = var.cluster_data.worker_node_count
  triggers = {
    conn_user        = var.ssh_username
    conn_private_key = base64decode(var.tf_sshkey)
    conn_host        = var.salt-master
    worker_node      = format("${var.cluster_data.name}-${var.worker_node_suffix}%02d.${var.cluster_data.domain}", count.index + 1)
  }
  connection {
    type        = "ssh"
    user        = self.triggers.conn_user
    private_key = self.triggers.conn_private_key
    host        = self.triggers.conn_host
  }

  provisioner "remote-exec" {
    inline = [
      "export hostname=$(hostname)",
      "echo 'Accepting Key for host ${self.triggers.worker_node} on Salt Master '$hostname",
      "if sudo salt-key -l acc | grep -w -q '${self.triggers.worker_node}'; then echo 'Node ${self.triggers.worker_node} has already an accepted key'; else sudo salt-key -y -a ${self.triggers.worker_node}; fi"
    ]
  }
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "export hostname=$(hostname)",
      "echo 'Deleting Key for host ${self.triggers.worker_node} on Salt Master '$hostname",
      "sudo salt-key -y -d ${self.triggers.worker_node}"
    ]
  }
}

resource "null_resource" "salt_key_master_nodes" {
  depends_on = [vsphere_virtual_machine.master,
  vsphere_virtual_machine.master_fix_ip]
  count = var.cluster_data.master_node_count
  triggers = {
    conn_user        = var.ssh_username
    conn_private_key = base64decode(var.tf_sshkey)
    conn_host        = var.salt-master
    worker_node      = format("${var.cluster_data.name}-${var.manager_node_suffix}%02d.${var.cluster_data.domain}", count.index + 1)
  }
  connection {
    type        = "ssh"
    user        = self.triggers.conn_user
    private_key = self.triggers.conn_private_key
    host        = self.triggers.conn_host
  }

  provisioner "remote-exec" {
    inline = [
      "export hostname=$(hostname)",
      "echo 'Accepting Key for host ${self.triggers.worker_node} on Salt Master '$hostname",
      "if sudo salt-key -l acc | grep -w -q '${self.triggers.worker_node}'; then echo 'Node ${self.triggers.worker_node} has already an accepted key'; else sudo salt-key -y -a ${self.triggers.worker_node}; fi"
    ]
  }
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "export hostname=$(hostname)",
      "echo 'Deleting Key for host ${self.triggers.worker_node} on Salt Master '$hostname",
      "sudo salt-key -y -d ${self.triggers.worker_node}"
    ]
  }
}
