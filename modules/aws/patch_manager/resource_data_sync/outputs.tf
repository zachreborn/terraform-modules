###########################
# Resource Data Sync Outputs
###########################

output "name" {
  description = "The name of the resource data sync configuration."
  value       = aws_ssm_resource_data_sync.this.name
}

###########################
# S3 Bucket Outputs
###########################

output "bucket_name" {
  description = "The name of the S3 bucket used as the sync destination. Returns the created bucket name or the provided bucket_name."
  value       = local.bucket_name
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket created for SSM sync data. Null when create_bucket = false."
  value       = var.create_bucket ? aws_s3_bucket.this[0].arn : null
}

output "bucket_region" {
  description = "The AWS region of the destination S3 bucket."
  value       = local.bucket_region
}
