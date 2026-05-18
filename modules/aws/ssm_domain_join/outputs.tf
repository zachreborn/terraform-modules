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

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Logs log group, or null if CloudWatch logging is disabled."
  value       = var.cloudwatch_log_group_name != null ? aws_cloudwatch_log_group.domain_join[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Logs log group, or null if CloudWatch logging is disabled."
  value       = var.cloudwatch_log_group_name != null ? aws_cloudwatch_log_group.domain_join[0].arn : null
}
