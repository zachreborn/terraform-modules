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

output "remote_state_sharing" {
  description = "Map of the effective remote_state_sharing value of each workspace (true when its state is shared with all workspaces in the environment), keyed by the same keys as var.workspaces. Reflects the account-wide default when var.workspaces[*].remote_state_sharing is unset."
  value       = { for k, v in scalr_workspace.this : k => v.remote_state_sharing }
}
