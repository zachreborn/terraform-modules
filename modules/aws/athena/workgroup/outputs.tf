output "id" {
  description = "The name of the Athena workgroup, which serves as its ID."
  value       = aws_athena_workgroup.this.id
}

output "arn" {
  description = "ARN of the Athena workgroup."
  value       = aws_athena_workgroup.this.arn
}
