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
# Data Sources
###########################


###########################
# Locals
###########################

###########################
# Module Configuration
###########################
resource "scalr_integration_infracost" "this" {
  for_each     = var.infracost_integrations
  name         = each.value.name
  environments = each.value.environments
  api_key      = lookup(var.infracost_api_keys, each.key, null)

  lifecycle {
    precondition {
      condition     = contains(keys(var.infracost_api_keys), each.key)
      error_message = "No api_key was found in var.infracost_api_keys for infracost_integrations entry \"${each.key}\". Add an entry to var.infracost_api_keys with the same key."
    }
  }
}
