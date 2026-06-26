###########################
# Resource Outputs
###########################
output "tenant_based_handle_ids" {
  description = "Map of Microsoft Teams tenant-based handle IDs keyed by logical name."
  value       = { for k, v in datadog_integration_ms_teams_tenant_based_handle.this : k => v.id }
}

output "workflows_webhook_handle_ids" {
  description = "Map of Microsoft Teams Workflows webhook handle IDs keyed by logical name."
  value       = { for k, v in datadog_integration_ms_teams_workflows_webhook_handle.this : k => v.id }
}
