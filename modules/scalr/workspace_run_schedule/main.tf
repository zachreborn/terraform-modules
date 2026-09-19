###########################
# Provider Configuration
###########################
terraform {
  # >= 1.9.0 is required because this module's apply_schedule/destroy_schedule validations
  # (variables.tf) reference local.workspace_run_schedule_cron_pattern from within a variable
  # validation block. Terraform and OpenTofu both added support for referencing other variables/
  # locals in variable validation in their respective 1.9.0 releases, so this floor is satisfied by
  # either tool.
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
resource "scalr_workspace_run_schedule" "this" {
  for_each         = var.workspace_run_schedules
  workspace_id     = each.value.workspace_id
  apply_schedule   = each.value.apply_schedule
  destroy_schedule = each.value.destroy_schedule
}
