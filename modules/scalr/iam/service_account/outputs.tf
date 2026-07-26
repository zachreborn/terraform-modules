###########################
# Service Account Outputs
###########################
output "ids" {
  description = "Map of Scalr Service Account IDs, keyed by the same keys as var.service_accounts."
  value       = { for k, v in scalr_service_account.this : k => v.id }
}

output "emails" {
  description = "Map of Scalr Service Account emails, keyed by the same keys as var.service_accounts."
  value       = { for k, v in scalr_service_account.this : k => v.email }
}

output "created_by" {
  description = "Map of the details (email, full_name, username) of the user that created each service account, keyed by the same keys as var.service_accounts."
  value       = { for k, v in scalr_service_account.this : k => v.created_by }
}

###########################
# Service Account Token Outputs
###########################
output "token_ids" {
  description = "Map of Scalr Service Account Token IDs, keyed by the same keys as var.tokens."
  value       = module.tokens.ids
}

output "tokens" {
  description = "Map of the issued Service Account token values, keyed by the same keys as var.tokens. Sensitive."
  value       = module.tokens.tokens
  sensitive   = true
}

###########################
# Assume Service Account Policy Outputs
###########################
output "assume_policy_ids" {
  description = "Map of Scalr Assume Service Account Policy IDs, keyed by the same keys as var.assume_policies."
  value       = module.assume_policies.ids
}
