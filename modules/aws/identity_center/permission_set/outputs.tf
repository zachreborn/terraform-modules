output "arn" {
  description = "The ARN of the permission set"
  value       = aws_ssoadmin_permission_set.this.arn
}

output "created_date" {
  description = "The date the permission set was created"
  value       = aws_ssoadmin_permission_set.this.created_date
}

output "id" {
  description = "The ID of the permission set"
  value       = aws_ssoadmin_permission_set.this.id
}
