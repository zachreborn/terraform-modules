###########################
# Resource Outputs
###########################

output "arn" {
  description = "The ARN of the log group"
  value       = aws_cloudwatch_log_group.this.arn
}