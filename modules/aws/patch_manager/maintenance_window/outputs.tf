###########################
# Maintenance Window Outputs
###########################

output "maintenance_window_id" {
  description = "The ID of the maintenance window."
  value       = aws_ssm_maintenance_window.this.id
}

output "maintenance_window_name" {
  description = "The name of the maintenance window."
  value       = aws_ssm_maintenance_window.this.name
}

###########################
# IAM Role Outputs
###########################

output "service_role_arn" {
  description = "The ARN of the maintenance window service IAM role."
  value       = aws_iam_role.maintenance_window.arn
}

output "service_role_name" {
  description = "The name of the maintenance window service IAM role."
  value       = aws_iam_role.maintenance_window.name
}

###########################
# Target and Task Outputs
###########################

output "target_ids" {
  description = "Map of maintenance window target IDs, keyed by target name."
  value       = { for k, v in aws_ssm_maintenance_window_target.this : k => v.id }
}

output "task_ids" {
  description = "Map of maintenance window task IDs, keyed by target name."
  value       = { for k, v in aws_ssm_maintenance_window_task.this : k => v.id }
}

###########################
# S3 Outputs
###########################

output "s3_bucket_id" {
  description = "The name of the S3 bucket created for patch logs. Null when create_s3_bucket = false."
  value       = var.create_s3_bucket ? aws_s3_bucket.this[0].id : null
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket created for patch logs. Null when create_s3_bucket = false."
  value       = var.create_s3_bucket ? aws_s3_bucket.this[0].arn : null
}

###########################
# SNS Outputs
###########################

output "sns_topic_arn" {
  description = "The ARN of the SNS topic created for patch notifications. Null when create_sns_topic = false."
  value       = var.create_sns_topic ? aws_sns_topic.this[0].arn : null
}

output "sns_topic_name" {
  description = "The name of the SNS topic created for patch notifications. Null when create_sns_topic = false."
  value       = var.create_sns_topic ? aws_sns_topic.this[0].name : null
}
