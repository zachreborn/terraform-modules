###########################
# Resource Outputs
###########################
output "fastly_account_ids" {
  description = "Map of Fastly account integration IDs keyed by logical name."
  value       = { for k, v in datadog_integration_fastly_account.this : k => v.id }
}

output "fastly_service_ids" {
  description = "Map of Fastly service integration IDs keyed by logical name."
  value       = { for k, v in datadog_integration_fastly_service.this : k => v.id }
}
