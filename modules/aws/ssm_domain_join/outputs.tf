########################################
# SSM Domain Join Outputs
########################################
output "ssm_document_arn" {
  description = "ARN of the SSM domain join document."
  value       = aws_ssm_document.this.arn
}

output "ssm_document_name" {
  description = "Name of the SSM domain join document."
  value       = aws_ssm_document.this.name
}

output "ssm_association_id" {
  description = "ID of the SSM State Manager association."
  value       = aws_ssm_association.this.association_id
}

output "ssm_association_arn" {
  description = "ARN of the SSM State Manager association."
  value       = aws_ssm_association.this.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Logs log group, or null if CloudWatch logging is disabled."
  value       = var.cloudwatch_log_group_name != null ? module.domain_join_log_group[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Logs log group, or null if CloudWatch logging is disabled."
  value       = var.cloudwatch_log_group_name != null ? module.domain_join_log_group[0].arn : null
}

output "iam_secret_read_policy_name" {
  description = "Name of the inline IAM policy granting Secrets Manager / KMS / EC2 tag read access."
  value       = aws_iam_role_policy.secret_read.name
}

output "iam_cloudwatch_logs_policy_name" {
  description = "Name of the inline IAM policy granting CloudWatch Logs write access, or null when CloudWatch logging is disabled."
  value       = var.cloudwatch_log_group_name != null ? aws_iam_role_policy.cloudwatch_logs[0].name : null
}
