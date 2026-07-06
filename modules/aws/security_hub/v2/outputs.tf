###########################################################
# Security Hub V2 Account Outputs
###########################################################

output "account_arn" {
  description = "ARN of the unified Security Hub (V2) resource created in the security account."
  value       = aws_securityhub_account_v2.this.arn
}

###########################################################
# Security Hub V2 Finding Aggregator Outputs
###########################################################

output "aggregator_arn" {
  description = "ARN of the Security Hub V2 aggregator, or null when enable_finding_aggregation is false."
  value       = try(aws_securityhub_aggregator_v2.this[0].arn, null)
}

output "aggregation_region" {
  description = "The AWS Region where Security Hub V2 findings are aggregated, or null when enable_finding_aggregation is false."
  value       = try(aws_securityhub_aggregator_v2.this[0].aggregation_region, null)
}

###########################################################
# Security Hub V2 Automation Rule Outputs
###########################################################

output "automation_rule_arns" {
  description = "Map of automation rule name to rule ARN for rules created by this module. Empty when no automation_rules are supplied."
  value       = { for name, rule in aws_securityhub_automation_rule_v2.this : name => rule.rule_arn }
}
