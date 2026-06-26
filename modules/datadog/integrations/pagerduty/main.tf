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
resource "datadog_integration_pagerduty" "this" {
  for_each = var.pagerduty_integrations

  subdomain = each.value.subdomain
  api_token = each.value.api_token
  schedules = each.value.schedules
}

resource "datadog_integration_pagerduty_service_object" "this" {
  for_each = var.service_objects

  service_name = each.value.service_name
  service_key  = each.value.service_key
}
