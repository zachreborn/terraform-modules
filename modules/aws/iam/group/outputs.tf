output "arn" {
  description = "The ARN assigned by AWS for this IAM group."
  value       = aws_iam_group.this.arn
}

output "id" {
  description = "The ID of the IAM group."
  value       = aws_iam_group.this.id
}

output "name" {
  description = "The name of the IAM group."
  value       = aws_iam_group.this.name
}

output "path" {
  description = "The path of the IAM group in AWS."
  value       = aws_iam_group.this.path
}
