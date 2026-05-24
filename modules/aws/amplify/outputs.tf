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
  value       = var.enable_notifications ? (var.create_sns_topic ? module.amplify_notifications_sns[0].topic_arn : var.sns_topic_arn) : null
}

output "notification_event_rule_arn" {
  description = "The ARN of the CloudWatch EventBridge rule for Amplify build notifications. Null when notifications are disabled."
  value       = var.enable_notifications ? module.amplify_notifications_event[0].arn : null
}
