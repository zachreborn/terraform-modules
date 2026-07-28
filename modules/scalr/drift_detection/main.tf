###########################
# Provider Configuration
###########################
terraform {
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

###########################
# Module Configuration
###########################
resource "scalr_drift_detection" "this" {
  for_each       = var.drift_detections
  environment_id = each.value.environment_id
  check_period   = each.value.check_period
  run_mode       = each.value.run_mode

  dynamic "workspace_filters" {
    for_each = each.value.workspace_filters != null ? [each.value.workspace_filters] : []
    content {
      name_patterns     = workspace_filters.value.name_patterns
      environment_types = workspace_filters.value.environment_types
      tags              = workspace_filters.value.tags
    }
  }
}
