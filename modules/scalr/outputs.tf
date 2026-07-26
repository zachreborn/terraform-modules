###########################
# Resource Outputs
###########################
output "environment_ids" {
  description = "Map of Environment names to their Scalr Environment IDs."
  value       = { for name, environment in scalr_environment.this : name => environment.id }
}

output "workspace_ids" {
  description = "Map of Workspace composite keys ('<environment>.<workspace>') to their Scalr Workspace IDs."
  value       = { for key, workspace in scalr_workspace.this : key => workspace.id }
}

output "vcs_provider_ids" {
  description = "Map of VCS Provider names to their Scalr VCS Provider IDs."
  value       = { for name, vcs_provider in scalr_vcs_provider.this : name => vcs_provider.id }
}

output "provider_configuration_ids" {
  description = "Map of AWS Provider Configuration names to their Scalr Provider Configuration IDs."
  value       = { for name, provider_configuration in scalr_provider_configuration.aws : name => provider_configuration.id }
}

output "provider_configuration_azurerm_ids" {
  description = "Map of AzureRM Provider Configuration names to their Scalr Provider Configuration IDs."
  value       = { for name, provider_configuration in scalr_provider_configuration.azurerm : name => provider_configuration.id }
}

output "provider_configuration_google_ids" {
  description = "Map of Google Provider Configuration names to their Scalr Provider Configuration IDs."
  value       = { for name, provider_configuration in scalr_provider_configuration.google : name => provider_configuration.id }
}

output "provider_configuration_custom_ids" {
  description = "Map of custom Provider Configuration names to their Scalr Provider Configuration IDs."
  value       = { for name, provider_configuration in scalr_provider_configuration.custom : name => provider_configuration.id }
}
