output "iam_role_arn" {
    value       = aws_iam_role.terraform_cloud.arn
    description = "The ARN of the IAM role for 'terraform_cloud' that Terraform Cloud/Enterprise will assume."
}
