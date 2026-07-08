###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Synthetics test IDs keyed by logical name."
  value       = { for k, v in datadog_synthetics_test.this : k => v.id }
}

output "monitor_ids" {
  description = "Map of Datadog monitor IDs associated with each Synthetics test, keyed by logical name."
  value       = { for k, v in datadog_synthetics_test.this : k => v.monitor_id }
}
