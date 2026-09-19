output "ids" {
  description = "Map of WorkSpaces directory IDs, keyed by the same keys as var.directories. For PERSONAL directories this equals the underlying directory_id; for POOLS directories this is the ID AWS generated automatically."
  value       = { for k, v in aws_workspaces_directory.this : k => v.id }
}

output "aliases" {
  description = "Map of WorkSpaces directory aliases, keyed by the same keys as var.directories."
  value       = { for k, v in aws_workspaces_directory.this : k => v.alias }
}

output "customer_user_names" {
  description = "Map of service account user names, keyed by the same keys as var.directories."
  value       = { for k, v in aws_workspaces_directory.this : k => v.customer_user_name }
}

output "directory_names" {
  description = "Map of directory names, keyed by the same keys as var.directories."
  value       = { for k, v in aws_workspaces_directory.this : k => v.directory_name }
}

output "directory_types" {
  description = "Map of directory types, keyed by the same keys as var.directories."
  value       = { for k, v in aws_workspaces_directory.this : k => v.directory_type }
}

output "dns_ip_addresses" {
  description = "Map of the list of DNS server IP addresses for each directory, keyed by the same keys as var.directories."
  value       = { for k, v in aws_workspaces_directory.this : k => v.dns_ip_addresses }
}

output "iam_role_ids" {
  description = "Map of the IAM role identifiers Amazon WorkSpaces uses to call other AWS services on each directory's behalf, keyed by the same keys as var.directories."
  value       = { for k, v in aws_workspaces_directory.this : k => v.iam_role_id }
}

output "registration_codes" {
  description = "Map of directory registration codes (entered by users in the WorkSpaces client to connect), keyed by the same keys as var.directories."
  value       = { for k, v in aws_workspaces_directory.this : k => v.registration_code }
}

output "workspace_security_group_ids" {
  description = "Map of the security group IDs assigned to new WorkSpaces desktops in each directory, keyed by the same keys as var.directories."
  value       = { for k, v in aws_workspaces_directory.this : k => v.workspace_security_group_id }
}
