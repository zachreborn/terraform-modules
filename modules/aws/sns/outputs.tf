###########################
# Resource Outputs
###########################

output "topic_arn" {
  description = "The ARN of the SNS topic."
  value       = aws_sns_topic.this.arn
}

output "topic_id" {
  description = "The ID of the SNS topic (same as the ARN)."
  value       = aws_sns_topic.this.id
}

output "topic_name" {
  description = "The name of the SNS topic."
  value       = aws_sns_topic.this.name
}

output "topic_owner" {
  description = "The AWS account ID of the SNS topic owner."
  value       = aws_sns_topic.this.owner
}

output "subscription_arns" {
  description = "Map of subscription logical names to their ARNs."
  value       = { for k, v in aws_sns_topic_subscription.this : k => v.arn }
}
