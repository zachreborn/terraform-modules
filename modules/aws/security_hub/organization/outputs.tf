############################################################
# AWS Security Hub CSPM Account Outputs
############################################################

output "account_id" {
  description = "The AWS account ID where Security Hub CSPM is enabled (the delegated security account)."
  value       = aws_securityhub_account.this.id
}

output "account_arn" {
  description = "ARN of the Security Hub CSPM account resource in the delegated security account."
  value       = aws_securityhub_account.this.arn
}

############################################################
# AWS Security Hub CSPM Delegated Administrator Outputs
############################################################

output "admin_account_id" {
  description = "The 12-digit AWS account ID designated as the Security Hub CSPM delegated administrator."
  value       = aws_securityhub_organization_admin_account.this.admin_account_id
}

############################################################
# AWS Security Hub CSPM Finding Aggregator Outputs
############################################################

output "finding_aggregator_arn" {
  description = "ARN of the Security Hub CSPM finding aggregator."
  value       = aws_securityhub_finding_aggregator.this.arn
}

############################################################
# AWS Security Hub CSPM Configuration Policy Outputs
############################################################

output "configuration_policy_ids" {
  description = "Map of configuration policy name to policy ID for policies created when configuration_type is CENTRAL. Empty for LOCAL configuration."
  value       = { for name, policy in aws_securityhub_configuration_policy.this : name => policy.id }
}
