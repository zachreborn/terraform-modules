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

output "directory_aliases" {
  description = "Map of WorkSpaces directory aliases, keyed by the same keys as var.directories."
  value       = module.directories.aliases
}

output "directory_registration_codes" {
  description = "Map of directory registration codes (entered by users in the WorkSpaces client to connect), keyed by the same keys as var.directories."
  value       = module.directories.registration_codes
}

output "directory_dns_ip_addresses" {
  description = "Map of the list of DNS server IP addresses for each directory, keyed by the same keys as var.directories."
  value       = module.directories.dns_ip_addresses
}

output "directory_workspace_security_group_ids" {
  description = "Map of the security group IDs assigned to new WorkSpaces desktops in each directory, keyed by the same keys as var.directories."
  value       = module.directories.workspace_security_group_ids
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
  description = "Map of shared default KMS key ARNs created for volume encryption, keyed by Region. One key is created per distinct Region among entries that need it; empty when enable_default_kms_key is false or no entry needed one."
  value       = module.workspaces.kms_key_arn
}
