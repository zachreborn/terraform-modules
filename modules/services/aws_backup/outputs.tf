output "vault_hourly_arn" {
  value = aws_backup_vault.vault_prod_hourly.arn
}

output "vault_daily_arn" {
  value = aws_backup_vault.vault_prod_daily.arn
}

output "vault_monthly_arn" {
  value = aws_backup_vault.vault_prod_monthly.arn
}

output "vault_disaster_recovery_arn" {
  value = aws_backup_vault.vault_disaster_recovery.arn
}

output "organization_backup_plan_policy_id" {
  description = "The id of the AWS Organizations resource policy created for the organization backup plan, or null when enable_organization_backup is false."
  value       = try(module.organization_backup_plan["this"].id, null)
}
