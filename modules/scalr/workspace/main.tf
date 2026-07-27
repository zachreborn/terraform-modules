###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

###########################
# Scalr Workspace
###########################
resource "scalr_workspace" "this" {
  for_each = var.workspaces

  name                        = coalesce(each.value.name, each.key)
  environment_id              = each.value.environment_id
  agent_pool_id               = each.value.agent_pool_id
  auto_apply                  = each.value.auto_apply
  auto_queue_runs             = each.value.auto_queue_runs
  deletion_protection_enabled = each.value.deletion_protection_enabled
  execution_mode              = each.value.execution_mode
  force_latest_run            = each.value.force_latest_run
  iac_platform                = each.value.iac_platform
  module_version_id           = each.value.module_version_id
  operations                  = each.value.operations
  remote_backend              = each.value.remote_backend
  remote_state_consumers      = each.value.remote_state_consumers
  run_operation_timeout       = each.value.run_operation_timeout
  ssh_key_id                  = each.value.ssh_key_id
  tag_ids                     = each.value.tag_ids
  terraform_version           = each.value.terraform_version
  type                        = each.value.type
  var_files                   = each.value.var_files
  vcs_provider_id             = each.value.vcs_provider_id
  working_directory           = each.value.working_directory

  dynamic "hooks" {
    for_each = each.value.hooks != null ? [each.value.hooks] : []
    content {
      post_apply = hooks.value.post_apply
      post_plan  = hooks.value.post_plan
      pre_apply  = hooks.value.pre_apply
      pre_init   = hooks.value.pre_init
      pre_plan   = hooks.value.pre_plan
    }
  }

  # scalr_workspace.provider_configuration is a Block Set in the provider schema (multiple
  # configurations, including two sharing an alias for plan/apply-only use, are explicitly
  # supported) -- so this always iterates the list directly, never a single wrapped object.
  dynamic "provider_configuration" {
    for_each = each.value.provider_configuration
    content {
      id    = provider_configuration.value.id
      alias = provider_configuration.value.alias
    }
  }

  dynamic "terragrunt" {
    for_each = each.value.terragrunt != null ? [each.value.terragrunt] : []
    content {
      version                       = terragrunt.value.version
      include_external_dependencies = terragrunt.value.include_external_dependencies
      use_run_all                   = terragrunt.value.use_run_all
    }
  }

  dynamic "vcs_repo" {
    for_each = each.value.vcs_repo != null ? [each.value.vcs_repo] : []
    content {
      identifier         = vcs_repo.value.identifier
      branch             = vcs_repo.value.branch
      dry_runs_enabled   = vcs_repo.value.dry_runs_enabled
      ingress_submodules = vcs_repo.value.ingress_submodules
      path               = vcs_repo.value.path
      trigger_patterns   = vcs_repo.value.trigger_patterns
      trigger_prefixes   = vcs_repo.value.trigger_prefixes
      version_constraint = vcs_repo.value.version_constraint
    }
  }
}
