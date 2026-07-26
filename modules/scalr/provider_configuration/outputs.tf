###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Provider Configuration IDs, keyed by the same keys as var.provider_configurations."
  value       = { for k, v in scalr_provider_configuration.this : k => v.id }
}

output "default_ids" {
  description = "Map of Provider Configuration Default IDs (from the companion ./default submodule), keyed by the same keys as var.provider_configuration_defaults."
  value       = module.default.ids
}

output "resolved_defaults" {
  description = "Map of environment_id/provider_configuration_id pairs actually passed to the companion ./default submodule, keyed by the same keys as var.provider_configuration_defaults. Useful to verify composition wiring."
  value       = local.resolved_defaults
}
