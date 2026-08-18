output "arn" {
  description = "The ARN of the Direct Connect gateway."
  value       = aws_dx_gateway.this.arn
}

output "id" {
  description = "The ID of the Direct Connect gateway."
  value       = aws_dx_gateway.this.id
}

output "owner_account_id" {
  description = "The ID of the AWS account that owns the Direct Connect gateway."
  value       = aws_dx_gateway.this.owner_account_id
}
