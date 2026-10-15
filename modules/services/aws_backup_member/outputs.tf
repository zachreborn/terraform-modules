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

output "backup_role_arn" {
  description = "ARN of the IAM role AWS Backup assumes in this account."
  value       = module.backup_role.arn
}

output "backup_role_name" {
  description = "Name of the IAM role AWS Backup assumes in this account."
  value       = module.backup_role.name
}
