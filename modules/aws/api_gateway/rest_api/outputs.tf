###########################
# API Gateway Outputs
###########################
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

output "created_date" {
  description = "Creation date of the REST API"
  value       = aws_api_gateway_rest_api.this.created_date
}

###########################
# Resource Outputs
###########################
output "resources" {
  description = "API Gateway resources created"
  value       = { for k, v in aws_api_gateway_resource.this : k => v }
}

###########################
# Model Outputs
###########################
output "models" {
  description = "API Gateway models created"
  value       = { for k, v in aws_api_gateway_model.this : k => v }
}

###########################
# Request Validator Outputs
###########################
output "request_validators" {
  description = "API Gateway request validators created"
  value       = { for k, v in aws_api_gateway_request_validator.this : k => v }
}

###########################
# Authorizer Outputs
###########################
output "authorizers" {
  description = "API Gateway authorizers created"
  value       = { for k, v in aws_api_gateway_authorizer.this : k => v }
}

###########################
# Method Outputs
###########################
output "methods" {
  description = "API Gateway methods created"
  value       = { for k, v in aws_api_gateway_method.this : k => v }
}

output "root_methods" {
  description = "API Gateway root resource methods created"
  value       = { for k, v in aws_api_gateway_method.root : k => v }
}

###########################
# Method Response Outputs
###########################
output "method_responses" {
  description = "API Gateway method responses created"
  value       = { for k, v in aws_api_gateway_method_response.this : k => v }
}

###########################
# Integration Outputs
###########################
output "integrations" {
  description = "API Gateway integrations created"
  value       = { for k, v in aws_api_gateway_integration.this : k => v }
}

output "root_integrations" {
  description = "API Gateway root resource integrations created"
  value       = { for k, v in aws_api_gateway_integration.root : k => v }
}

###########################
# Integration Response Outputs
###########################
output "integration_responses" {
  description = "API Gateway integration responses created"
  value       = { for k, v in aws_api_gateway_integration_response.this : k => v }
}

###########################
# Gateway Response Outputs
###########################
output "gateway_responses" {
  description = "API Gateway gateway responses created"
  value       = { for k, v in aws_api_gateway_gateway_response.this : k => v }
}

###########################
# VPC Link Outputs
###########################
output "vpc_links" {
  description = "VPC Links created by this module"
  value       = { for k, v in aws_api_gateway_vpc_link.this : k => v }
}

###########################
# Deployment Outputs
###########################
output "deployment_id" {
  description = "ID of the API Gateway deployment"
  value       = aws_api_gateway_deployment.this.id
}


###########################
# Stage Outputs
###########################
output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.this.stage_name
}

output "stage_id" {
  description = "ID of the API Gateway stage"
  value       = aws_api_gateway_stage.this.id
}

output "stage_arn" {
  description = "ARN of the API Gateway stage"
  value       = aws_api_gateway_stage.this.arn
}

output "stage_invoke_url" {
  description = "Invoke URL for the API Gateway stage"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "stage_execution_arn" {
  description = "Execution ARN to be used in Lambda permissions"
  value       = aws_api_gateway_stage.this.execution_arn
}

###########################
# Method Settings Outputs
###########################
output "method_settings" {
  description = "API Gateway method settings created"
  value       = { for k, v in aws_api_gateway_method_settings.this : k => v }
}

###########################
# Domain Name Outputs
###########################
output "domain_name" {
  description = "Domain name of the API Gateway (if configured)"
  value       = var.domain_name != null ? aws_api_gateway_domain_name.this[0].domain_name : null
}

output "domain_name_id" {
  description = "Internal identifier of the domain name"
  value       = var.domain_name != null ? aws_api_gateway_domain_name.this[0].id : null
}

output "domain_name_arn" {
  description = "ARN of the domain name"
  value       = var.domain_name != null ? aws_api_gateway_domain_name.this[0].arn : null
}

output "domain_name_target_domain_name" {
  description = "Target domain name for the API Gateway custom domain (for DNS alias)"
  value       = var.domain_name != null ? aws_api_gateway_domain_name.this[0].regional_domain_name : null
}

output "domain_name_hosted_zone_id" {
  description = "Hosted zone ID for the API Gateway custom domain (for Route53 alias)"
  value       = var.domain_name != null ? aws_api_gateway_domain_name.this[0].regional_zone_id : null
}

output "certificate_arn" {
  description = "ARN of the ACM certificate used (from input variable)"
  value       = var.domain_name != null ? var.certificate_arn : null
}

###########################
# Base Path Mapping Outputs
###########################
output "base_path_mapping_id" {
  description = "ID of the base path mapping"
  value       = var.domain_name != null ? aws_api_gateway_base_path_mapping.this[0].id : null
}

###########################
# mTLS Configuration Outputs
###########################
output "mtls_enabled" {
  description = "Whether mTLS is enabled"
  value       = var.enable_mtls
}

output "truststore_uri" {
  description = "S3 URI of the truststore file used for mTLS (from configuration)"
  value       = var.enable_mtls && var.mtls_config != null ? var.mtls_config.truststore_uri : null
}

output "truststore_version" {
  description = "Version of the truststore file used for mTLS (from configuration)"
  value       = var.enable_mtls && var.mtls_config != null ? var.mtls_config.truststore_version : null
}

###########################
# Usage Plan Outputs
###########################
output "usage_plans" {
  description = "API Gateway usage plans created"
  value       = { for k, v in aws_api_gateway_usage_plan.this : k => v }
}

###########################
# API Key Outputs
###########################
output "api_keys" {
  description = "API Gateway API keys created"
  value = {
    for k, v in aws_api_gateway_api_key.this : k => {
      id                = v.id
      arn               = v.arn
      name              = v.name
      description       = v.description
      enabled           = v.enabled
      created_date      = v.created_date
      last_updated_date = v.last_updated_date
      # Value is sensitive and excluded from output for security
    }
  }
  sensitive = true
}

output "api_key_values" {
  description = "API key values (sensitive) - only use when necessary"
  value       = { for k, v in aws_api_gateway_api_key.this : k => v.value }
  sensitive   = true
}

###########################
# Usage Plan Key Association Outputs
###########################
output "usage_plan_keys" {
  description = "API Gateway usage plan key associations created"
  value       = { for k, v in aws_api_gateway_usage_plan_key.this : k => v }
}
