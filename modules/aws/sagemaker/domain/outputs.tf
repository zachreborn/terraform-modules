###########################
# Domain Outputs
###########################

output "id" {
  description = "The ID of the SageMaker domain."
  value       = aws_sagemaker_domain.this.id
}

output "arn" {
  description = "The ARN of the SageMaker domain."
  value       = aws_sagemaker_domain.this.arn
}

output "url" {
  description = "The domain's URL used to access the SageMaker Studio environment."
  value       = aws_sagemaker_domain.this.url
}

output "home_efs_file_system_id" {
  description = "The ID of the Amazon Elastic File System (EFS) managed by this domain."
  value       = aws_sagemaker_domain.this.home_efs_file_system_id
}

output "security_group_id_for_domain_boundary" {
  description = "The ID of the security group that authorizes traffic between the RSessionGateway apps and the RStudioServerPro app."
  value       = aws_sagemaker_domain.this.security_group_id_for_domain_boundary
}

output "single_sign_on_managed_application_instance_id" {
  description = "The SSO managed application instance ID."
  value       = aws_sagemaker_domain.this.single_sign_on_managed_application_instance_id
}

output "single_sign_on_application_arn" {
  description = "The ARN of the application managed by SageMaker in IAM Identity Center."
  value       = aws_sagemaker_domain.this.single_sign_on_application_arn
}
