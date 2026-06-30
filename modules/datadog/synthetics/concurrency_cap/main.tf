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
resource "datadog_synthetics_concurrency_cap" "this" {
  on_demand_concurrency_cap = var.on_demand_concurrency_cap
}
