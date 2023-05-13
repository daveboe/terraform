resource "dockerhub_token" "cluster_token" {
  depends_on = [
    vsphere_virtual_machine.master,
    vsphere_virtual_machine.master_fix_ip,
    vsphere_virtual_machine.worker
  ]
  label  = "${var.cluster_data.platform} Rancher-${upper(var.cluster_data.name)}"
  scopes = ["repo:public_read"]
}