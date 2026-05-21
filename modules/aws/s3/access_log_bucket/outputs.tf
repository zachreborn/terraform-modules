output "bucket_id" {
  description = "Name (ID) of the S3 access log bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 access log bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Bucket domain name in the format: <bucket>.s3.amazonaws.com"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Bucket region-specific domain name in the format: <bucket>.s3.<region>.amazonaws.com"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}
