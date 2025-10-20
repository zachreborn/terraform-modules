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
  yaml_config    = yamldecode(var.environments_config)
  workspaces_map = { for environment, value in local.yaml_config : environment => value.workspaces }
  workspaces = { for item in flatten([for environment, env_conf in local.yaml_config : [
    for workspace_name, workspace_value in env_conf.workspaces : {
      agent_pool_id               = workspace_value.agent_pool_id
      auto_apply                  = workspace_value.auto_apply
      auto_queue_runs             = workspace_value.auto_queue_runs
      deletion_protection_enabled = workspace_value.deletion_protection_enabled
      environment_id              = scalr_environment.this[environment].id
      environment_name            = environment
      execution_mode              = workspace_value.execution_mode
      force_latest_run            = workspace_value.force_latest_run
      iac_platform                = workspace_value.iac_platform
      module_version_id           = workspace_value.module_version_id
      name                        = workspace_value.name
      operations                  = workspace_value.operations
      provider_configuration      = workspace_value.provider_configuration
      remote_state_consumers      = workspace_value.remote_state_consumers
      run_operation_timeout       = workspace_value.run_operation_timeout
      ssh_key_id                  = workspace_value.ssh_key_id
      tag_ids                     = workspace_value.tag_ids
      terraform_version           = workspace_value.terraform_version
      type                        = workspace_value.type
      var_files                   = workspace_value.var_files
      working_directory           = workspace_value.working_directory
    }
  ]]) : "${item.environment_name}.${item.workspace_name}" => item }
}

###########################
# Provider Configurations
###########################

resource "scalr_provider_configuration" "scalr" {
  account_id   = data.scalr_current_account.account.id
  environments = var.scalr_environments
  name         = var.scalr_provider_name
  owners       = var.scalr_owners
  scalr {
    hostname = var.scalr_hostname
    token    = var.scalr_token
  }
}

resource "scalr_provider_configuration" "aws" {
  account_id             = data.scalr_current_account.account.id
  environments           = var.aws_environments
  export_shell_variables = var.export_shell_variables
  name                   = var.aws_provider_name
  owners                 = var.aws_owners
  aws {
    access_key          = var.aws_access_key
    account_type        = var.aws_account_type
    audience            = var.aws_audience
    credentials_type    = var.aws_credentials_type
    external_id         = var.aws_external_id
    role_arn            = var.aws_role_arn
    secret_key          = var.aws_secret_key
    trusted_entity_type = var.aws_trusted_entity_type
  }
}

# resource "scalr_provider_configuration_default" "this" {
#   for_each                  = var.default_environment_ids != null ? toset(var.default_environment_ids) : {}
#   environment_id            = each.key
#   provider_configuration_id = scalr_provider_configuration.aws.id
# }

###########################
# Environment Configurations
###########################

resource "scalr_environment" "this" {
  for_each                        = local.yaml_config
  account_id                      = data.scalr_current_account.account.id
  default_provider_configurations = each.value.default_provider_configurations
  default_workspace_agent_pool_id = each.value.default_workspace_agent_pool_id
  federated_environments          = each.value.federated_environments
  mask_sensitive_output           = each.value.mask_sensitive_output
  name                            = each.key
  remote_backend                  = each.value.remote_backend
  remote_backend_overridable      = each.value.remote_backend_overridable
  storage_profile_id              = each.value.storage_profile_id
  tag_ids                         = each.value.tag_ids
}

###########################
# Workspace Configurations
###########################

resource "scalr_workspace" "this" {
  for_each                    = local.workspaces
  agent_pool_id               = each.value.agent_pool_id
  auto_apply                  = each.value.auto_apply
  auto_queue_runs             = each.value.auto_queue_runs
  deletion_protection_enabled = each.value.deletion_protection_enabled
  environment_id              = each.value.environment_id
  execution_mode              = each.value.execution_mode
  force_latest_run            = each.value.force_latest_run
  iac_platform                = each.value.iac_platform
  module_version_id           = each.value.module_version_id
  name                        = each.value.name
  operations                  = each.value.operations
  remote_state_consumers      = each.value.remote_state_consumers
  run_operation_timeout       = each.value.run_operation_timeout
  ssh_key_id                  = each.value.ssh_key_id
  tag_ids                     = each.value.tag_ids
  terraform_version           = each.value.terraform_version
  type                        = each.value.type
  var_files                   = each.value.var_files
  working_directory           = each.value.working_directory

  dynamic "provider_configuration" {
    for_each = each.value.provider_configuration != null ? toset(each.value.provider_configuration) : []
    content {
      id = provider_configuration.value
    }
  }

  dynamic "vcs_repo" {
    for_each = each.value.vcs_repo != null ? toset(each.value.vcs_repo) : []
    content {
      branch             = vcs_repo.value.branch
      dry_runs_enabled   = vcs_repo.value.dry_runs_enabled
      identifier         = vcs_repo.value.identifier
      ingress_submodules = vcs_repo.value.ingress_submodules
      path               = vcs_repo.value.path
      trigger_patterns   = vcs_repo.value.trigger_patterns
      trigger_prefixes   = vcs_repo.value.trigger_prefixes
      version_constraint = vcs_repo.value.version_constraint
    }
  }
}
