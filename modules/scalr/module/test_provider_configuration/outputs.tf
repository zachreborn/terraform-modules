###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of module test provider configuration link IDs (format 'tpcfgl-<RANDOM STRING>'), keyed by the same keys as var.module_test_provider_configurations."
  value       = { for key, value in scalr_module_test_provider_configuration.this : key => value.id }
}

output "links" {
  description = "Map of the resolved link (id, test_configuration_id, provider_configuration_id) for each entry, keyed by the same keys as var.module_test_provider_configurations. Useful for callers/tests that need to prove which test configuration / provider configuration pair was wired into each resource."
  value = {
    for key, value in scalr_module_test_provider_configuration.this : key => {
      id                        = value.id
      test_configuration_id     = value.test_configuration_id
      provider_configuration_id = value.provider_configuration_id
    }
  }
}
