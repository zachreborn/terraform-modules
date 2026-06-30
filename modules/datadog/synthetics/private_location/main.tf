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
# Locals
###########################

###########################
# Module Configuration
###########################
resource "datadog_synthetics_private_location" "this" {
  for_each = var.private_locations

  name        = each.value.name
  description = each.value.description
  tags        = each.value.tags
  api_key     = each.value.api_key

  dynamic "metadata" {
    for_each = each.value.metadata != null ? [each.value.metadata] : []
    content {
      restricted_roles = metadata.value.restricted_roles
    }
  }
}
