output "ids" {
  description = "Map of WorkSpaces directory IDs, keyed by the same keys as var.directories. For PERSONAL directories this equals the underlying directory_id; for POOLS directories this is the ID AWS generated automatically."
  value       = { for k, v in aws_workspaces_directory.this : k => v.id }
}
