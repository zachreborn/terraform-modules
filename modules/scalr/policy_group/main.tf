###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

###########################
# Locals
###########################
locals {
  # Resolve each policy_group_linkages entry's policy_group_id: either a literal, externally-managed
  # ID, or a reference (by key) to a policy group created by this same module call.
  resolved_linkages = {
    for k, v in var.policy_group_linkages : k => {
      policy_group_id = v.policy_group_id != null ? v.policy_group_id : scalr_policy_group.this[v.policy_group_key].id
      environment_id  = v.environment_id
    }
  }
}

###########################
# Policy Groups
###########################
resource "scalr_policy_group" "this" {
  for_each = var.policy_groups

  name                    = coalesce(each.value.name, each.key)
  account_id              = each.value.account_id
  vcs_provider_id         = each.value.vcs_provider_id
  opa_version             = each.value.opa_version
  common_functions_folder = each.value.common_functions_folder
  environments            = each.value.environments

  vcs_repo {
    identifier = each.value.vcs_repo.identifier
    branch     = each.value.vcs_repo.branch
    path       = each.value.vcs_repo.path
  }
}

###########################
# Policy Group Linkages (companion submodule)
###########################
module "linkage" {
  source = "./linkage"

  linkages = local.resolved_linkages
}
