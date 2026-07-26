###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Checkov integration IDs keyed by the same logical name used in var.checkov_integrations."
  value       = { for key, value in scalr_checkov_integration.this : key => value.id }
}

output "checkov_integrations" {
  description = "Map of full scalr_checkov_integration resource objects keyed by the same logical name used in var.checkov_integrations."
  value       = { for key, value in scalr_checkov_integration.this : key => value }
}
