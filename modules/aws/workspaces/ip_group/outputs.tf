output "ids" {
  description = "Map of WorkSpaces IP access control group IDs, keyed by the same keys as var.ip_groups."
  value       = { for k, v in aws_workspaces_ip_group.this : k => v.id }
}
