# ---------------------------------------------------------------------------------------------------------------------
# AAP Admin Group Bindings
# ---------------------------------------------------------------------------------------------------------------------

## Global permission
resource "rancher2_global_role_binding" "global_binding_aap_admin" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.global_binding}-${local.keycloak_groups.aap_admin}"
  global_role_id     = "user-base"
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.aap_admin}"
}

## Project permissions
### Default Project
resource "rancher2_project_role_template_binding" "project_default_binding_aap_admin" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.project_default_binding}-${local.keycloak_groups.aap_admin}"
  project_id         = data.rancher2_project.default_project.id
  role_template_id   = "project-owner"
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.aap_admin}"
}

### Default Project
resource "rancher2_project_role_template_binding" "project_system_binding_aap_admin" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.project_system_binding}-${local.keycloak_groups.aap_admin}"
  project_id         = data.rancher2_project.system_project.id
  role_template_id   = "project-owner"
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.aap_admin}"
}

### AAP Tools Project
resource "rancher2_project_role_template_binding" "project_aap_tools_binding_aap_admin" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.project_aap_tools_binding}-${local.keycloak_groups.aap_admin}"
  project_id         = rancher2_project.aap_tools_project.id
  role_template_id   = "project-owner"
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.aap_admin}"
}

### AAP Default Project
resource "rancher2_project_role_template_binding" "project_aap_default_binding_aap_admin" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.project_aap_default_binding}-${local.keycloak_groups.aap_admin}"
  project_id         = rancher2_project.aap_default_project.id
  role_template_id   = "project-owner"
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.aap_admin}"
}

## Cluster permissions
resource "rancher2_cluster_role_template_binding" "cluster_binding_aap_admin" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.cluster_member_binding}-${local.keycloak_groups.aap_admin}"
  cluster_id         = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
  role_template_id   = "cluster-owner"
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.aap_admin}"
}



# ---------------------------------------------------------------------------------------------------------------------
# DevOps Group Bindings
# ---------------------------------------------------------------------------------------------------------------------

## Global permission
resource "rancher2_global_role_binding" "global_binding_devops" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.global_binding}-${local.keycloak_groups.devops}"
  global_role_id     = "user-base"
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.devops}"
}


## Project permissions
### AAP Tools Project
resource "rancher2_project_role_template_binding" "project_aap_tools_binding_devops" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.project_aap_tools_binding}-${local.keycloak_groups.devops}"
  project_id         = rancher2_project.aap_tools_project.id
  role_template_id   = data.rancher2_role_template.devops_project_role.id
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.devops}"
}

### AAP Default Project
resource "rancher2_project_role_template_binding" "project_aap_default_binding_devops" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.project_aap_default_binding}-${local.keycloak_groups.devops}"
  project_id         = rancher2_project.aap_default_project.id
  role_template_id   = data.rancher2_role_template.solution_member_project_role.id
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.devops}"
}

## Cluster permissions
resource "rancher2_cluster_role_template_binding" "cluster_binding_devops" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.cluster_member_binding}-${local.keycloak_groups.devops}"
  cluster_id         = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
  role_template_id   = data.rancher2_role_template.aap_cluster_member_role.id
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.devops}"
}


# ---------------------------------------------------------------------------------------------------------------------
# Developer Group Bindings
# ---------------------------------------------------------------------------------------------------------------------

## Global permission
resource "rancher2_global_role_binding" "global_binding_developer" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.global_binding}-${local.keycloak_groups.developer}"
  global_role_id     = "user-base"
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.developer}"
}

## Project permissions
### AAP Default Project
resource "rancher2_project_role_template_binding" "project_aap_default_binding_developer" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.project_aap_default_binding}-${local.keycloak_groups.developer}"
  project_id         = rancher2_project.aap_default_project.id
  role_template_id   = data.rancher2_role_template.solution_member_project_role.id
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.developer}"
}

## Cluster permissions
resource "rancher2_cluster_role_template_binding" "cluster_binding_developer" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.cluster_member_binding}-${local.keycloak_groups.developer}"
  cluster_id         = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
  role_template_id   = data.rancher2_role_template.aap_cluster_member_role.id
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.developer}"
}


# ---------------------------------------------------------------------------------------------------------------------
# user Group Bindings
# ---------------------------------------------------------------------------------------------------------------------

## Global permission
resource "rancher2_global_role_binding" "global_binding_user" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.global_binding}-${local.keycloak_groups.user}"
  global_role_id     = "user-base"
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.user}"
}

## Project permissions
### AAP Default Project
resource "rancher2_project_role_template_binding" "project_aap_default_binding_user" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.project_aap_default_binding}-${local.keycloak_groups.user}"
  project_id         = rancher2_project.aap_default_project.id
  role_template_id   = "read-only"
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.user}"
}


## Cluster permissions
resource "rancher2_cluster_role_template_binding" "cluster_binding_user" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.cluster_member_binding}-${local.keycloak_groups.user}"
  cluster_id         = rancher2_cluster_v2.rke2_cluster.cluster_v1_id
  role_template_id   = data.rancher2_role_template.aap_cluster_member_role.id
  group_principal_id = "${local.keycloak_group_principal_prefix}://${local.keycloak_groups.user}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Solution Group Bindings
# ---------------------------------------------------------------------------------------------------------------------
resource "rancher2_project_role_template_binding" "project_solution_binding_member" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  for_each           = toset(var.solution_projects)
  provider           = rancher2.admin
  name               = "${local.rancher_shortcuts.project_solution_binding}-${var.cluster_data.name}-rancher-${lower(each.key)}-member"
  project_id         = rancher2_project.aap_solution_projects[each.key].id
  role_template_id   = data.rancher2_role_template.solution_member_project_role.id
  group_principal_id = "${local.keycloak_group_principal_prefix}://${var.cluster_data.name}-rancher-${lower(each.key)}-member"
}