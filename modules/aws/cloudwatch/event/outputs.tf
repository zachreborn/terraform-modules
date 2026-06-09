###########################
# Resource Outputs
###########################

output "arn" {
  description = "The ARN of the CloudWatch event rule."
  value       = aws_cloudwatch_event_rule.event_rule.arn
}

output "rule_name" {
  description = "The name of the CloudWatch event rule."
  value       = aws_cloudwatch_event_rule.event_rule.name
}

output "target_arn" {
  description = "The ARN of the CloudWatch event target."
  value       = aws_cloudwatch_event_target.event_target.arn
}
