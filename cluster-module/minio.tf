resource "minio_s3_bucket" "cluster_etcd_backup" {
  depends_on = [
    vsphere_virtual_machine.worker,
    vsphere_virtual_machine.master_fix_ip,
    vsphere_virtual_machine.master
  ]
  bucket        = "${var.cluster_data.name}-etcd-backup"
  force_destroy = false
}

resource "minio_iam_user" "cluster_etcd_backup" {
  depends_on = [
    minio_s3_bucket.cluster_etcd_backup
  ]
  name = "${var.cluster_data.name}-etcd-backup-user"
}

resource "minio_iam_service_account" "access_credentials" {
  depends_on = [
    minio_s3_bucket.cluster_etcd_backup
  ]
  target_user = minio_iam_user.cluster_etcd_backup.id
}

resource "minio_iam_policy" "cluster_etcd_backup" {
  depends_on = [
    minio_s3_bucket.cluster_etcd_backup
  ]
  name   = "${var.cluster_data.name}-etcd-backup-policy"
  policy = data.minio_iam_policy_document.cluster_etcd_backup.json
}

resource "minio_iam_user_policy_attachment" "bucket_access" {
  depends_on = [
    minio_s3_bucket.cluster_etcd_backup
  ]
  user_name   = minio_iam_user.cluster_etcd_backup.id
  policy_name = minio_iam_policy.cluster_etcd_backup.id
}