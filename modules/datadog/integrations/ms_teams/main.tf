###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Module Configuration
###########################
resource "datadog_integration_ms_teams_tenant_based_handle" "this" {
  for_each = var.tenant_based_handles

  name         = each.value.name
  tenant_name  = each.value.tenant_name
  team_name    = each.value.team_name
  channel_name = each.value.channel_name
}

resource "datadog_integration_ms_teams_workflows_webhook_handle" "this" {
  for_each = var.workflows_webhook_handles

  name = each.value.name
  url  = each.value.url
}
