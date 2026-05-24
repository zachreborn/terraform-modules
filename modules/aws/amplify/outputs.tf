###########################
# Resource Outputs
###########################

output "app_id" {
  description = "The unique ID of the Amplify app."
  value       = aws_amplify_app.this.id
}

output "app_arn" {
  description = "The ARN of the Amplify app."
  value       = aws_amplify_app.this.arn
}

output "default_domain" {
  description = "The default domain of the Amplify app."
  value       = aws_amplify_app.this.default_domain
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic used for Amplify build notifications. Null when notifications are disabled."
  value       = var.enable_notifications && var.create_sns_topic ? aws_sns_topic.this[0].arn : var.sns_topic_arn
}

output "notification_event_rule_arn" {
  description = "The ARN of the CloudWatch EventBridge rule for Amplify build notifications. Null when notifications are disabled."
  value       = var.enable_notifications ? aws_cloudwatch_event_rule.amplify_notifications[0].arn : null
}
