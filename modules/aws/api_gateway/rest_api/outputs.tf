# API Gateway Outputs

output "api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "api_name" {
  description = "Name of the REST API"
  value       = aws_api_gateway_rest_api.this.name
}

output "execution_arn" {
  description = "Execution ARN of the REST API"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "root_resource_id" {
  description = "Resource ID of the REST API root resource"
  value       = aws_api_gateway_rest_api.this.root_resource_id
}

# Domain Name Outputs
output "domain_name" {
  description = "Domain name of the API Gateway (if configured)"
  value       = var.enable_mtls && var.domain_name != null ? aws_api_gateway_domain_name.this[0].domain_name : null
}

output "domain_name_target_domain_name" {
  description = "Target domain name for the API Gateway custom domain"
  value       = var.enable_mtls && var.domain_name != null ? aws_api_gateway_domain_name.this[0].regional_domain_name : null
}

output "domain_name_hosted_zone_id" {
  description = "Hosted zone ID for the API Gateway custom domain"
  value       = var.enable_mtls && var.domain_name != null ? aws_api_gateway_domain_name.this[0].regional_zone_id : null
}

# Stage Outputs
output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.this.stage_name
}

output "stage_invoke_url" {
  description = "Invoke URL for the API Gateway stage"
  value       = aws_api_gateway_stage.this.invoke_url
}

# VPC Links Outputs
output "vpc_links" {
  description = "VPC Links created by this module"
  value       = { for k, v in aws_api_gateway_vpc_link.this : k => v }
}

# mTLS Configuration Outputs
output "truststore_s3_uri" {
  description = "S3 URI of the truststore file used for mTLS (from configuration)"
  value       = var.enable_mtls && var.domain_name != null && var.mtls_config != null ? var.mtls_config.truststore_uri : null
}

output "truststore_version_id" {
  description = "Version ID of the truststore file used for mTLS (from configuration)"
  value       = var.enable_mtls && var.domain_name != null && var.mtls_config != null ? var.mtls_config.truststore_version : null
}

# Certificate Outputs
output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.enable_mtls && var.domain_name != null ? aws_acm_certificate.domain[0].arn : null
}

# Resources Outputs
output "resources" {
  description = "API Gateway resources created"
  value       = { for k, v in aws_api_gateway_resource.this : k => v }
}

output "methods" {
  description = "API Gateway methods created"
  value       = { for k, v in aws_api_gateway_method.this : k => v }
}