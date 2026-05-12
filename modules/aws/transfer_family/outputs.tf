###########################
# Resource Outputs
###########################

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group for Transfer Family server logs"
  value       = aws_cloudwatch_log_group.transfer_family.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group for Transfer Family server logs"
  value       = aws_cloudwatch_log_group.transfer_family.name
}

output "logging_role_arn" {
  description = "The ARN of the IAM role used by Transfer Family to write CloudWatch logs"
  value       = module.transfer_family_logging_iam_role.arn
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.bucket.s3_bucket_arn
}

output "server_arn" {
  description = "The ARN of the transfer family server"
  value       = aws_transfer_server.this.arn
}

output "server_endpoint" {
  description = "The endpoint of the transfer family server"
  value       = aws_transfer_server.this.endpoint
}

output "server_host_key_fingerprint" {
  description = "The RSA private key fingerprint of the transfer family server"
  value       = aws_transfer_server.this.host_key_fingerprint
}

output "server_id" {
  description = "The ID of the transfer family server"
  value       = aws_transfer_server.this.id
}
