###########################
# Resource Outputs
###########################

output "ids" {
  description = "Map of notification rule logical names to their Datadog notification rule IDs."
  value       = { for k, v in datadog_monitor_notification_rule.this : k => v.id }
}

output "notification_rules" {
  description = "Full map of all datadog_monitor_notification_rule resource objects, keyed by logical name."
  value       = datadog_monitor_notification_rule.this
}
