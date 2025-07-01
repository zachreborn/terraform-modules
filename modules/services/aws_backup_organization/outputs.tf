###############################################################
# Organization Policy Outputs
###############################################################

output "backup_policy_id" {
  description = "The ID of the organization backup policy"
  value       = aws_organizations_policy.backup_policy.id
}

output "backup_policy_arn" {
  description = "The ARN of the organization backup policy"
  value       = aws_organizations_policy.backup_policy.arn
}

output "organization_id" {
  description = "The ID of the AWS Organization"
  value       = data.aws_organizations_organization.current.id
}

output "organization_root_id" {
  description = "The root ID of the AWS Organization"
  value       = data.aws_organizations_organization.current.roots[0].id
}

###############################################################
# Account Information Outputs
###############################################################

output "active_accounts" {
  description = "List of active accounts in the organization"
  value = [
    for account in local.active_accounts : {
      id     = account.id
      name   = account.name
      email  = account.email
      status = account.status
    }
  ]
}

output "total_active_accounts" {
  description = "Total number of active accounts in the organization"
  value       = length(local.active_accounts)
}

###############################################################
# Deployment Information Outputs
###############################################################

output "vault_deployment_function_name" {
  description = "Name of the Lambda function used for vault deployment"
  value       = aws_lambda_function.vault_deployment.function_name
}

output "vault_deployment_function_arn" {
  description = "ARN of the Lambda function used for vault deployment"
  value       = aws_lambda_function.vault_deployment.arn
}

output "deployment_results" {
  description = "Results from the vault deployment Lambda function"
  value       = aws_lambda_invocation.deploy_vaults.result
  sensitive   = true
}

###############################################################
# Cross-Account Role Outputs
###############################################################

output "cross_account_deployment_role_arn" {
  description = "ARN of the cross-account deployment role"
  value       = aws_iam_role.cross_account_backup_deployment.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.vault_deployment_lambda.arn
}

###############################################################
# Monitoring Outputs
###############################################################

output "backup_notifications_topic_arn" {
  description = "ARN of the SNS topic for backup notifications"
  value       = aws_sns_topic.backup_notifications.arn
}

output "backup_failure_alarm_arn" {
  description = "ARN of the CloudWatch alarm for backup failures"
  value       = aws_cloudwatch_metric_alarm.backup_failures.arn
}

###############################################################
# Configuration Outputs
###############################################################

output "backup_configuration" {
  description = "Summary of backup configuration"
  value = {
    prod_region     = var.aws_prod_region
    dr_region       = var.aws_dr_region
    backup_plan     = var.backup_plan_name
    schedules = {
      hourly  = var.hourly_backup_schedule
      daily   = var.daily_backup_schedule
      monthly = var.monthly_backup_schedule
    }
    retention = {
      hourly  = var.hourly_backup_retention
      daily   = var.daily_backup_retention
      monthly = var.monthly_backup_retention
      dr      = var.dr_backup_retention
    }
    vault_names = {
      hourly  = var.vault_prod_hourly_name
      daily   = var.vault_prod_daily_name
      monthly = var.vault_prod_monthly_name
      dr      = var.vault_disaster_recovery_name
    }
  }
}

###############################################################
# Vault ARNs (Template - Actual ARNs depend on deployment)
###############################################################

output "vault_arn_template" {
  description = "Template for vault ARNs across accounts"
  value = {
    prod_hourly_template  = "arn:aws:backup:${var.aws_prod_region}:ACCOUNT_ID:backup-vault:${var.vault_prod_hourly_name}"
    prod_daily_template   = "arn:aws:backup:${var.aws_prod_region}:ACCOUNT_ID:backup-vault:${var.vault_prod_daily_name}"
    prod_monthly_template = "arn:aws:backup:${var.aws_prod_region}:ACCOUNT_ID:backup-vault:${var.vault_prod_monthly_name}"
    dr_template          = "arn:aws:backup:${var.aws_dr_region}:ACCOUNT_ID:backup-vault:${var.vault_disaster_recovery_name}"
  }
}