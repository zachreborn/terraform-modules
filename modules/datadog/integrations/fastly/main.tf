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
resource "datadog_integration_fastly_account" "this" {
  for_each = var.fastly_accounts

  name               = each.value.name
  api_key            = each.value.api_key
  api_key_wo         = each.value.api_key_wo
  api_key_wo_version = each.value.api_key_wo_version
}

resource "datadog_integration_fastly_service" "this" {
  for_each = var.fastly_services

  service_id = each.value.service_id
  account_id = each.value.account_id
  tags       = each.value.tags
}
