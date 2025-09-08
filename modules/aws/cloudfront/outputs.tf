###########################
# Resource Outputs
###########################
output "arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "Domain name corresponding to the distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID that can be used to route an Alias record to"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "origin_access_control_ids" {
  description = "Map of Origin Access Control names to their IDs"
  value       = { for k, v in aws_cloudfront_origin_access_control.this : k => v.id }
}