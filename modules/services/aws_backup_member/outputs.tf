###########################
# Resource Outputs
###########################
output "staging_vault_arn" {
  description = "ARN of the local staging backup vault."
  value       = aws_backup_vault.staging.arn
}

output "staging_vault_name" {
  description = "Name of the local staging backup vault."
  value       = aws_backup_vault.staging.name
}

output "staging_vault_policy" {
  description = "Resource-based access policy on the staging vault."
  value       = aws_backup_vault_policy.staging.policy
}

output "vault_lock_mode" {
  description = "The AWS Backup Vault Lock mode applied to the staging vault (none, governance, or compliance)."
  value       = var.vault_lock_mode
}

output "backup_role_arn" {
  description = "ARN of the IAM role AWS Backup assumes in this account."
  value       = module.backup_role.arn
}

output "backup_role_name" {
  description = "Name of the IAM role AWS Backup assumes in this account."
  value       = module.backup_role.name
}
