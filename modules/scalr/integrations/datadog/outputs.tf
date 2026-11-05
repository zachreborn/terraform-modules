###########################
# Resource Outputs
###########################
# Explicit non-sensitive projections only. The whole scalr_datadog_integration object is
# deliberately NOT output because it carries the sensitive api_key attribute.
output "ids" {
  description = "Map of Scalr Datadog integration IDs (in-<RANDOM STRING>) keyed by the same logical name used in var.datadog_integrations."
  value       = { for key, value in scalr_datadog_integration.this : key => value.id }
}

output "statuses" {
  description = "Map of Scalr Datadog integration statuses (\"active\", \"disabled\", or \"failed\") keyed by the same logical name used in var.datadog_integrations. Scalr sets \"failed\" when the integration cannot connect to Datadog."
  value       = { for key, value in scalr_datadog_integration.this : key => value.status }
}

output "err_messages" {
  description = "Map of error messages reported by Scalr keyed by the same logical name used in var.datadog_integrations. Only meaningful when the matching status is \"failed\"."
  value       = { for key, value in scalr_datadog_integration.this : key => value.err_message }
}

output "account_ids" {
  description = "Map of the Scalr account IDs (acc-<RANDOM STRING>) each Datadog integration belongs to, keyed by the same logical name used in var.datadog_integrations."
  value       = { for key, value in scalr_datadog_integration.this : key => value.account_id }
}
