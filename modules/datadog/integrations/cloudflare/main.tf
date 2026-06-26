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
resource "datadog_integration_cloudflare_account" "this" {
  for_each = var.cloudflare_accounts

  api_key   = each.value.api_key
  name      = each.value.name
  email     = each.value.email
  resources = each.value.resources
}
