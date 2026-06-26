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
resource "datadog_integration_opsgenie_service_object" "this" {
  for_each = var.service_objects

  name             = each.value.name
  opsgenie_api_key = each.value.opsgenie_api_key
  region           = each.value.region
  custom_url       = each.value.custom_url
}
