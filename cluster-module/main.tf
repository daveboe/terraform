locals {
  keycloak_group_principal_prefix = "keycloakoidc_group"
  keycloak_groups = {
    aap_admin = "${var.cluster_data.name}-rancher-aap-admin"
    devops    = "${var.cluster_data.name}-rancher-devops"
    developer = "${var.cluster_data.name}-rancher-developer"
    user      = "${var.cluster_data.name}-rancher-user"
  }
  rancher_shortcuts = {
    administrator_binding       = "ab"
    project_default_binding     = "pdb"
    project_system_binding      = "psb"
    project_aap_tools_binding   = "paaptb"
    project_aap_default_binding = "paapdb"
    project_solution_binding    = "psolb"
    cluster_member_binding      = "cmb"
    global_binding              = "gb"
  }

  keycloak_idp = tomap({
    secure-connect = {
      tenant_id = "1234"
    }
    secure-connect-pro-vo = {
      tenant_id = "45"
    }
  })

  keycloak_claim_template = [{
    key = "groups"
    value = "%s:%s"
  }]
}

