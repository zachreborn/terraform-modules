###########################
# Resource Outputs
###########################

output "arn" {
  value       = aws_ecr_repository.this.arn
  description = "The ARN of the ECR repository."
}
