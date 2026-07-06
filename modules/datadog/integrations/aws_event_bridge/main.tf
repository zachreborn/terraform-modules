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
resource "datadog_integration_aws_event_bridge" "this" {
  for_each = var.event_bridges

  account_id           = each.value.account_id
  event_generator_name = each.value.event_generator_name
  region               = each.value.region
  create_event_bus     = each.value.create_event_bus
}
