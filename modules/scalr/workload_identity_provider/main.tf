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
resource "scalr_workload_identity_provider" "this" {
  for_each          = var.workload_identity_providers
  name              = each.value.name
  url               = each.value.url
  allowed_audiences = each.value.allowed_audiences
}
