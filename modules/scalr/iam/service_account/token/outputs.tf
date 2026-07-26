###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Service Account Token IDs, keyed by the same keys as var.tokens."
  value       = { for k, v in scalr_service_account_token.this : k => v.id }
}

output "service_account_ids" {
  description = "Map of the service_account_id actually passed to each scalr_service_account_token resource, keyed by the same keys as var.tokens. Useful for callers/tests that need to prove which service account was actually wired into each token."
  value       = { for k, v in scalr_service_account_token.this : k => v.service_account_id }
}

output "tokens" {
  description = "Map of the issued Service Account token values, keyed by the same keys as var.tokens. Sensitive."
  value       = { for k, v in scalr_service_account_token.this : k => v.token }
  sensitive   = true
}
