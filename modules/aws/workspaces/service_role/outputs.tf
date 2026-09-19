output "arn" {
  description = "The Amazon Resource Name (ARN) of the workspaces_DefaultRole IAM role."
  value       = module.role.arn
}

output "name" {
  description = "The name of the workspaces_DefaultRole IAM role."
  value       = module.role.name
}

output "policy_arns" {
  description = "List of managed policy ARNs attached to the role (always includes AmazonWorkSpacesServiceAccess, plus AmazonWorkSpacesSelfServiceAccess when enable_self_service_access is true)."
  value       = local.policy_arns
}
