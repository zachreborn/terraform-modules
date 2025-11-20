output "arn" {
  description = "The ARN assigned by AWS for this user."
  value       = aws_iam_user.this.arn
}

output "id" {
  description = "The ID of the user."
  value       = aws_iam_user.this.id
}

output "user_name" {
  description = "The user's name."
  value       = aws_iam_user.this.name
}
