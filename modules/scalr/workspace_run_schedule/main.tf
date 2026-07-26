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
resource "scalr_workspace_run_schedule" "this" {
  for_each         = var.workspace_run_schedules
  workspace_id     = each.value.workspace_id
  apply_schedule   = each.value.apply_schedule
  destroy_schedule = each.value.destroy_schedule
}
