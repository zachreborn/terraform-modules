###########################
# Resource Outputs
###########################

output "ids" {
  description = "Map of monitor logical names to their Datadog monitor IDs."
  value       = { for k, v in datadog_monitor.this : k => v.id }
}

output "names" {
  description = "Map of monitor logical names to their Datadog monitor display names."
  value       = { for k, v in datadog_monitor.this : k => v.name }
}

output "monitors" {
  description = "Full map of all datadog_monitor resource objects, keyed by logical name."
  value       = datadog_monitor.this
}
