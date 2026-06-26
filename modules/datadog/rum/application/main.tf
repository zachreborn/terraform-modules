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

resource "datadog_rum_application" "this" {
  for_each = var.applications

  name                              = each.value.name
  type                              = each.value.type
  rum_event_processing_state        = each.value.rum_event_processing_state
  product_analytics_retention_state = each.value.product_analytics_retention_state
}
