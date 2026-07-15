###########################
# Resource Outputs
###########################

output "arn" {
  description = "The ARN of the CloudWatch metric alarm."
  value       = aws_cloudwatch_metric_alarm.alarm.arn
}

output "id" {
  description = "The ID (name) of the CloudWatch metric alarm."
  value       = aws_cloudwatch_metric_alarm.alarm.id
}
