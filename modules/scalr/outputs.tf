###########################
# Resource Outputs
###########################
output "environment_ids" {
  description = "Map of Environment names to their Scalr Environment IDs."
  value       = module.environment.ids
}

output "workspace_ids" {
  description = "Map of Workspace composite keys ('<environment>.<workspace>') to their Scalr Workspace IDs."
  value       = module.workspace.ids
}

output "vcs_provider_ids" {
  description = "Map of VCS Provider names to their Scalr VCS Provider IDs."
  value       = module.vcs_provider.ids
}

output "provider_configuration_ids" {
  description = "Map of every Provider Configuration name (across all AWS, AzureRM, Google, and custom types) to its Scalr Provider Configuration ID."
  value       = local.provider_configuration_ids
}

output "provider_configuration_aws_ids" {
  description = "Map of AWS Provider Configuration names to their Scalr Provider Configuration IDs."
  value       = { for name in keys(local.aws_provider_config) : name => local.provider_configuration_ids[name] }
}

output "provider_configuration_azurerm_ids" {
  description = "Map of AzureRM Provider Configuration names to their Scalr Provider Configuration IDs."
  value       = { for name in keys(local.azurerm_provider_config) : name => local.provider_configuration_ids[name] }
}

output "provider_configuration_google_ids" {
  description = "Map of Google Provider Configuration names to their Scalr Provider Configuration IDs."
  value       = { for name in keys(local.google_provider_config) : name => local.provider_configuration_ids[name] }
}

output "provider_configuration_custom_ids" {
  description = "Map of custom Provider Configuration names to their Scalr Provider Configuration IDs."
  value       = { for name in keys(local.custom_provider_config) : name => local.provider_configuration_ids[name] }
}

###########################
# Composition Wiring (verification)
###########################
# These outputs surface the non-sensitive, resolved inputs the root passes to its child modules so
# callers (and tests) can verify the YAML-to-submodule transformation without reaching into child
# module internals. They mirror the ./provider_configuration submodule's own resolved_defaults
# output. Sensitive credentials are never included here -- those are routed separately through each
# submodule's dedicated *_secrets / *_tokens map.
output "provider_configuration_custom" {
  description = "Resolved, non-sensitive custom provider configuration blocks (provider_name + arguments) passed to the ./provider_configuration submodule, keyed by configuration name. Exposed to verify the root's YAML-to-submodule wiring for custom providers. Sensitive custom argument values are routed separately via provider_configuration_secrets and are never included here (sensitive arguments carry value = null with sensitive = true)."
  value       = { for name, cfg in local.provider_configurations : name => cfg.custom if cfg.custom != null }
}

output "workspace_provider_configurations" {
  description = "Map of each workspace's resolved provider_configuration list (id + alias) as passed to the ./workspace submodule, keyed by '<environment>.<workspace>'. Exposed to verify the root's name-to-ID resolution and ordering."
  value       = { for key, workspace in local.workspace_inputs : key => workspace.provider_configuration }
}
