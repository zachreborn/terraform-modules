###########################
# Resource Outputs
###########################

output "ids" {
  description = "Map of config policy logical names to their Datadog config policy IDs."
  value       = { for k, v in datadog_monitor_config_policy.this : k => v.id }
}

output "config_policies" {
  description = "Full map of all datadog_monitor_config_policy resource objects, keyed by logical name."
  value       = datadog_monitor_config_policy.this
}
