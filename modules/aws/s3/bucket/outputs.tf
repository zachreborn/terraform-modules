output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "s3_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = aws_s3_bucket.this.hosted_zone_id
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.this.region
}

output "s3_website_domain" {
  description = "Domain of the website endpoint. Can be utilized to create Route 53 alias records"
  value       = aws_s3_bucket_website_configuration.this[0].website_domain
}

output "s3_website_endpoint" {
  description = "Endpoint of the website"
  value       = aws_s3_bucket_website_configuration.this[0].website_endpoint
}
