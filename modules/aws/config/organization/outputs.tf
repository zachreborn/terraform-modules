output "delegated_admin_id" {
  description = "The unique identifier of the delegated administrator registration (account_id:service_principal)."
  value       = aws_organizations_delegated_administrator.this.id
}

output "recorder_name" {
  description = "The name of the AWS Config configuration recorder."
  value       = aws_config_configuration_recorder.this.name
}

output "delivery_channel_name" {
  description = "The name of the AWS Config delivery channel."
  value       = aws_config_delivery_channel.this.name
}

output "s3_bucket_id" {
  description = "The ID (name) of the S3 bucket used for AWS Config delivery. Returns null when create_s3_bucket is false."
  value       = var.create_s3_bucket ? aws_s3_bucket.this[0].id : null
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for AWS Config delivery. Returns null when create_s3_bucket is false."
  value       = var.create_s3_bucket ? aws_s3_bucket.this[0].arn : null
}
