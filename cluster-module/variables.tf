# ---------------------------------------------------------------------------------------------------------------------
# VMWARE PROVIDER VARIABLES
# These are used to connect to vCenter.
# ---------------------------------------------------------------------------------------------------------------------
variable "vsphere_user" {
  description = "vSphere username provided from Gitlab CI/CD env vars"
  type        = string
  sensitive   = true
}

variable "vsphere_passwd" {
  description = "vSphere username provided from Gitlab CI/CD env vars"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server to connect"
  type        = string
  default     = "vpvcapc01.abx-net.net"
}

# ---------------------------------------------------------------------------------------------------------------------
# Gitlab Variables
# These are used to interact with Gitlab.
# ---------------------------------------------------------------------------------------------------------------------
variable "access_token" {
  description = "Gitlab Access Token provided from Gitlab CI/CD env vars"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------------------------------------------------
# Rancher Variables
# These are used to interact with Rancher.
# ---------------------------------------------------------------------------------------------------------------------

variable "rancher2_token_key" {
  description = "Rancher Token Key"
  type        = string
  sensitive   = true
}

variable "rancher2_api_url" {
  description = "Rancher API Url"
  type        = string
  default     = "https://cop.abraxas-its.ch"
}

# ---------------------------------------------------------------------------------------------------------------------
# Keycloak Variables
# These are used to interact with Keycloak.
# ---------------------------------------------------------------------------------------------------------------------

variable "keycloak_client_secret" {
  description = "Client Secret of the Terraform Client in Keycloak Admin Realm"
  type        = string
  sensitive   = true
}

variable "keycloak_url" {
  description = "Keycloak Url"
  type        = string
  default     = "https://keycloak.green.cop.abx-net.net"
}

variable "keycloak_realm" {
  description = "Realm of Keycloak"
  type        = string
  default     = "container-foundation"
}

variable "keycloak_idp_alias" {
  description = "IDP which is Used to Login"
  type = string
  default = "secure-connect"
}

variable "keycloak_additional_tenant_ids" {
  description = "List of Additional Tenant ID's for mapping"
  type = list(string)
  default = null
}

# ---------------------------------------------------------------------------------------------------------------------
# VMWARE DATA SOURCE VARIABLES
# These are used to discover unmanaged resources used during deployment.
# ---------------------------------------------------------------------------------------------------------------------
variable "datasource" {
  description = ""
  type = object({
    vsphere_dc_name      = string
    vsphere_ds_main      = string
    vsphere_ds_dr        = string
    vsphere_cluster_main = string
    vsphere_cluster_dr   = string
    vsphere_folder_base  = string
    vm_template_folder   = string
  })
  default = {
    vsphere_dc_name      = "Abraxas"
    vsphere_ds_main      = "FC-LUP"
    vsphere_ds_dr        = "FC-GLB"
    vsphere_cluster_main = "lin-lup"
    vsphere_cluster_dr   = "lin-glb"
    vsphere_folder_base  = "/Linux"
    vm_template_folder   = "Linux/COP/templates"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# VMWARE RESOURCE VARIABLES
# Variables used during the creation of resources in vSphere.
# ---------------------------------------------------------------------------------------------------------------------
variable "cluster_data" {
  description = "Data belonging to the cluster "
  type = object({
    name               = string
    platform           = string
    is_dr_site         = bool
    network            = string
    domain             = string
    stage              = string
    master_node_count  = number
    worker_node_count  = number
    cp_concurrency     = number
    worker_concurrency = number
    k8s_version        = string
    etcd = object({
      snapshot_retention = optional(number, 5)
      snapshot_cron      = optional(string, "0 */5 * * *")
      s3_endpoint        = optional(string, "backup.cop.abraxas-its.ch")
      minio = object({
        user   = string
        passwd = string
      })
    })
  })
  validation {
    condition     = !can(regex("/", var.cluster_data.etcd.s3_endpoint))
    error_message = "S3 endpoint must not contain paths, only fqdn is allowed"
  }
  default = {
    platform           = "AAP" # AAP/COP
    name               = "t01"
    network            = "vlan-3063"
    is_dr_site         = false
    domain             = "t01.aap.abx-net.net"
    stage              = "prod"
    master_node_count  = 1
    worker_node_count  = 1
    cp_concurrency     = 1
    worker_concurrency = 1
    k8s_version        = "v1.23.10+rke2r1"
    etcd = {
      snapshot_retention = 5
      snapshot_cron      = "0 */5 * * *"
      s3_endpoint        = "backup.abraxas-tools.ch"
      minio = {
        user   = ""
        passwd = ""
      }
    }
  }
}

variable "vm" {
  description = "Settings for VMs to provision"
  type = object({
    master = object({
      cpu_count      = number
      memory_size    = number
      disk_size      = number
      packages       = optional(list(string), [])
      commands       = optional(list(string), [])
      bootcmds       = optional(list(string), [])
      network_cidr   = optional(string)
      start_ip_count = optional(number)
    })
    worker = object({
      cpu_count      = number
      memory_size    = number
      disk_size      = number
      packages       = optional(list(string), [])
      commands       = optional(list(string), [])
      bootcmds       = optional(list(string), [])
      network_cidr   = optional(string)
      start_ip_count = optional(number)
    })
    template = string
  })
  default = {
    template = "ubuntu-22.04-minimal-hardened"
    master = {
      cpu_count      = 2
      memory_size    = 8192
      disk_size      = 50
      packages       = []
      commands       = []
      bootcmds       = []
      network_cidr   = null
      start_ip_count = null
    }
    worker = {
      cpu_count      = 4
      memory_size    = 16384
      disk_size      = 50
      packages       = []
      commands       = []
      bootcmds       = []
      network_cidr   = null
      start_ip_count = null
    }
  }
}

variable "tf_sshkey" {
  description = "sshkey for user terraform provided from Gitlab CI/CD env vars"
  type        = string
  sensitive   = true
}

variable "solution_projects" {
  description = "array of solution projects which should be created"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------------------------------------------------
# Cloud-Init Variables
# These are used to create the cloud-init file or check cloud-init state.
# ---------------------------------------------------------------------------------------------------------------------

variable "salt-master" {
  description = "Domain name of the saltmaster"
  type        = string
  default     = "salt-master.green.cop.abx-net.net"
}

# ---------------------------------------------------------------------------------------------------------------------
# Helper Variables
# These are used to help templating diffent values (e.x. hostname suffix)
# ---------------------------------------------------------------------------------------------------------------------
variable "manager_node_suffix" {
  description = "Suffix for Manager Nodes"
  type        = string
  default     = "m"
}

variable "worker_node_suffix" {
  description = "Suffix for Manager Nodes"
  type        = string
  default     = "w"
}

variable "ssh_username" {
  description = "SSH User which is used to connect to vm's"
  type        = string
  default     = "terraform"
}

variable "dockerhub" {
  description = "Login Information about docker hub"
  type = object({
    username = string
    passwd   = string
  })
  sensitive = true
}