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
# Environments
###########################
resource "scalr_environment" "this" {
  for_each = var.environments

  name                            = coalesce(each.value.name, each.key)
  account_id                      = each.value.account_id != null ? each.value.account_id : var.account_id
  default_provider_configurations = each.value.default_provider_configurations
  default_workspace_agent_pool_id = each.value.default_workspace_agent_pool_id
  federated_environments          = each.value.federated_environments
  mask_sensitive_output           = each.value.mask_sensitive_output
  remote_backend                  = each.value.remote_backend
  remote_backend_overridable      = each.value.remote_backend_overridable
  storage_profile_id              = each.value.storage_profile_id
  tag_ids                         = each.value.tag_ids
}
