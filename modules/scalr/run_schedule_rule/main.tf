###########################
# Provider Configuration
###########################
terraform {
  # >= 1.9.0 is required because this module's schedule validation (variables.tf) references
  # local.run_schedule_rule_cron_pattern from within a variable validation block. Terraform and
  # OpenTofu both added support for referencing other variables/locals in variable validation in
  # their respective 1.9.0 releases, so this floor is satisfied by either tool.
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
resource "scalr_run_schedule_rule" "this" {
  for_each      = var.run_schedule_rules
  schedule      = each.value.schedule
  schedule_mode = each.value.schedule_mode
  workspace_id  = each.value.workspace_id
}
