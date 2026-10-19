###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.9.0" # variable validations reference other variables (needs 1.9+)
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.20.0" # scalr_wiz_integration first shipped in provider 3.20.0
    }
  }
}

###########################
# Scalr Wiz Integration
###########################
resource "scalr_wiz_integration" "this" {
  for_each = var.wiz_integrations

  name              = each.value.name
  client_id         = each.value.client_id
  default_policies  = each.value.default_policies
  default_scan_name = each.value.default_scan_name
  endpoint_mode     = each.value.endpoint_mode
  autofail          = each.value.autofail
  environments      = each.value.environments
  # The client secret comes from the separate sensitive var.wiz_client_secrets map. The
  # cross-variable validation on that variable guarantees a non-empty entry exists for every key
  # in var.wiz_integrations, so a direct index is safe here.
  client_secret = var.wiz_client_secrets[each.key]
}
