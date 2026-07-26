###########################
# Provider Configuration
###########################
terraform {
  # >= 1.9.0 is required because this module's events validation (variables.tf) references
  # local.environment_hook_valid_events (declared below) from within a variable validation block.
  # Terraform and OpenTofu both added support for referencing other variables/locals in variable
  # validation in their respective 1.9.0 releases, so this floor is satisfied by either tool.
  required_version = ">= 1.9.0"
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
