###########################
# API Gateway Outputs
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

###########################
# Origin Access Control Outputs
###########################
output "origin_access_control_ids" {
  description = "Map of Origin Access Control IDs created by this module, keyed by OAC name. Empty when origin_access_controls is null."
  value       = { for k, v in aws_cloudfront_origin_access_control.this : k => v.id }
}

output "origin_access_control_arns" {
  description = "Map of Origin Access Control ARNs created by this module, keyed by OAC name. Empty when origin_access_controls is null."
  value       = { for k, v in aws_cloudfront_origin_access_control.this : k => v.arn }
}

output "origin_access_control_etags" {
  description = "Map of Origin Access Control etags created by this module, keyed by OAC name. Empty when origin_access_controls is null."
  value       = { for k, v in aws_cloudfront_origin_access_control.this : k => v.etag }
}
