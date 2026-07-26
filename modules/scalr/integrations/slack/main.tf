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
resource "scalr_slack_integration" "this" {
  for_each     = var.slack_integrations
  name         = each.value.name
  channel_id   = each.value.channel_id
  events       = each.value.events
  environments = each.value.environments
  workspaces   = each.value.workspaces
  run_mode     = each.value.run_mode
  account_id   = try(coalesce(each.value.account_id, var.account_id), null)
}
