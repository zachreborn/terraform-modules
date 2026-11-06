###########################
# Stack Outputs
###########################
output "id" {
  description = "Stack ARN."
  value       = aws_cloudformation_stack.this.id
}

output "name" {
  description = "Stack name."
  value       = aws_cloudformation_stack.this.name
}

output "outputs" {
  description = "Outputs exported by the CloudFormation template."
  value       = aws_cloudformation_stack.this.outputs
}

output "tags_all" {
  description = "All stack tags, including provider default tags."
  value       = aws_cloudformation_stack.this.tags_all
}
