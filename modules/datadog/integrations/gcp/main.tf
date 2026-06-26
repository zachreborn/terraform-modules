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
resource "datadog_integration_gcp_sts" "this" {
  for_each = var.gcp_accounts

  client_email                          = each.value.client_email
  account_tags                          = each.value.account_tags
  automute                              = each.value.automute
  is_cspm_enabled                       = each.value.is_cspm_enabled
  is_global_location_enabled            = each.value.is_global_location_enabled
  is_per_project_quota_enabled          = each.value.is_per_project_quota_enabled
  is_resource_change_collection_enabled = each.value.is_resource_change_collection_enabled
  is_security_command_center_enabled    = each.value.is_security_command_center_enabled
  resource_collection_enabled           = each.value.resource_collection_enabled
  region_filter_configs                 = each.value.region_filter_configs

  dynamic "metric_namespace_configs" {
    for_each = each.value.metric_namespace_configs != null ? each.value.metric_namespace_configs : []
    content {
      id       = metric_namespace_configs.value.id
      disabled = metric_namespace_configs.value.disabled
      filters  = metric_namespace_configs.value.filters
    }
  }

  dynamic "monitored_resource_configs" {
    for_each = each.value.monitored_resource_configs != null ? each.value.monitored_resource_configs : []
    content {
      type    = monitored_resource_configs.value.type
      filters = monitored_resource_configs.value.filters
    }
  }
}
