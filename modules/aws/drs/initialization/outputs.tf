###########################
# Resource Outputs
###########################

output "role_arns" {
  description = "Map of Elastic Disaster Recovery service role ARNs, keyed by role name. Empty when create_service_roles is false."
  value       = { for role_name, role in module.role : role_name => role.arn }
}

output "role_names" {
  description = "Map of Elastic Disaster Recovery service role names, keyed by role name. Empty when create_service_roles is false."
  value       = { for role_name, role in module.role : role_name => role.name }
}

output "instance_profile_arns" {
  description = "Map of instance profile ARNs for the EC2-assumed Elastic Disaster Recovery roles, keyed by role name. Empty when create_service_roles is false."
  value       = { for role_name, profile in aws_iam_instance_profile.this : role_name => profile.arn }
}

output "instance_profile_names" {
  description = "Map of instance profile names for the EC2-assumed Elastic Disaster Recovery roles, keyed by role name. Empty when create_service_roles is false."
  value       = { for role_name, profile in aws_iam_instance_profile.this : role_name => profile.name }
}

output "service_linked_role_arn" {
  description = "ARN of the AWSServiceRoleForElasticDisasterRecovery service-linked role, or null when create_service_linked_role is false."
  value       = try(aws_iam_service_linked_role.this[0].arn, null)
}

output "service_linked_role_name" {
  description = "Name of the AWSServiceRoleForElasticDisasterRecovery service-linked role, or null when create_service_linked_role is false."
  value       = try(aws_iam_service_linked_role.this[0].name, null)
}
