###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr workspace run schedule IDs (equal to the workspace ID) keyed by the same logical name used in var.workspace_run_schedules."
  value       = { for key, value in scalr_workspace_run_schedule.this : key => value.id }
}

output "workspace_run_schedules" {
  description = "Map of full scalr_workspace_run_schedule resource objects keyed by the same logical name used in var.workspace_run_schedules."
  value       = { for key, value in scalr_workspace_run_schedule.this : key => value }
}
