###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Service Account Token IDs, keyed by the same keys as var.tokens."
  value       = { for k, v in scalr_service_account_token.this : k => v.id }
}

output "tokens" {
  description = "Map of the issued Service Account token values, keyed by the same keys as var.tokens. Sensitive."
  value       = { for k, v in scalr_service_account_token.this : k => v.token }
  sensitive   = true
}
