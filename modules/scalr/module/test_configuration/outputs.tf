###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of module test configuration IDs (format 'tc-<RANDOM STRING>'), keyed by the same keys as var.module_test_configurations. Pass these to the sibling module/test_provider_configuration as test_configuration_id."
  value       = { for key, value in scalr_module_test_configuration.this : key => value.id }
}

output "test_configurations" {
  description = "Map of the resolved settings (id, module_id, enabled, failure_behavior, trigger_on_new_version_enabled, trigger_on_pr_activity_enabled) of each test configuration, keyed by the same keys as var.module_test_configurations. None of these values are sensitive."
  value = {
    for key, value in scalr_module_test_configuration.this : key => {
      id                             = value.id
      module_id                      = value.module_id
      enabled                        = value.enabled
      failure_behavior               = value.failure_behavior
      trigger_on_new_version_enabled = value.trigger_on_new_version_enabled
      trigger_on_pr_activity_enabled = value.trigger_on_pr_activity_enabled
    }
  }
}
