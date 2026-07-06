###########################
# Resource Outputs
###########################
output "azure_integration_ids" {
  description = "Map of Azure integration IDs keyed by logical name."
  value       = { for k, v in datadog_integration_azure.this : k => v.id }
}
