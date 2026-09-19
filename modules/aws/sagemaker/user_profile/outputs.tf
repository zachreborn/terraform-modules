###########################
# User Profile Outputs
###########################

output "id" {
  description = "The user profile Amazon Resource Name (ARN), which serves as its ID."
  value       = aws_sagemaker_user_profile.this.id
}

output "arn" {
  description = "The user profile ARN."
  value       = aws_sagemaker_user_profile.this.arn
}

output "user_profile_name" {
  description = "The name of the user profile."
  value       = aws_sagemaker_user_profile.this.user_profile_name
}

output "home_efs_file_system_uid" {
  description = "The ID of the user's profile in the Amazon Elastic File System (EFS) volume."
  value       = aws_sagemaker_user_profile.this.home_efs_file_system_uid
}
