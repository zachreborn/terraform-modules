###########################
# Resource Outputs
###########################
output "confluent_account_ids" {
  description = "Map of Confluent account integration IDs keyed by logical name."
  value       = { for k, v in datadog_integration_confluent_account.this : k => v.id }
}

output "confluent_resource_ids" {
  description = "Map of Confluent resource integration IDs keyed by logical name."
  value       = { for k, v in datadog_integration_confluent_resource.this : k => v.id }
}
