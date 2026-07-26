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
locals {
  environment_hook_valid_events = ["pre-init", "pre-plan", "post-plan", "pre-apply", "post-apply"]
}

###########################
# Module Configuration
###########################
resource "scalr_environment_hook" "this" {
  for_each       = var.environment_hooks
  hook_id        = each.value.hook_id
  environment_id = each.value.environment_id
  events         = each.value.events
}
