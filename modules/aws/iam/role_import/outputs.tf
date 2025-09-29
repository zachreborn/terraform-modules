output "arn" {
  description = "The Amazon Resource Name (ARN) specifying the role."
  value       = aws_iam_role.this.arn
}

output "name" {
  description = "The name of the role."
  value       = aws_iam_role.this.name
}
