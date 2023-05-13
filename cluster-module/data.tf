locals {
  vsphere_ds_main      = upper(var.cluster_data.platform) == "COP" ? "${var.datasource.vsphere_ds_main}-01" : "${var.datasource.vsphere_ds_main}-02-AAP"
  vsphere_ds_dr        = upper(var.cluster_data.platform) == "COP" ? "${var.datasource.vsphere_ds_dr}-01" : "${var.datasource.vsphere_ds_dr}-02-AAP"
  vsphere_cluster_main = upper(var.cluster_data.platform) == "COP" ? "${var.datasource.vsphere_cluster_main}-01" : "${var.datasource.vsphere_cluster_main}-02"
  vsphere_cluster_dr   = upper(var.cluster_data.platform) == "COP" ? "${var.datasource.vsphere_cluster_dr}-01" : "${var.datasource.vsphere_cluster_dr}-01"
}

data "vsphere_datacenter" "datacenter" {
  name = var.datasource.vsphere_dc_name
}

data "vsphere_datastore_cluster" "datastore_cluster" {
  name          = var.cluster_data.is_dr_site ? local.vsphere_ds_dr : local.vsphere_ds_main
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster_data.is_dr_site ? local.vsphere_cluster_dr : local.vsphere_cluster_main
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.datasource.vm_template_folder}/${var.vm.template}"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.cluster_data.network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "rancher2_project" "default_project" {
  provider   = rancher2.admin
  cluster_id = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
  name       = "Default"
}
data "rancher2_project" "system_project" {
  provider   = rancher2.admin
  cluster_id = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
  name       = "System"
}

data "rancher2_role_template" "devops_project_role" {
  provider = rancher2.admin
  name     = "DevOps"
  context  = "project"
}

data "rancher2_role_template" "solution_member_project_role" {
  provider = rancher2.admin
  name     = "Solution Member"
  context  = "project"
}

data "rancher2_role_template" "aap_cluster_member_role" {
  provider = rancher2.admin
  name     = "Cluster Member"
  context  = "cluster"
}

data "keycloak_realm" "cf" {
  realm = var.keycloak_realm
}

data "minio_iam_policy_document" "cluster_etcd_backup" {
  statement {
    sid       = "ListObjectsInBucket"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::${minio_s3_bucket.cluster_etcd_backup.bucket}"]
  }
  statement {
    sid    = "AllObjectActions"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::${minio_s3_bucket.cluster_etcd_backup.bucket}/*"]
  }
}
