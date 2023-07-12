output "arn" {
  description = "The Amazon Resource Name (ARN) specifying the role."
  value       = aws_iam_role.this.arn
}
