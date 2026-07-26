###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    scalr = {
      source = "registry.scalr.io/scalr/scalr"
      # >= 3.17.0 is required by the google provider_configuration's default_labels block below.
      version = ">= 3.17.0"
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
  # Decode each optional provider-config YAML file to an empty map when the variable itself is
  # unset (the null default), without swallowing genuine YAML syntax errors: unlike
  # try(yamldecode(var.x), {}), this only short-circuits on a missing variable, so malformed YAML
  # in a *supplied* file still raises a real decode error at plan time instead of silently
  # planning zero resources.
  aws_provider_config     = var.aws_provider_config == null ? {} : yamldecode(var.aws_provider_config)
  azurerm_provider_config = var.azurerm_provider_config == null ? {} : yamldecode(var.azurerm_provider_config)
  custom_provider_config  = var.custom_provider_config == null ? {} : yamldecode(var.custom_provider_config)
  google_provider_config  = var.google_provider_config == null ? {} : yamldecode(var.google_provider_config)
  vcs_provider_config     = try(yamldecode(var.vcs_provider_config), null)
  yaml_config             = try(yamldecode(var.scalr_config), null)
  workspaces = merge([for environment, value in local.yaml_config : {
    for workspace, workspace_value in value.workspaces : "${environment}.${workspace}" => merge(workspace_value, {
      environment = environment
      workspace   = workspace
    })
  }]...)

  # Merged name -> ID lookup across all four provider_configuration resource types, so a
  # workspace's provider_configuration.name can reference an AzureRM, Google, or custom
  # configuration -- not just AWS.
  provider_configuration_ids = merge(
    { for k, v in scalr_provider_configuration.aws : k => v.id },
    { for k, v in scalr_provider_configuration.azurerm : k => v.id },
    { for k, v in scalr_provider_configuration.google : k => v.id },
    { for k, v in scalr_provider_configuration.custom : k => v.id },
  )
}

###########################
# VCS Provider Configurations
###########################
resource "scalr_vcs_provider" "this" {
  for_each              = local.vcs_provider_config != null ? local.vcs_provider_config : {}
  account_id            = data.scalr_current_account.account.id
  agent_pool_id         = try(each.value.agent_pool_id, var.vcs_provider_agent_pool_id)
  draft_pr_runs_enabled = try(each.value.draft_pr_runs_enabled, var.vcs_provider_draft_pr_runs_enabled)
  environments          = try(each.value.environments, var.vcs_provider_environments)
  name                  = each.key
  token                 = try(each.value.token, var.vcs_provider_token)
  url                   = try(each.value.url, var.vcs_provider_url)
  username              = try(each.value.username, var.vcs_provider_username)
  vcs_type              = try(each.value.vcs_type, var.vcs_provider_vcs_type)
}

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
# AzureRM Provider Configurations
###########################

resource "scalr_provider_configuration" "azurerm" {
  for_each               = local.azurerm_provider_config
  account_id             = data.scalr_current_account.account.id
  environments           = try(each.value.environments, var.azurerm_environments)
  export_shell_variables = try(each.value.export_shell_variables, var.azurerm_export_shell_variables)
  name                   = each.key
  owners                 = try(each.value.owners, var.azurerm_owners)
  tag_ids                = try(each.value.tag_ids, var.azurerm_tag_ids)
  azurerm {
    audience        = try(each.value.audience, var.azurerm_audience)
    auth_type       = try(each.value.auth_type, var.azurerm_auth_type)
    client_id       = try(each.value.client_id, var.azurerm_client_id)
    client_secret   = try(each.value.client_secret, var.azurerm_client_secret)
    subscription_id = try(each.value.subscription_id, var.azurerm_subscription_id)
    tenant_id       = try(each.value.tenant_id, var.azurerm_tenant_id)
  }
}

###########################
# Google Provider Configurations
###########################

resource "scalr_provider_configuration" "google" {
  for_each               = local.google_provider_config
  account_id             = data.scalr_current_account.account.id
  environments           = try(each.value.environments, var.google_environments)
  export_shell_variables = try(each.value.export_shell_variables, var.google_export_shell_variables)
  name                   = each.key
  owners                 = try(each.value.owners, var.google_owners)
  tag_ids                = try(each.value.tag_ids, var.google_tag_ids)
  google {
    auth_type              = try(each.value.auth_type, var.google_auth_type)
    credentials            = try(each.value.credentials, var.google_credentials)
    project                = try(each.value.project, var.google_project)
    service_account_email  = try(each.value.service_account_email, var.google_service_account_email)
    use_default_project    = try(each.value.use_default_project, var.google_use_default_project)
    workload_provider_name = try(each.value.workload_provider_name, var.google_workload_provider_name)

    dynamic "default_labels" {
      for_each = try(each.value.default_labels != null, false) || var.google_default_labels_labels != null || var.google_default_labels_strategy != null ? [1] : []
      content {
        labels   = try(each.value.default_labels.labels, var.google_default_labels_labels)
        strategy = try(each.value.default_labels.strategy, var.google_default_labels_strategy)
      }
    }
  }
}

###########################
# Custom Provider Configurations
###########################

resource "scalr_provider_configuration" "custom" {
  for_each               = local.custom_provider_config
  account_id             = data.scalr_current_account.account.id
  environments           = try(each.value.environments, var.custom_environments)
  export_shell_variables = try(each.value.export_shell_variables, var.custom_export_shell_variables)
  name                   = each.key
  owners                 = try(each.value.owners, var.custom_owners)
  tag_ids                = try(each.value.tag_ids, var.custom_tag_ids)
  custom {
    provider_name = try(each.value.provider_name, var.custom_provider_name)

    dynamic "argument" {
      for_each = try(each.value.argument, var.custom_argument)
      content {
        name        = argument.value.name
        description = try(argument.value.description, null)
        hcl         = try(argument.value.hcl, false)
        sensitive   = try(argument.value.sensitive, false)
        # Sensitive argument values are never read from the non-sensitive argument.value.value
        # (the provider's sensitive flag only controls masking in Scalr, not in Terraform/OpenTofu
        # plan output) -- they must be supplied via var.custom_argument_secrets instead, keyed by
        # this provider configuration's name (each.key) and the argument's own name.
        value = try(argument.value.sensitive, false) ? try(var.custom_argument_secrets[each.key][argument.value.name], null) : try(argument.value.value, null)
      }
    }
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
  vcs_provider_id             = try(each.value.vcs_provider_id, var.vcs_provider_id)
  working_directory           = try(each.value.working_directory, var.workspace_working_directory)

  dynamic "provider_configuration" {
    for_each = try(each.value.provider_configuration != null ? [1] : [], [])
    content {
      id    = local.provider_configuration_ids[each.value.provider_configuration.name]
      alias = try(each.value.provider_configuration.alias, null)
    }
  }

  dynamic "vcs_repo" {
    for_each = try(each.value.vcs_repo, null) != null ? [1] : []
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

  dynamic "hooks" {
    for_each = try(each.value.hooks != null ? [1] : [], [])
    content {
      post_apply = try(each.value.hooks.post_apply, null)
      post_plan  = try(each.value.hooks.post_plan, null)
      pre_apply  = try(each.value.hooks.pre_apply, null)
      pre_init   = try(each.value.hooks.pre_init, null)
      pre_plan   = try(each.value.hooks.pre_plan, null)
    }
  }
}
