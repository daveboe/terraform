resource "rancher2_cloud_credential" "cluster_etcd_backup_s3_cred" {
  provider = rancher2.admin
  name     = "${var.cluster_data.name}-etcd-backup"
  s3_credential_config {
    access_key       = minio_iam_service_account.access_credentials.access_key
    secret_key       = minio_iam_service_account.access_credentials.secret_key
    default_bucket   = minio_s3_bucket.cluster_etcd_backup.bucket
    default_endpoint = var.cluster_data.etcd.s3_endpoint
    default_folder   = ""
  }
}

resource "rancher2_secret_v2" "dockerhub_token" {
  provider   = rancher2.admin
  cluster_id = "local"
  name       = "${var.cluster_data.name}-registry-token"
  namespace  = "fleet-default"
  type       = "kubernetes.io/basic-auth"
  data = {
    password = dockerhub_token.cluster_token.token
    username = var.dockerhub.username
  }
}

resource "rancher2_cluster_v2" "rke2_cluster" {
  provider              = rancher2.admin
  name                  = var.cluster_data.name
  kubernetes_version    = var.cluster_data.k8s_version
  enable_network_policy = false

  local_auth_endpoint {
    enabled  = true
    ca_certs = ""
    fqdn     = ""
  }

  rke_config {
    chart_values = <<EOF
    rke2-cilium:
        encryption:
          enabled: true
          type: wireguard
        l7Proxy: false
        resources:
          limits:
            cpu: 4000m
            memory: 4Gi
          requests:
            cpu: 100m
            memory: 512Mi
        operator:
          resources:
            limits:
              cpu: 1000m
              memory: 1Gi
            requests:
              cpu: 100m
              memory: 128Mi
    EOF
    etcd {
      disable_snapshots      = false
      snapshot_retention     = var.cluster_data.etcd.snapshot_retention
      snapshot_schedule_cron = var.cluster_data.etcd.snapshot_cron
      s3_config {
        bucket                = minio_s3_bucket.cluster_etcd_backup.bucket
        cloud_credential_name = rancher2_cloud_credential.cluster_etcd_backup_s3_cred.id
        endpoint              = var.cluster_data.etcd.s3_endpoint
        endpoint_ca           = "-----BEGIN CERTIFICATE-----\nMIIFkzCCA3ugAwIBAgIUPmmM9AaLnIjrwI/NA+C8QM3sfRwwDQYJKoZIhvcNAQEL\nBQAwUTELMAkGA1UEBhMCQ0gxHjAcBgNVBAoMFUFicmF4YXMgSW5mb3JtYXRpayBB\nRzEiMCAGA1UEAwwZQWJyYXhhcyBTaGFyZWQgUm9vdCBDQSBHMTAeFw0yMDEwMzAx\nMDM3MTNaFw00MDEwMjUxMDM3MTNaMFExCzAJBgNVBAYTAkNIMR4wHAYDVQQKDBVB\nYnJheGFzIEluZm9ybWF0aWsgQUcxIjAgBgNVBAMMGUFicmF4YXMgU2hhcmVkIFJv\nb3QgQ0EgRzEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC4+TfEF5M7\nzrxU9YJXLzdtxWRGtCgEX9zQNa+AHIPxD1sKL5oCTap1Q14Xow+3gt8v0QOybhhH\nNp1faj6rzD0lYFaroiwz7XkM9vW4r0oeH/wdGGNoHHnO4FXNgn71tCrXlCb/3pqu\nPN/oJgUhMrzDZhWf46zWuZkfA2vNPz1QEBJ1uaGLYhPSjugqAMR43BmM/PBscN+d\ngZ3wp7mmWzOCXLAmtnT8xg4O25+NEsaSarsiq6rM2MLVkYbF+lHlfUQOlNeKaG2h\nNoJLQd61R+WMW9cUpZ9q/emJt7WYnEfXIMCZHF7yUDJuoEOj4muQALyWYfXL0+Xy\nnO81pC29DysLnKvh18OGoM7hZKfCCunDDvrB7iLiD8k4dKWWLPRfkvjAFkmjYGAS\nkDuhpPQtEkPvKNoJKhV1lBg6aQqmdMeRZDMckMjZjx5b3ikDwr4bUkl0Hy4d8Bd4\nxTUBECCAapDspS3+l7lwrWY1tCtmuEnW0iPy9Be4yAD71AOB16R7t5GU9sW4yFim\n/5KwXVtlnNaiBqev/JV9N7TBTuXrXHu9gon2zQ3kiv1UBKDDrBBGLHFzEIjsIOJI\n7gYagMO6J+EkcPeEoeB6hstv0qtQQr9UspiW+Q6QRr1YDqZFO2CzNRPnzoUwAtVs\nkyfD8klfCkRi5dELiqemBrSCiXrx8le/hwIDAQABo2MwYTAPBgNVHRMBAf8EBTAD\nAQH/MB8GA1UdIwQYMBaAFEsR5krOgvcYS1B8KZkUcMQTltjaMB0GA1UdDgQWBBRL\nEeZKzoL3GEtQfCmZFHDEE5bY2jAOBgNVHQ8BAf8EBAMCAYYwDQYJKoZIhvcNAQEL\nBQADggIBAI0o1LbYPmo5b5v1Z6Z8oTkABzobVomSr+D7lEFJsyUQ91al8gJNXNR+\nccWqFoAoechNCmOFVfUz5V31sH5U3vW8tyt0QztdauEs2JaDHAgPGgKsR8CSdAb9\nHXGZbcKQp4o0O17GDSsErMA92dYllFaZoZy4Wb2dcgGInp4Yn1RrNknqR32N7d9/\n28f9nYEvg93O0eDp39Spo1i0Fb96PzJXFn/IhhowmK/eUJlMXcr6qkwljJo9crSx\nI9oNRPSZ+Gv3rSOu+2KsNtfT83e1z0uUDStpM/GNCu/+yL6PGTfzckne131325SO\nbqGJM3C5KYiSP2NVyIeRmkupHMJM+Y2iQrsfz41OCKjtbKYeWwj8zXY5QKPVHBbD\nXOYj/4l7So4H97YD0WQvs0Kor7zILNsY1/jFPQqkqNPACD6ihqhtHqGXbjbEJ8tT\n2CLSEZzD5kHagP9majkFUgmGs6eOAYpaLq4fRj3RPjBh2T+bIsH/PRpP04MBlicA\n3yArEVmWvuISdMMjZkhdtuciHlzmPDM2wFKlFpCIaNgnuqUKF+JYZOtPjHwdir2Z\nRZoyCMUusogzxMGUOyLQn9qIMoRGw+45xvlQzccflW7Tysio4+43lZ3Ckc466sZ4\nBy1KRYg6J06A9NKbZLYgKo5X3YDXpYV59kFAARWbqI8Pzq0+H/1p\n-----END CERTIFICATE-----"
        skip_ssl_verify       = false
      }
    }
    # Kube Reserved Memory According to examples from Public Cloud Providers
    # https://learnk8s.io/allocatable-resources
    # 25% of the first 4GB of memory
    # 20% of the next 4GB of memory (up to 8GB)
    # Follow UP https://jira.abraxas-tools.ch/jira/browse/PS-1406
    machine_global_config = <<EOF
      # K8S POD CIDR
      cluster-cidr: 100.125.128.0/17
      # K8S Service CIDR
      service-cidr: 100.125.0.0/17
      # Cluster Domain Name
      cluster-domain: cluster.${var.cluster_data.name}
      cni: cilium
      disable:
      - rke2-ingress-nginx
      disable-kube-proxy: false
      etcd-expose-metrics: true
      profile: null
      kubelet-arg:
        - --resolv-conf=/etc/custom-resolv.conf
        - --logtostderr=true
        - --eviction-hard=memory.available<5%
        - --system-reserved=memory=1Gi
        - --system-reserved-cgroup=/system.slice
      kube-apiserver-arg:
        - --profiling=false
        - --audit-log-path=-
        - --audit-policy-file=/etc/audit-policy.yaml
      kube-controller-manager-arg:
        - --profiling=false
        - --terminated-pod-gc-threshold=10
      kube-scheduler-arg:
        - --profiling=false
    EOF
    # Due to this issue https://github.com/rancher/rancher/issues/38112 moved kubelet-arg to machine_global_config
    machine_selector_config {
      config = {
        protect-kernel-defaults : true
      }
    }

    registries {
      configs {
        hostname                = "registry-1.docker.io"
        auth_config_secret_name = rancher2_secret_v2.dockerhub_token.name
        tls_secret_name         = null
        ca_bundle               = ""
        insecure                = false
      }
    }

    upgrade_strategy {
      control_plane_concurrency = var.cluster_data.cp_concurrency
      control_plane_drain_options {
        delete_empty_dir_data                = true
        disable_eviction                     = false
        enabled                              = true
        force                                = false
        grace_period                         = -1
        ignore_daemon_sets                   = true
        skip_wait_for_delete_timeout_seconds = 0
        timeout                              = 120
      }
      worker_concurrency = var.cluster_data.worker_concurrency
      worker_drain_options {
        delete_empty_dir_data                = true
        disable_eviction                     = false
        enabled                              = true
        force                                = false
        grace_period                         = -1
        ignore_daemon_sets                   = true
        skip_wait_for_delete_timeout_seconds = 0
        timeout                              = 120
      }
    }
  }
}

resource "null_resource" "master_rke2_deployment" {
  depends_on = [
    rancher2_cluster_v2.rke2_cluster
  ]
  count = var.cluster_data.master_node_count

  triggers = {
    conn_user            = var.ssh_username
    conn_private_key     = base64decode(var.tf_sshkey)
    conn_host            = format("${var.cluster_data.name}-${var.manager_node_suffix}%02d.${var.cluster_data.domain}", count.index + 1)
    cluster_id           = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
    hostname             = format("${var.cluster_data.name}-${var.manager_node_suffix}%02d", count.index + 1)
    rancher_access_token = var.rancher2_token_key
    rancher_api_url      = var.rancher2_api_url
  }
  connection {
    type        = "ssh"
    user        = self.triggers.conn_user
    private_key = self.triggers.conn_private_key
    host        = self.triggers.conn_host
  }

  provisioner "file" {
    source      = "${path.module}/templates/policy.yaml"
    destination = "/tmp/audit-policy.yaml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/audit-policy.yaml /etc/audit-policy.yaml",
      "echo 'Executing Register Node Command'",
      "${replace("${rancher2_cluster_v2.rke2_cluster.cluster_registration_token[0].node_command}", "curl -fL", "wget -q -O -")} --etcd --controlplane"
    ]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "apk --update add bash"
  }

  provisioner "local-exec" {
    when        = destroy
    working_dir = "${path.module}/templates/"
    command     = "chmod +x drain_and_delete_node.sh  && ./drain_and_delete_node.sh ${self.triggers.cluster_id} ${self.triggers.hostname}"
    interpreter = ["bash", "-c"]
    environment = {
      ACCESS_TOKEN    = self.triggers.rancher_access_token
      RANCHER_API_URL = self.triggers.rancher_api_url
    }
  }

  provisioner "remote-exec" {
    on_failure = continue
    when       = destroy
    connection {
      timeout = "2m"
      type    = "ssh"
    }
    inline = [
      "echo 'Node has been removed'",
      "FILE=/usr/local/bin/rke2-uninstall.sh",
      "if [ -f $FILE ]; then sudo $FILE; else echo \"missing file $FILE\"; fi"
    ]
  }
}

resource "null_resource" "worker_rke2_deployment" {
  depends_on = [
    rancher2_cluster_v2.rke2_cluster
  ]

  count = var.cluster_data.worker_node_count

  triggers = {
    conn_user            = var.ssh_username
    conn_private_key     = base64decode(var.tf_sshkey)
    conn_host            = format("${var.cluster_data.name}-${var.worker_node_suffix}%02d.${var.cluster_data.domain}", count.index + 1)
    cluster_id           = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
    hostname             = format("${var.cluster_data.name}-${var.worker_node_suffix}%02d", count.index + 1)
    rancher_access_token = var.rancher2_token_key
    rancher_api_url      = var.rancher2_api_url
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = self.triggers.conn_user
      private_key = self.triggers.conn_private_key
      host        = self.triggers.conn_host
    }
    inline = [
      "echo 'Executing Register Node Command'",
      "${replace("${rancher2_cluster_v2.rke2_cluster.cluster_registration_token[0].node_command}", "curl -fL", "wget -q -O -")} --worker"
    ]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "apk --update add bash"
  }

  provisioner "local-exec" {
    when        = destroy
    working_dir = "${path.module}/templates/"
    command     = "chmod +x drain_and_delete_node.sh  && ./drain_and_delete_node.sh ${self.triggers.cluster_id} ${self.triggers.hostname}"
    interpreter = ["bash", "-c"]
    environment = {
      ACCESS_TOKEN    = self.triggers.rancher_access_token
      RANCHER_API_URL = self.triggers.rancher_api_url
    }
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    connection {
      timeout     = "2m"
      type        = "ssh"
      user        = self.triggers.conn_user
      private_key = self.triggers.conn_private_key
      host        = self.triggers.conn_host
    }
    inline = [
      "echo 'Node has been removed'",
      "FILE=/usr/local/bin/rke2-uninstall.sh",
      "if [ -f $FILE ]; then sudo $FILE; else echo \"missing file $FILE\"; fi"
    ]
  }
}

resource "rancher2_cluster_sync" "rke2_cluster_readiness" {
  depends_on = [
    null_resource.master_rke2_deployment,
    null_resource.worker_rke2_deployment
  ]
  provider      = rancher2.admin
  cluster_id    = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
  state_confirm = 2
}


resource "rancher2_project" "aap_tools_project" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider   = rancher2.admin
  name       = "AAP Tools"
  cluster_id = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
}

resource "rancher2_project" "aap_default_project" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider   = rancher2.admin
  name       = "AAP Default"
  cluster_id = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
}


resource "rancher2_project" "aap_solution_projects" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  for_each   = toset(var.solution_projects)
  provider   = rancher2.admin
  name       = each.key
  cluster_id = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
}