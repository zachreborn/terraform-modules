###########################
# Resource Outputs
###########################

output "arn" {
  value       = aws_ecr_repository.this.arn
  description = "The ARN of the ECR repository."
}

output "id" {
  value       = aws_ecr_repository.this.id
  description = "The registry ID (AWS account ID) where the repository was created."
}

output "registry_id" {
  value       = aws_ecr_repository.this.registry_id
  description = "The registry ID (AWS account ID) where the repository was created."
}

output "repository_url" {
  value       = aws_ecr_repository.this.repository_url
  description = "The URL of the ECR repository in the form <registry_id>.dkr.ecr.<region>.amazonaws.com/<repository_name>."
}

output "tags_all" {
  value       = aws_ecr_repository.this.tags_all
  description = "A map of all tags assigned to the ECR repository, including those inherited from the provider default_tags block."
}
