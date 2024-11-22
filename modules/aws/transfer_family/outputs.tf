###########################
# Resource Outputs
###########################

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
