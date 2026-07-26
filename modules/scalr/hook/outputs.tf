###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr hook IDs keyed by the same logical name used in var.hooks."
  value       = { for key, value in scalr_hook.this : key => value.id }
}

output "hooks" {
  description = "Map of full scalr_hook resource objects keyed by the same logical name used in var.hooks."
  value       = { for key, value in scalr_hook.this : key => value }
}
