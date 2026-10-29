#####################
# Outputs
#####################

output "id" {
  description = "The API identifier"
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "The URI of the API"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "arn" {
  description = "The ARN of the API"
  value       = aws_apigatewayv2_api.this.arn
}

output "execution_arn" {
  description = "The ARN prefix to be used in permission policies"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "api_key_selection_expression" {
  description = "The API key selection expression for the API"
  value       = aws_apigatewayv2_api.this.api_key_selection_expression
}

output "cors_configuration" {
  description = "The CORS configuration for the API"
  value       = aws_apigatewayv2_api.this.cors_configuration
}

output "tags_all" {
  description = "Map of tags assigned to the resource"
  value       = aws_apigatewayv2_api.this.tags_all
}

# Keyed resource outputs preserve logical caller identities, including empty maps.
output "integration_ids" {
  description = "Map of integration ids keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_integration.this : k => v.id })
}

output "route_ids" {
  description = "Map of route ids keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_route.this : k => v.id })
}

output "authorizer_ids" {
  description = "Map of authorizer ids keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_authorizer.this : k => v.id })
}

output "model_ids" {
  description = "Map of model ids keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_model.this : k => v.id })
}

output "integration_response_ids" {
  description = "Map of integration response ids keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_integration_response.this : k => v.id })
}

output "route_response_ids" {
  description = "Map of route response ids keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_route_response.this : k => v.id })
}

output "vpc_link_ids" {
  description = "Map of vpc link ids keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_vpc_link.this : k => v.id })
}

output "vpc_link_arns" {
  description = "Map of vpc link arns keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_vpc_link.this : k => v.arn })
}

output "stage_ids" {
  description = "Map of stage ids keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_stage.this : k => v.id })
}

output "stage_invoke_urls" {
  description = "Map of stage invoke urls keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_stage.this : k => v.invoke_url })
}

output "stage_execution_arns" {
  description = "Map of stage execution arns keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_stage.this : k => v.execution_arn })
}

output "stage_arns" {
  description = "Map of stage arns keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_stage.this : k => v.arn })
}

output "integration_response_selection_expressions" {
  description = "Map of integration response selection expressions keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_integration.this : k => v.integration_response_selection_expression })
}

output "domain_tags_all" {
  description = "Map of domain tags all keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_domain_name.this : k => v.tags_all })
}

output "stage_tags_all" {
  description = "Map of stage tags all keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_stage.this : k => v.tags_all })
}

output "vpc_link_tags_all" {
  description = "Map of vpc link tags all keyed by the original logical resource keys."
  value       = tomap({ for k, v in aws_apigatewayv2_vpc_link.this : k => v.tags_all })
}

output "domains" {
  description = "Domain identifiers and routing metadata keyed by domain name."
  value = tomap({ for k, v in aws_apigatewayv2_domain_name.this : k => {
    id                               = v.id
    arn                              = v.arn
    target_domain_name               = v.domain_name_configuration[0].target_domain_name
    hosted_zone_id                   = v.domain_name_configuration[0].hosted_zone_id
    api_mapping_selection_expression = v.api_mapping_selection_expression
  } })
}
