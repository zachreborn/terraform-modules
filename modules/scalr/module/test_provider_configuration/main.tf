###########################
# Provider Configuration
###########################
terraform {
  # >= 1.3.0: the startswith() function (variables.tf validations) was introduced in Terraform 1.3.0.
  # The validations reference only their own variable, so no newer language feature is needed.
  required_version = ">= 1.3.0"
  required_providers {
    scalr = {
      source = "registry.scalr.io/scalr/scalr"
      # >= 3.20.0: scalr_module_test_provider_configuration was first released in provider v3.20.0.
      version = ">= 3.20.0"
    }
  }
}

###########################
# Module Test Provider Configuration Links
###########################
resource "scalr_module_test_provider_configuration" "this" {
  for_each = var.module_test_provider_configurations

  test_configuration_id     = each.value.test_configuration_id
  provider_configuration_id = each.value.provider_configuration_id
}
