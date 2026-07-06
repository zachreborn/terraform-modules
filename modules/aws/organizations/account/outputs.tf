############################################################
# AWS Organization Account
############################################################

output "ids" {
  description = "Map of AWS Organization account IDs, keyed by the same keys as var.accounts."
  value       = { for k, v in aws_organizations_account.this : k => v.id }
}

output "arns" {
  description = "Map of AWS Organization account ARNs, keyed by the same keys as var.accounts."
  value       = { for k, v in aws_organizations_account.this : k => v.arn }
}

output "tags_all" {
  description = "Map of the resolved tags for each account, keyed by the same keys as var.accounts."
  value       = { for k, v in aws_organizations_account.this : k => v.tags_all }
}
