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
