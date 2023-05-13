# ---------------------------------------------------------------------------------------------------------------------
# Keycloak Groups
# ---------------------------------------------------------------------------------------------------------------------

resource "keycloak_group" "parent_group" {
  depends_on = [
    rancher2_cluster_sync.rke2_cluster_readiness
  ]
  realm_id = data.keycloak_realm.cf.id
  name     = var.cluster_data.name
}

resource "keycloak_group" "intermediate_group" {
  realm_id  = data.keycloak_realm.cf.id
  parent_id = keycloak_group.parent_group.id
  name      = "${keycloak_group.parent_group.name}-rancher"
}

resource "keycloak_group" "child_group_aap_admin" {
  realm_id  = data.keycloak_realm.cf.id
  parent_id = keycloak_group.intermediate_group.id
  name      = local.keycloak_groups.aap_admin
}

resource "keycloak_group" "child_group_devops" {
  realm_id  = data.keycloak_realm.cf.id
  parent_id = keycloak_group.intermediate_group.id
  name      = local.keycloak_groups.devops
}

resource "keycloak_group" "child_group_developer" {
  realm_id  = data.keycloak_realm.cf.id
  parent_id = keycloak_group.intermediate_group.id
  name      = local.keycloak_groups.developer
}

resource "keycloak_group" "child_group_user" {
  realm_id  = data.keycloak_realm.cf.id
  parent_id = keycloak_group.intermediate_group.id
  name      = local.keycloak_groups.user
}

resource "keycloak_group" "child_group_solution_member" {
  for_each  = toset(var.solution_projects)
  realm_id  = data.keycloak_realm.cf.id
  parent_id = keycloak_group.intermediate_group.id
  name      = "${var.cluster_data.name}-rancher-${lower(each.key)}-member"
}

# ---------------------------------------------------------------------------------------------------------------------
# Keycloak OIDC Mapping Secure Connect
# ---------------------------------------------------------------------------------------------------------------------

# Code Documentation for claims:
# Target is to have a string like: "{\"key\":\"groups\",\"value\":\"(177778113432781596|382754863349675405):test1234\"}"
# As template there is a local variable keylcoak_claim_template with format function place holders for the tenant_id and group_name
# Additional there is an if else which handles if additional tenant_id needs to be put into a regex query conform value


resource "keycloak_custom_identity_provider_mapper" "aap_admin_mapper" {
  realm                    = data.keycloak_realm.cf.id
  name                     = "group mapper ${keycloak_group.child_group_aap_admin.name}"
  identity_provider_alias  = var.keycloak_idp_alias
  identity_provider_mapper = "oidc-advanced-group-idp-mapper"

  extra_config = {
    "claims" : format(
      jsonencode(local.keycloak_claim_template),
      var.keycloak_additional_tenant_ids == null ?
      local.keycloak_idp[var.keycloak_idp_alias].tenant_id :
      format("(%s)",
        join("|",
          concat(
            [local.keycloak_idp[var.keycloak_idp_alias].tenant_id],
            var.keycloak_additional_tenant_ids
          )
        )
      ),
    keycloak_group.child_group_aap_admin.name),
    "syncMode" : "FORCE",
    "are.claim.values.regex" : var.keycloak_additional_tenant_ids == null ? "false" : "true",
    "attributes" : "[]",
    "group" : "/${keycloak_group.parent_group.name}/${keycloak_group.intermediate_group.name}/${keycloak_group.child_group_aap_admin.name}"

  }
}

resource "keycloak_custom_identity_provider_mapper" "devops_mapper" {
  realm                    = data.keycloak_realm.cf.id
  name                     = "group mapper ${keycloak_group.child_group_devops.name}"
  identity_provider_alias  = var.keycloak_idp_alias
  identity_provider_mapper = "oidc-advanced-group-idp-mapper"

  extra_config = {
    "claims" : format(
      jsonencode(local.keycloak_claim_template),
      var.keycloak_additional_tenant_ids == null ?
      local.keycloak_idp[var.keycloak_idp_alias].tenant_id :
      format("(%s)",
        join("|",
          concat(
            [local.keycloak_idp[var.keycloak_idp_alias].tenant_id],
            var.keycloak_additional_tenant_ids
          )
        )
      ),
    keycloak_group.child_group_devops.name),
    "syncMode" : "FORCE",
    "are.claim.values.regex" : var.keycloak_additional_tenant_ids == null ? "false" : "true",
    "attributes" : "[]",
    "group" : "/${keycloak_group.parent_group.name}/${keycloak_group.intermediate_group.name}/${keycloak_group.child_group_devops.name}"

  }
}

resource "keycloak_custom_identity_provider_mapper" "developer_mapper" {
  realm                    = data.keycloak_realm.cf.id
  name                     = "group mapper ${keycloak_group.child_group_developer.name}"
  identity_provider_alias  = var.keycloak_idp_alias
  identity_provider_mapper = "oidc-advanced-group-idp-mapper"

  extra_config = {
    "claims" : format(
      jsonencode(local.keycloak_claim_template),
      var.keycloak_additional_tenant_ids == null ?
      local.keycloak_idp[var.keycloak_idp_alias].tenant_id :
      format("(%s)",
        join("|",
          concat(
            [local.keycloak_idp[var.keycloak_idp_alias].tenant_id],
            var.keycloak_additional_tenant_ids
          )
        )
      ),
    keycloak_group.child_group_developer.name),
    "syncMode" : "FORCE",
    "are.claim.values.regex" : var.keycloak_additional_tenant_ids == null ? "false" : "true",
    "attributes" : "[]",
    "group" : "/${keycloak_group.parent_group.name}/${keycloak_group.intermediate_group.name}/${keycloak_group.child_group_developer.name}"

  }
}

resource "keycloak_custom_identity_provider_mapper" "user_mapper" {
  realm                    = data.keycloak_realm.cf.id
  name                     = "group mapper ${keycloak_group.child_group_user.name}"
  identity_provider_alias  = var.keycloak_idp_alias
  identity_provider_mapper = "oidc-advanced-group-idp-mapper"

  extra_config = {
    "claims" : format(
      jsonencode(local.keycloak_claim_template),
      var.keycloak_additional_tenant_ids == null ?
      local.keycloak_idp[var.keycloak_idp_alias].tenant_id :
      format("(%s)",
        join("|",
          concat(
            [local.keycloak_idp[var.keycloak_idp_alias].tenant_id],
            var.keycloak_additional_tenant_ids
          )
        )
      ),
    keycloak_group.child_group_user.name),
    "syncMode" : "FORCE",
    "are.claim.values.regex" : var.keycloak_additional_tenant_ids == null ? "false" : "true",
    "attributes" : "[]",
    "group" : "/${keycloak_group.parent_group.name}/${keycloak_group.intermediate_group.name}/${keycloak_group.child_group_user.name}"
  }
}

resource "keycloak_custom_identity_provider_mapper" "solution_member_mapper" {
  for_each                 = toset(var.solution_projects)
  realm                    = data.keycloak_realm.cf.id
  name                     = "group mapper ${keycloak_group.child_group_solution_member[each.key].name}"
  identity_provider_alias  = var.keycloak_idp_alias
  identity_provider_mapper = "oidc-advanced-group-idp-mapper"

  extra_config = {
    "claims" : format(
      jsonencode(local.keycloak_claim_template),
      var.keycloak_additional_tenant_ids == null ?
      local.keycloak_idp[var.keycloak_idp_alias].tenant_id :
      format("(%s)",
        join("|",
          concat(
            [local.keycloak_idp[var.keycloak_idp_alias].tenant_id],
            var.keycloak_additional_tenant_ids
          )
        )
      ),
    keycloak_group.child_group_solution_member[each.key].name),
    "syncMode" : "FORCE",
    "are.claim.values.regex" : var.keycloak_additional_tenant_ids == null ? "false" : "true",
    "attributes" : "[]",
    "group" : "/${keycloak_group.parent_group.name}/${keycloak_group.intermediate_group.name}/${keycloak_group.child_group_solution_member[each.key].name}"
  }
}