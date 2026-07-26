###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Provider Configuration Default IDs, keyed by the same keys as var.provider_configuration_defaults."
  value       = { for k, v in scalr_provider_configuration_default.this : k => v.id }
}
