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
resource "datadog_integration_confluent_account" "this" {
  for_each = var.confluent_accounts

  api_key    = each.value.api_key
  api_secret = each.value.api_secret
  tags       = each.value.tags
}

resource "datadog_integration_confluent_resource" "this" {
  for_each = var.confluent_resources

  account_id            = each.value.account_id
  resource_id           = each.value.resource_id
  resource_type         = each.value.resource_type
  enable_custom_metrics = each.value.enable_custom_metrics
  tags                  = each.value.tags
}
