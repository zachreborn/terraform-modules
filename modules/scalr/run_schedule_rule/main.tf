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
resource "scalr_run_schedule_rule" "this" {
  for_each      = var.run_schedule_rules
  schedule      = each.value.schedule
  schedule_mode = each.value.schedule_mode
  workspace_id  = each.value.workspace_id
}
