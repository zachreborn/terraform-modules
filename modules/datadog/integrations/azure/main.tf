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
resource "datadog_integration_azure" "this" {
  for_each = var.azure_integrations

  tenant_name                 = each.value.tenant_name
  client_id                   = each.value.client_id
  client_secret               = each.value.client_secret
  secretless_auth_enabled     = each.value.secretless_auth_enabled
  automute                    = each.value.automute
  cspm_enabled                = each.value.cspm_enabled
  custom_metrics_enabled      = each.value.custom_metrics_enabled
  metrics_enabled             = each.value.metrics_enabled
  metrics_enabled_default     = each.value.metrics_enabled_default
  usage_metrics_enabled       = each.value.usage_metrics_enabled
  resource_collection_enabled = each.value.resource_collection_enabled
  host_filters                = each.value.host_filters
  app_service_plan_filters    = each.value.app_service_plan_filters
  container_app_filters       = each.value.container_app_filters

  dynamic "resource_provider_configs" {
    for_each = each.value.resource_provider_configs != null ? each.value.resource_provider_configs : []
    content {
      namespace       = resource_provider_configs.value.namespace
      metrics_enabled = resource_provider_configs.value.metrics_enabled
    }
  }
}
