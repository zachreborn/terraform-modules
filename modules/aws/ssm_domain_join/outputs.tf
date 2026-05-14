########################################
# SSM Domain Join Outputs
########################################
output "ssm_document_arn" {
  description = "ARN of the SSM domain join document."
  value       = aws_ssm_document.this.arn
}

output "ssm_document_name" {
  description = "Name of the SSM domain join document."
  value       = aws_ssm_document.this.name
}

output "ssm_association_id" {
  description = "ID of the SSM State Manager association."
  value       = aws_ssm_association.this.association_id
}
