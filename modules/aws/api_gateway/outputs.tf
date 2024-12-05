#####################
# Outputs
#####################

output "id" {
  description = "The API identifier"
  value       = aws_apigatewayv2_api.api.id
}

output "api_endpoint" {
  description = "The URI of the API"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "arn" {
  description = "The ARN of the API"
  value       = aws_apigatewayv2_api.api.arn
}

output "execution_arn" {
  description = "The ARN prefix to be used in permission policies"
  value       = aws_apigatewayv2_api.api.execution_arn
}

output "api_key_selection_expression" {
  description = "The API key selection expression for the API"
  value       = aws_apigatewayv2_api.api.api_key_selection_expression
}

output "cors_configuration" {
  description = "The CORS configuration for the API"
  value       = aws_apigatewayv2_api.api.cors_configuration
}

output "tags_all" {
  description = "Map of tags assigned to the resource"
  value       = aws_apigatewayv2_api.api.tags_all
}
