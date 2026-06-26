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

resource "datadog_rum_retention_filter" "this" {
  for_each = var.retention_filters

  application_id = each.value.application_id
  name           = each.value.name
  event_type     = each.value.event_type
  sample_rate    = each.value.sample_rate
  enabled        = each.value.enabled
  query          = each.value.query
}

resource "datadog_rum_retention_filters_order" "this" {
  count = var.enable_filter_order ? 1 : 0

  application_id       = var.filter_order_application_id
  retention_filter_ids = var.filter_order_ids

  lifecycle {
    precondition {
      condition     = var.filter_order_application_id != null && length(var.filter_order_ids) > 0
      error_message = "filter_order_application_id and filter_order_ids must be provided (non-null and non-empty) when enable_filter_order is true."
    }
  }
}
