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
resource "datadog_webhook" "this" {
  for_each = var.webhooks

  name           = each.value.name
  url            = each.value.url
  custom_headers = each.value.custom_headers
  encode_as      = each.value.encode_as
  payload        = each.value.payload
}

resource "datadog_webhook_custom_variable" "this" {
  for_each = var.webhook_custom_variables

  name      = each.value.name
  value     = each.value.value
  is_secret = each.value.is_secret
}
