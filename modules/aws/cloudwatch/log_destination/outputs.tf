###########################
# Log Destination Outputs
###########################

output "arn" {
  description = "The ARN of the CloudWatch log destination. Used by other accounts as the destination_arn of a subscription filter."
  value       = aws_cloudwatch_log_destination.this.arn
}

output "name" {
  description = "The name of the CloudWatch log destination."
  value       = aws_cloudwatch_log_destination.this.name
}

output "id" {
  description = "The ID (name) of the CloudWatch log destination."
  value       = aws_cloudwatch_log_destination.this.id
}

output "access_policy" {
  description = "The effective cross-account access policy attached to the log destination, or null when no destination policy is created."
  value       = length(aws_cloudwatch_log_destination_policy.this) > 0 ? aws_cloudwatch_log_destination_policy.this[0].access_policy : null
}
