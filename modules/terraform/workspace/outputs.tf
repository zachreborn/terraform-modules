output "id" {
  value = tfe_workspace.this.id
}

output "execution_mode" {
  description = "The effective execution mode of the workspace as managed by the tfe_workspace_settings resource."
  value       = tfe_workspace_settings.this.execution_mode
}

output "workspace_settings_overwrites" {
  description = "Read-only attribute indicating whether execution_mode and agent_pool are set explicitly on the workspace (true) or inherited from organization/project defaults (false)."
  value       = tfe_workspace_settings.this.overwrites
}
