###########################
# Resource Outputs
###########################
output "webhook_ids" {
  description = "Map of Datadog webhook IDs keyed by logical name."
  value       = { for k, v in datadog_webhook.this : k => v.id }
}

output "webhook_custom_variable_ids" {
  description = "Map of Datadog webhook custom variable IDs keyed by logical name."
  value       = { for k, v in datadog_webhook_custom_variable.this : k => v.id }
}
