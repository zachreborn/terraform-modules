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
# Provider Configuration Defaults
###########################
resource "scalr_provider_configuration_default" "this" {
  for_each = var.provider_configuration_defaults

  environment_id            = each.value.environment_id
  provider_configuration_id = each.value.provider_configuration_id
}
