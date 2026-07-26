###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr workload identity provider IDs keyed by the same logical name used in var.workload_identity_providers."
  value       = { for key, value in scalr_workload_identity_provider.this : key => value.id }
}

output "workload_identity_providers" {
  description = "Map of full scalr_workload_identity_provider resource objects keyed by the same logical name used in var.workload_identity_providers."
  value       = { for key, value in scalr_workload_identity_provider.this : key => value }
}
