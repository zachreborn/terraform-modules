###########################################################
# AWS Organization Policy Outputs
###########################################################

output "arn" {
  description = "The ARN of the AWS Organization's delegated resource policy."
  value       = aws_organizations_policy.this.arn
}

output "id" {
  description = "The ID of the AWS Organization's delegated resource policy."
  value       = aws_organizations_policy.this.id
}
