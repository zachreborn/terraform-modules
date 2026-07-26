###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

###########################
# Data Sources
###########################


###########################
# Locals
###########################

###########################
# Module Configuration
###########################
resource "scalr_webhook" "this" {
  for_each     = var.webhooks
  name         = each.value.name
  url          = each.value.url
  events       = each.value.events
  account_id   = try(coalesce(each.value.account_id, var.account_id), null)
  enabled      = each.value.enabled
  environments = each.value.environments
  max_attempts = each.value.max_attempts
  secret_key   = lookup(var.webhook_secret_keys, each.key, null)
  timeout      = each.value.timeout

  dynamic "header" {
    for_each = each.value.header
    content {
      name  = header.value.name
      value = header.value.value
    }
  }
}
