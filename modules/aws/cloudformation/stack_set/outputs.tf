###########################
# Resource Outputs
###########################
output "arn" {
  description = "The ARN of the stack set."
  value       = aws_cloudformation_stack_set.this.arn
}

output "id" {
  description = "The unique ID of the stack set."
  value       = aws_cloudformation_stack_set.this.id
}
