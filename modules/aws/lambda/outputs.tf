output "arn" {
  description = "The Amazon Resource Name (ARN) identifying the Lambda function."
  value       = aws_lambda_function.lambda_function.arn
}

output "function_name" {
  description = "The unique name of the Lambda function."
  value       = aws_lambda_function.lambda_function.function_name
}

output "invoke_arn" {
  description = "ARN to be used for invoking the Lambda function from API Gateway, e.g. in aws_api_gateway_integration's uri or aws_lambda_permission."
  value       = aws_lambda_function.lambda_function.invoke_arn
}

output "qualified_arn" {
  description = "The ARN identifying the function's published version."
  value       = aws_lambda_function.lambda_function.qualified_arn
}

output "version" {
  description = "Latest published version of the Lambda function."
  value       = aws_lambda_function.lambda_function.version
}

output "last_modified" {
  description = "The date this resource was last modified."
  value       = aws_lambda_function.lambda_function.last_modified
}

output "tags_all" {
  description = "Map of tags assigned to the resource, including those inherited from the provider default_tags configuration block."
  value       = aws_lambda_function.lambda_function.tags_all
}
