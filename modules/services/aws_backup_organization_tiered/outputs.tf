###########################
# Policy Outputs
###########################
output "backup_policy_id" {
  description = "The ID of the AWS Organizations BACKUP_POLICY."
  value       = aws_organizations_policy.tiered_backup.id
}

output "backup_policy_arn" {
  description = "The ARN of the AWS Organizations BACKUP_POLICY."
  value       = aws_organizations_policy.tiered_backup.arn
}

output "backup_policy_json" {
  description = "The rendered BACKUP_POLICY JSON document. Useful for review and for validating the generated policy before attachment."
  value       = jsonencode(local.backup_policy)
}

output "attached_ou_ids" {
  description = "The Organizational Unit IDs the BACKUP_POLICY is attached to."
  value       = [for a in aws_organizations_policy_attachment.tiered_backup : a.target_id]
}

###########################
# Central Vault Outputs
###########################
output "central_vault_names" {
  description = "Map of tier key to central vault name (identical across regions)."
  value       = local.central_vault_names
}

output "central_vault_arns_prod" {
  description = "Map of tier key to central vault ARN in the prod_region."
  value       = { for k, v in aws_backup_vault.central_prod : k => v.arn }
}

output "central_vault_arns_dr" {
  description = "Map of tier key to central vault ARN in the dr_region (copy_to_dr tiers only)."
  value       = { for k, v in aws_backup_vault.central_dr : k => v.arn }
}

output "central_kms_key_arns_prod" {
  description = "Map of tier key to central KMS key ARN in the prod_region."
  value       = { for k, v in module.central_kms_prod : k => v.arn }
}

output "central_kms_key_arns_dr" {
  description = "Map of tier key to central KMS key ARN in the dr_region (copy_to_dr tiers only)."
  value       = { for k, v in module.central_kms_dr : k => v.arn }
}

output "vault_lock_enabled" {
  description = "Whether COMPLIANCE-mode Vault Lock is applied to the central vaults."
  value       = var.enable_vault_lock
}

###########################
# Audit Manager Outputs
###########################
output "audit_framework_arn" {
  description = "ARN of the AWS Backup Audit Manager framework, if created."
  value       = try(aws_backup_framework.this[0].arn, null)
}

output "audit_report_plan_arn" {
  description = "ARN of the AWS Backup Audit Manager report plan, if created."
  value       = try(aws_backup_report_plan.this[0].arn, null)
}
