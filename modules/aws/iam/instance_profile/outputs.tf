###########################
# Resource Outputs
###########################
output "arn" {
  description = "ARN assigned by AWS to the instance profile."
  value       = aws_iam_instance_profile.this.arn
}

output "name" {
  description = "Resolved instance-profile name, including a name generated from name_prefix."
  value       = aws_iam_instance_profile.this.name
}

output "unique_id" {
  description = "AWS-assigned unique ID of the instance profile."
  value       = aws_iam_instance_profile.this.unique_id
}

output "id" {
  description = "Instance-profile ID, which equals its name."
  value       = aws_iam_instance_profile.this.id
}

output "create_date" {
  description = "Creation timestamp of the instance profile."
  value       = aws_iam_instance_profile.this.create_date
}

output "path" {
  description = "Applied instance-profile path."
  value       = aws_iam_instance_profile.this.path
}

output "role" {
  description = "IAM role name attached to the instance profile."
  value       = aws_iam_instance_profile.this.role
}

output "tags_all" {
  description = "All instance-profile tags, including inherited provider default_tags."
  value       = aws_iam_instance_profile.this.tags_all
}
