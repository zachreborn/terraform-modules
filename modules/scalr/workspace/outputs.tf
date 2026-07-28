###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Workspace IDs, keyed by the same keys as var.workspaces."
  value       = { for k, v in scalr_workspace.this : k => v.id }
}

output "has_resources" {
  description = "Map of whether each workspace currently has active resources in its state version, keyed by the same keys as var.workspaces."
  value       = { for k, v in scalr_workspace.this : k => v.has_resources }
}

output "created_by" {
  description = "Map of details about the user that created each workspace, keyed by the same keys as var.workspaces."
  value       = { for k, v in scalr_workspace.this : k => v.created_by }
}
