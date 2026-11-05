###########################
# Resource Variables
###########################
variable "module_test_provider_configurations" {
  description = <<-EOT
    Map of links (`scalr_module_test_provider_configuration`) that attach a provider configuration
    (credentials) to a module test configuration, keyed by a caller-chosen logical name. The attached
    provider configuration is used while the module's tests run.

    Constraints that Terraform cannot check at plan time (Scalr enforces them on apply):
      - The provider configuration must have is_allowed_in_module_test = true (see the sibling
        modules/scalr/provider_configuration module).
      - Only one provider configuration per provider type (for example one "aws") can be linked to a
        given test configuration.

    Fields:
      - test_configuration_id:     (Required) ID of the module test configuration, in the format
                                   "tc-<RANDOM STRING>". Typically the output of modules/scalr/module/test_configuration.
      - provider_configuration_id: (Required) ID of the provider configuration to use as credentials for the
                                   module tests, in the format "pcfg-<RANDOM STRING>".

    Example:
      module_test_provider_configurations = {
        vpc_aws = {
          test_configuration_id     = "tc-xxxxxxxxxx"
          provider_configuration_id = "pcfg-xxxxxxxxxx"
        }
      }
  EOT
  type = map(object({
    test_configuration_id     = string
    provider_configuration_id = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.module_test_provider_configurations : value.test_configuration_id == null ? false : startswith(value.test_configuration_id, "tc-")
    ])
    error_message = "Each module_test_provider_configurations entry's test_configuration_id must be a module test configuration ID starting with 'tc-', e.g. 'tc-xxxxxxxxxx'."
  }

  validation {
    condition = alltrue([
      for key, value in var.module_test_provider_configurations : value.provider_configuration_id == null ? false : startswith(value.provider_configuration_id, "pcfg-")
    ])
    error_message = "Each module_test_provider_configurations entry's provider_configuration_id must be a provider configuration ID starting with 'pcfg-', e.g. 'pcfg-xxxxxxxxxx'."
  }
}
