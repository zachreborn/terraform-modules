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
resource "scalr_event_bridge_integration" "this" {
  for_each       = var.event_bridge_integrations
  name           = each.value.name
  aws_account_id = each.value.aws_account_id
  region         = each.value.region
}
