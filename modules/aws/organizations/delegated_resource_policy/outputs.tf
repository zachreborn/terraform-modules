###########################################################
# AWS Organization Delegated Resource Policy Outputs
###########################################################

output "arn" {
  description = "The ARN of the AWS Organization's delegated resource policy."
  value       = aws_organizations_resource_policy.this.arn
}

output "id" {
  description = "The ID of the AWS Organization's delegated resource policy."
  value       = aws_organizations_resource_policy.this.id
}
