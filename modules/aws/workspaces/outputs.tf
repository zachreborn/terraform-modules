############################################################
# Service Role
############################################################

output "service_role_arn" {
  description = "ARN of the workspaces_DefaultRole IAM role, or null when enable_service_role is false."
  value       = try(module.service_role["this"].arn, null)
}

output "service_role_name" {
  description = "Name of the workspaces_DefaultRole IAM role, or null when enable_service_role is false."
  value       = try(module.service_role["this"].name, null)
}

############################################################
# IP Access Control Groups
############################################################

output "ip_group_ids" {
  description = "Map of WorkSpaces IP access control group IDs, keyed by the same keys as var.ip_groups."
  value       = module.ip_groups.ids
}

############################################################
# Directories
############################################################

output "directory_ids" {
  description = "Map of WorkSpaces directory IDs, keyed by the same keys as var.directories."
  value       = module.directories.ids
}

############################################################
# Connection Aliases
############################################################

output "connection_alias_ids" {
  description = "Map of WorkSpaces connection alias IDs, keyed by the same keys as var.connection_aliases."
  value       = module.connection_aliases.ids
}

############################################################
# Desktops
############################################################

output "workspace_ids" {
  description = "Map of WorkSpaces desktop IDs, keyed by the same keys as var.workspaces."
  value       = module.workspaces.ids
}

output "workspace_ip_addresses" {
  description = "Map of WorkSpaces desktop IP addresses, keyed by the same keys as var.workspaces."
  value       = module.workspaces.ip_addresses
}

output "workspace_computer_names" {
  description = "Map of WorkSpaces desktop computer names (as seen by the operating system), keyed by the same keys as var.workspaces."
  value       = module.workspaces.computer_names
}

output "kms_key_arn" {
  description = "ARN of the shared default KMS key created for volume encryption, or null when enable_default_kms_key is false or no entry needed it."
  value       = module.workspaces.kms_key_arn
}
