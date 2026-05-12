output "ssm_document_name" {
  value       = aws_ssm_document.default.name
  description = "The name of the SSM domain join document."
}

output "ssm_document_arn" {
  value       = aws_ssm_document.default.arn
  description = "The ARN of the SSM domain join document."
}

output "ssm_association_id" {
  value       = aws_ssm_association.default.association_id
  description = "The ID of the SSM association."
}
