###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    scalr = {
      source = "registry.scalr.io/scalr/scalr"
      # >= 3.20.0: scalr_module_test_configuration was first released in provider v3.20.0.
      version = ">= 3.20.0"
    }
  }
}

###########################
# Module Test Configurations
###########################
resource "scalr_module_test_configuration" "this" {
  for_each = var.module_test_configurations

  module_id                      = each.value.module_id
  enabled                        = each.value.enabled
  failure_behavior               = each.value.failure_behavior
  trigger_on_new_version_enabled = each.value.trigger_on_new_version_enabled
  trigger_on_pr_activity_enabled = each.value.trigger_on_pr_activity_enabled
}
