###########################
# Resource Outputs
###########################
output "id" {
  description = "The unique ID of the stack."
  value       = aws_cloudformation_stack.this.id
}

output "outputs" {
  description = "A map containing all of the outputs from the stack."
  value       = aws_cloudformation_stack.this.outputs
}
