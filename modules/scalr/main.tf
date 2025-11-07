###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.0"
    }
  }
}

###########################
# Data Sources
###########################
data "scalr_current_account" "account" {}

###########################
# Locals
###########################
locals {
  yaml_config = yamldecode(var.scalr_config)
  workspaces = merge([for environment, value in local.yaml_config : {
    for workspace, workspace_value in value.workspaces : "${environment}.${workspace}" => merge(workspace_value, {
      environment = environment
      workspace   = workspace
    })
  }]...)
  aws_provider_config = var.aws_provider_config != null ? yamldecode(var.aws_provider_config) : {}
}

###########################
# VCS Provider Configurations
###########################
# resource "scalr_vcs_provider" "this" {
#   account_id            = data.scalr_current_account.account.id
#   agent_pool_id         = var.vcs_provider_agent_pool_id
#   draft_pr_runs_enabled = var.vcs_provider_draft_pr_runs_enabled
#   environments          = var.vcs_provider_environments
#   name                  = var.vcs_provider_name
#   token                 = var.vcs_provider_token
#   url                   = var.vcs_provider_url
#   username              = var.vcs_provider_username
#   vcs_type              = var.vcs_provider_vcs_type
# }

###########################
# Provider Configurations
###########################

resource "scalr_provider_configuration" "aws" {
  for_each               = local.aws_provider_config
  account_id             = data.scalr_current_account.account.id
  environments           = try(each.value.environments, var.aws_environments)
  export_shell_variables = try(each.value.export_shell_variables, var.aws_export_shell_variables)
  name                   = each.key
  owners                 = try(each.value.owners, var.aws_owners)
  aws {
    access_key          = try(each.value.access_key, var.aws_access_key)
    account_type        = try(each.value.account_type, var.aws_account_type)
    audience            = try(each.value.audience, var.aws_audience)
    credentials_type    = try(each.value.credentials_type, var.aws_credentials_type)
    external_id         = try(each.value.external_id, var.aws_external_id)
    role_arn            = try(each.value.role_arn, var.aws_role_arn)
    secret_key          = try(each.value.secret_key, var.aws_secret_key)
    trusted_entity_type = try(each.value.trusted_entity_type, var.aws_trusted_entity_type)
  }
}

###########################
# Environment Configurations
###########################

resource "scalr_environment" "this" {
  for_each                        = local.yaml_config
  account_id                      = data.scalr_current_account.account.id
  default_provider_configurations = try(each.value.default_provider_configurations, var.environment_default_provider_configurations)
  default_workspace_agent_pool_id = try(each.value.default_workspace_agent_pool_id, var.environment_default_workspace_agent_pool_id)
  federated_environments          = try(each.value.federated_environments, var.environment_federated_environments)
  mask_sensitive_output           = try(each.value.mask_sensitive_output, var.environment_mask_sensitive_output)
  name                            = each.key
  remote_backend                  = try(each.value.remote_backend, var.environment_remote_backend)
  remote_backend_overridable      = try(each.value.remote_backend_overridable, var.environment_remote_backend_overridable)
  storage_profile_id              = try(each.value.storage_profile_id, var.environment_storage_profile_id)
  tag_ids                         = try(each.value.tag_ids, var.environment_tag_ids)
}

###########################
# Workspace Configurations
###########################

resource "scalr_workspace" "this" {
  for_each                    = local.workspaces
  agent_pool_id               = try(each.value.agent_pool_id, var.workspace_agent_pool_id)
  auto_apply                  = try(each.value.auto_apply, var.workspace_auto_apply)
  auto_queue_runs             = try(each.value.auto_queue_runs, var.workspace_auto_queue_runs)
  deletion_protection_enabled = try(each.value.deletion_protection_enabled, var.workspace_deletion_protection_enabled)
  environment_id              = scalr_environment.this[each.value.environment].id
  execution_mode              = try(each.value.execution_mode, var.workspace_execution_mode)
  force_latest_run            = try(each.value.force_latest_run, var.workspace_force_latest_run)
  iac_platform                = try(each.value.iac_platform, var.workspace_iac_platform)
  module_version_id           = try(each.value.module_version_id, var.workspace_module_version_id)
  name                        = each.value.workspace
  remote_backend              = try(each.value.remote_backend, var.workspace_remote_backend)
  remote_state_consumers      = try(each.value.remote_state_consumers, var.workspace_remote_state_consumers)
  run_operation_timeout       = try(each.value.run_operation_timeout, var.workspace_run_operation_timeout)
  ssh_key_id                  = try(each.value.ssh_key_id, var.workspace_ssh_key_id)
  tag_ids                     = try(each.value.tag_ids, var.workspace_tag_ids)
  terraform_version           = try(each.value.terraform_version, var.workspace_terraform_version)
  type                        = try(each.value.type, var.workspace_type)
  var_files                   = try(each.value.var_files, var.workspace_var_files)
  vcs_provider_id             = try(each.value.vcs_provider_id, var.workspace_vcs_provider_id)
  working_directory           = try(each.value.working_directory, var.workspace_working_directory)

  dynamic "provider_configuration" {
    for_each = try(each.value.provider_configuration, [])
    content {
      id = provider_configuration.value
    }
  }

  dynamic "vcs_repo" {
    for_each = each.value.vcs_repo != null ? [1] : []
    content {
      branch             = try(each.value.vcs_repo.branch, null)
      dry_runs_enabled   = try(each.value.vcs_repo.dry_runs_enabled, true)
      identifier         = each.value.vcs_repo.identifier
      ingress_submodules = try(each.value.vcs_repo.ingress_submodules, false)
      path               = try(each.value.vcs_repo.path, null)
      trigger_patterns   = try(each.value.vcs_repo.trigger_patterns, null)
      trigger_prefixes   = try(each.value.vcs_repo.trigger_prefixes, null)
      version_constraint = try(each.value.vcs_repo.version_constraint, null)
    }
  }
}
