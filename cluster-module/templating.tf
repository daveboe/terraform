data "template_file" "userdata-master" {
  template = templatefile("${path.module}/templates/userdata.yaml", {
    cluster     = var.cluster_data.name
    is_dr_site  = var.cluster_data.is_dr_site
    stage       = var.cluster_data.stage
    node-role   = "master"
    template    = var.vm.template
    commands    = var.vm.master.commands
    packages    = var.vm.master.packages
    bootcmds    = var.vm.master.bootcmds
    salt-master = var.salt-master
  })
}
data "template_file" "userdata-worker" {
  template = templatefile("${path.module}/templates/userdata.yaml", {
    cluster     = var.cluster_data.name
    is_dr_site  = var.cluster_data.is_dr_site
    stage       = var.cluster_data.stage
    node-role   = "worker"
    template    = var.vm.template
    commands    = var.vm.worker.commands
    packages    = var.vm.worker.packages
    bootcmds    = var.vm.worker.bootcmds
    salt-master = var.salt-master
  })
}
