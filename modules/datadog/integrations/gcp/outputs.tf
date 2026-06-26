###########################
# Resource Outputs
###########################
output "gcp_account_ids" {
  description = "Map of GCP integration IDs keyed by logical name."
  value       = { for k, v in datadog_integration_gcp_sts.this : k => v.id }
}

output "delegate_account_emails" {
  description = "Map of Datadog STS delegate service account emails keyed by logical name. Use these to grant the token creator role in GCP."
  value       = { for k, v in datadog_integration_gcp_sts.this : k => v.delegate_account_email }
}
