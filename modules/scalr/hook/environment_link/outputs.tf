###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr environment hook link IDs keyed by the same logical name used in var.environment_hooks."
  value       = { for key, value in scalr_environment_hook.this : key => value.id }
}

output "environment_hooks" {
  description = "Map of full scalr_environment_hook resource objects keyed by the same logical name used in var.environment_hooks."
  value       = { for key, value in scalr_environment_hook.this : key => value }
}
