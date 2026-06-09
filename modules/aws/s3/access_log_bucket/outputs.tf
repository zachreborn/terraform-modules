output "bucket_id" {
  description = "Name (ID) of the S3 access log bucket"
  value       = module.this.s3_bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 access log bucket"
  value       = module.this.s3_bucket_arn
}

output "bucket_region" {
  description = "Region of the S3 access log bucket"
  value       = module.this.s3_bucket_region
}
