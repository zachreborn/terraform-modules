###########################
# Resource Outputs
###########################
output "pagerduty_integration_ids" {
  description = "Map of PagerDuty integration IDs keyed by logical name."
  value       = { for k, v in datadog_integration_pagerduty.this : k => v.id }
}

output "service_object_ids" {
  description = "Map of PagerDuty service object IDs keyed by logical name."
  value       = { for k, v in datadog_integration_pagerduty_service_object.this : k => v.id }
}
