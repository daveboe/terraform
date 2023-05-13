terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.1.1"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 3.13.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 1.24.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.1"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.0.0"
    }
    dockerhub = {
      source  = "BarnabyShearer/dockerhub"
      version = "0.0.15"
    }
    minio = {
      source  = "aminueza/minio"
      version = "1.9.1"
    }
  }
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_passwd
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

provider "gitlab" {
  base_url = "https://gitlab.myorg.ch/api/v4/"
  token    = var.access_token
}

provider "rancher2" {
  alias     = "admin"
  api_url   = var.rancher2_api_url
  token_key = var.rancher2_token_key
}

provider "keycloak" {
  client_id                = "terraform"
  client_secret            = var.keycloak_client_secret
  url                      = var.keycloak_url
  base_path                = "/auth"
  tls_insecure_skip_verify = true
}

provider "minio" {
  minio_server   = "${var.cluster_data.etcd.s3_endpoint}:443"
  minio_user     = var.cluster_data.etcd.minio.user
  minio_password = var.cluster_data.etcd.minio.passwd
  minio_ssl      = true
  minio_insecure = true
}

provider "dockerhub" {
  username = var.dockerhub.username
  password = var.dockerhub.passwd
}