###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.9.0" # variable validations reference other variables (needs 1.9+)
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.20.0" # scalr_datadog_integration first shipped in provider 3.20.0
    }
  }
}

###########################
# Scalr Datadog Integration
###########################
resource "scalr_datadog_integration" "this" {
  for_each = var.datadog_integrations

  name           = each.value.name
  deployment_url = each.value.deployment_url
  # The API key comes from the separate sensitive var.datadog_api_keys map. The cross-variable
  # validation on that variable guarantees a non-empty entry exists for every key in
  # var.datadog_integrations, so a direct index is safe here.
  api_key = var.datadog_api_keys[each.key]
}
