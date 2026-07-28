###########################
# Provider Configuration
###########################
terraform {
  # >= 1.9.0 is required because this root composes the ./provider_configuration submodule, whose
  # variable validation references another variable (cross-variable validation), a feature added
  # in the OpenTofu/Terraform 1.9.0 releases.
  required_version = ">= 1.9.0"
  required_providers {
    scalr = {
      source = "registry.scalr.io/scalr/scalr"
      # >= 3.17.0 is required by the google provider_configuration's default_labels block.
      version = ">= 3.17.0"
    }
  }
}

###########################
# Data Sources
###########################
data "scalr_current_account" "account" {
  lifecycle {
    # Provider-configuration names must be unique across the four provider-type YAML files: they are
    # merged into a single map (local.provider_configurations) that shares one ID namespace. merge()
    # would otherwise silently drop a duplicate (last file wins), changing that name's provider type
    # and making the per-type *_ids outputs point at the wrong configuration. Fail loudly instead --
    # any collision makes the merged map smaller than the sum of the four parts.
    # Computed from the raw decoded YAML maps (not the pc_* locals, which carry account_id from this
    # very data source -- referencing those here would create a dependency cycle). If any name is
    # shared across files, the merged map is smaller than the sum of the four key sets.
    precondition {
      condition = (
        length(keys(local.aws_provider_config)) + length(keys(local.azurerm_provider_config)) + length(keys(local.google_provider_config)) + length(keys(local.custom_provider_config))
        == length(merge(local.aws_provider_config, local.azurerm_provider_config, local.google_provider_config, local.custom_provider_config))
      )
      error_message = "Provider-configuration names must be unique across aws_provider_config, azurerm_provider_config, google_provider_config, and custom_provider_config. A name is defined in more than one of these files."
    }
  }
}

###########################
# Locals
###########################
locals {
  account_id = data.scalr_current_account.account.id

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

  # Merged name -> ID lookup across every provider configuration created by the composed
  # ./provider_configuration submodule, so a workspace's provider_configuration.name can reference
  # an AWS, AzureRM, Google, or custom configuration by its YAML key.
  provider_configuration_ids = module.provider_configuration.ids

  ###########################
  # ./provider_configuration inputs
  ###########################
  # Each of the four provider-type YAML maps is transformed into the unified provider_configurations
  # shape the ./provider_configuration submodule expects. Module-wide default variables (e.g.
  # var.aws_role_arn) still fill in any field an individual YAML entry omits, preserving the root
  # module's historical behavior. Exactly one provider block is set per entry; the others are null.
  # NOTE: provider-configuration names must be unique across all four YAML files, since they share
  # a single ID namespace (local.provider_configuration_ids) once merged.
  pc_aws = {
    for name, cfg in local.aws_provider_config : name => {
      account_id             = local.account_id
      apply_only             = try(cfg.apply_only, false)
      environments           = try(cfg.environments, var.aws_environments)
      export_shell_variables = try(cfg.export_shell_variables, var.aws_export_shell_variables)
      owners                 = try(cfg.owners, var.aws_owners)
      tag_ids                = try(cfg.tag_ids, null)
      aws = {
        credentials_type    = try(cfg.credentials_type, var.aws_credentials_type)
        access_key          = try(cfg.access_key, var.aws_access_key)
        account_type        = try(cfg.account_type, var.aws_account_type)
        audience            = try(cfg.audience, var.aws_audience)
        credentials_source  = try(cfg.credentials_source, null)
        external_id         = try(cfg.external_id, var.aws_external_id)
        role_arn            = try(cfg.role_arn, var.aws_role_arn)
        trusted_entity_type = try(cfg.trusted_entity_type, var.aws_trusted_entity_type)
        default_tags        = try(cfg.default_tags, null)
      }
      azurerm = null
      google  = null
      scalr   = null
      custom  = null
    }
  }

  pc_azurerm = {
    for name, cfg in local.azurerm_provider_config : name => {
      account_id             = local.account_id
      apply_only             = false
      environments           = try(cfg.environments, var.azurerm_environments)
      export_shell_variables = try(cfg.export_shell_variables, var.azurerm_export_shell_variables)
      owners                 = try(cfg.owners, var.azurerm_owners)
      tag_ids                = try(cfg.tag_ids, var.azurerm_tag_ids)
      aws                    = null
      azurerm = {
        client_id       = try(cfg.client_id, var.azurerm_client_id)
        tenant_id       = try(cfg.tenant_id, var.azurerm_tenant_id)
        audience        = try(cfg.audience, var.azurerm_audience)
        auth_type       = try(cfg.auth_type, var.azurerm_auth_type)
        subscription_id = try(cfg.subscription_id, var.azurerm_subscription_id)
      }
      google = null
      scalr  = null
      custom = null
    }
  }

  pc_google = {
    for name, cfg in local.google_provider_config : name => {
      account_id             = local.account_id
      apply_only             = false
      environments           = try(cfg.environments, var.google_environments)
      export_shell_variables = try(cfg.export_shell_variables, var.google_export_shell_variables)
      owners                 = try(cfg.owners, var.google_owners)
      tag_ids                = try(cfg.tag_ids, var.google_tag_ids)
      aws                    = null
      azurerm                = null
      google = {
        auth_type              = try(cfg.auth_type, var.google_auth_type)
        project                = try(cfg.project, var.google_project)
        service_account_email  = try(cfg.service_account_email, var.google_service_account_email)
        use_default_project    = try(cfg.use_default_project, var.google_use_default_project)
        workload_provider_name = try(cfg.workload_provider_name, var.google_workload_provider_name)
        default_labels = (try(cfg.default_labels, null) != null || var.google_default_labels_labels != null || var.google_default_labels_strategy != null) ? {
          labels   = try(cfg.default_labels.labels, var.google_default_labels_labels)
          strategy = try(cfg.default_labels.strategy, var.google_default_labels_strategy)
        } : null
      }
      scalr  = null
      custom = null
    }
  }

  pc_custom = {
    for name, cfg in local.custom_provider_config : name => {
      account_id             = local.account_id
      apply_only             = false
      environments           = try(cfg.environments, var.custom_environments)
      export_shell_variables = try(cfg.export_shell_variables, var.custom_export_shell_variables)
      owners                 = try(cfg.owners, var.custom_owners)
      tag_ids                = try(cfg.tag_ids, var.custom_tag_ids)
      aws                    = null
      azurerm                = null
      google                 = null
      scalr                  = null
      custom = {
        provider_name = try(cfg.provider_name, var.custom_provider_name)
        arguments = [
          for arg in try(cfg.argument, var.custom_argument) : {
            name        = arg.name
            value       = try(arg.sensitive, false) ? null : try(arg.value, null)
            description = try(arg.description, null)
            hcl         = try(arg.hcl, false)
            sensitive   = try(arg.sensitive, false)
          }
        ]
      }
    }
  }

  provider_configurations = merge(local.pc_aws, local.pc_azurerm, local.pc_google, local.pc_custom)

  # Sensitive credential leaves are routed to the submodule's separate, always-sensitive
  # provider_configuration_secrets map (keyed by the same YAML key) so the non-sensitive
  # provider_configurations map above can remain a valid for_each source in the submodule.
  provider_configuration_secrets = merge(
    { for name, cfg in local.aws_provider_config : name => {
      aws_secret_key         = try(cfg.secret_key, var.aws_secret_key)
      azurerm_client_secret  = null
      google_credentials     = null
      scalr_token            = null
      custom_argument_values = {}
    } },
    { for name, cfg in local.azurerm_provider_config : name => {
      aws_secret_key         = null
      azurerm_client_secret  = try(cfg.client_secret, var.azurerm_client_secret)
      google_credentials     = null
      scalr_token            = null
      custom_argument_values = {}
    } },
    { for name, cfg in local.google_provider_config : name => {
      aws_secret_key         = null
      azurerm_client_secret  = null
      google_credentials     = try(cfg.credentials, var.google_credentials)
      scalr_token            = null
      custom_argument_values = {}
    } },
    { for name, cfg in local.custom_provider_config : name => {
      aws_secret_key         = null
      azurerm_client_secret  = null
      google_credentials     = null
      scalr_token            = null
      custom_argument_values = try(var.custom_argument_secrets[name], {})
    } },
  )

  ###########################
  # ./environment inputs
  ###########################
  environment_inputs = {
    for environment, cfg in local.yaml_config : environment => {
      default_provider_configurations = try(cfg.default_provider_configurations, var.environment_default_provider_configurations)
      default_workspace_agent_pool_id = try(cfg.default_workspace_agent_pool_id, var.environment_default_workspace_agent_pool_id)
      federated_environments          = try(cfg.federated_environments, var.environment_federated_environments)
      mask_sensitive_output           = try(cfg.mask_sensitive_output, var.environment_mask_sensitive_output)
      remote_backend                  = try(cfg.remote_backend, var.environment_remote_backend)
      remote_backend_overridable      = try(cfg.remote_backend_overridable, var.environment_remote_backend_overridable)
      storage_profile_id              = try(cfg.storage_profile_id, var.environment_storage_profile_id)
      tag_ids                         = try(cfg.tag_ids, var.environment_tag_ids)
    }
  }

  ###########################
  # ./vcs_provider inputs
  ###########################
  vcs_provider_inputs = {
    for name, cfg in(local.vcs_provider_config != null ? local.vcs_provider_config : {}) : name => {
      agent_pool_id             = try(cfg.agent_pool_id, var.vcs_provider_agent_pool_id)
      comments_enabled          = try(cfg.comments_enabled, null)
      draft_pr_runs_enabled     = try(cfg.draft_pr_runs_enabled, var.vcs_provider_draft_pr_runs_enabled)
      environments              = try(cfg.environments, var.vcs_provider_environments)
      pr_merge_comments_enabled = try(cfg.pr_merge_comments_enabled, null)
      url                       = try(cfg.url, var.vcs_provider_url)
      username                  = try(cfg.username, var.vcs_provider_username)
      vcs_type                  = try(cfg.vcs_type, var.vcs_provider_vcs_type)
    }
  }

  vcs_provider_tokens = {
    for name, cfg in(local.vcs_provider_config != null ? local.vcs_provider_config : {}) : name => try(cfg.token, var.vcs_provider_token)
  }

  ###########################
  # ./workspace inputs
  ###########################
  workspace_inputs = {
    for key, ws in local.workspaces : key => {
      name                        = ws.workspace
      environment_id              = module.environment.ids[ws.environment]
      agent_pool_id               = try(ws.agent_pool_id, var.workspace_agent_pool_id)
      auto_apply                  = try(ws.auto_apply, var.workspace_auto_apply)
      auto_queue_runs             = try(ws.auto_queue_runs, var.workspace_auto_queue_runs)
      deletion_protection_enabled = try(ws.deletion_protection_enabled, var.workspace_deletion_protection_enabled)
      execution_mode              = try(ws.execution_mode, var.workspace_execution_mode)
      force_latest_run            = try(ws.force_latest_run, var.workspace_force_latest_run)
      iac_platform                = try(ws.iac_platform, var.workspace_iac_platform)
      module_version_id           = try(ws.module_version_id, var.workspace_module_version_id)
      operations                  = try(ws.operations, null)
      remote_backend              = try(ws.remote_backend, var.workspace_remote_backend)
      remote_state_consumers      = try(ws.remote_state_consumers, var.workspace_remote_state_consumers)
      run_operation_timeout       = try(ws.run_operation_timeout, var.workspace_run_operation_timeout)
      ssh_key_id                  = try(ws.ssh_key_id, var.workspace_ssh_key_id)
      tag_ids                     = try(ws.tag_ids, var.workspace_tag_ids)
      terraform_version           = try(ws.terraform_version, var.workspace_terraform_version)
      type                        = try(ws.type, var.workspace_type)
      var_files                   = try(ws.var_files, var.workspace_var_files)
      vcs_provider_id             = try(ws.vcs_provider_id, var.vcs_provider_id)
      working_directory           = try(ws.working_directory, var.workspace_working_directory)

      hooks = try(ws.hooks, null) != null ? {
        post_apply = try(ws.hooks.post_apply, null)
        post_plan  = try(ws.hooks.post_plan, null)
        pre_apply  = try(ws.hooks.pre_apply, null)
        pre_init   = try(ws.hooks.pre_init, null)
        pre_plan   = try(ws.hooks.pre_plan, null)
      } : null

      # scalr_workspace.provider_configuration is a Block Set; resolve each entry's YAML name to
      # the ID of a configuration created by the composed ./provider_configuration submodule.
      provider_configuration = [
        for pc in try(ws.provider_configuration, []) : {
          id    = local.provider_configuration_ids[pc.name]
          alias = try(pc.alias, null)
        }
      ]

      terragrunt = try(ws.terragrunt, null) != null ? {
        version                       = ws.terragrunt.version
        include_external_dependencies = try(ws.terragrunt.include_external_dependencies, null)
        use_run_all                   = try(ws.terragrunt.use_run_all, null)
      } : null

      vcs_repo = try(ws.vcs_repo, null) != null ? {
        identifier         = ws.vcs_repo.identifier
        branch             = try(ws.vcs_repo.branch, null)
        dry_runs_enabled   = try(ws.vcs_repo.dry_runs_enabled, true)
        ingress_submodules = try(ws.vcs_repo.ingress_submodules, false)
        path               = try(ws.vcs_repo.path, null)
        trigger_patterns   = try(ws.vcs_repo.trigger_patterns, null)
        trigger_prefixes   = try(ws.vcs_repo.trigger_prefixes, null)
        version_constraint = try(ws.vcs_repo.version_constraint, null)
      } : null
    }
  }
}

###########################
# Provider Configurations (./provider_configuration)
###########################
module "provider_configuration" {
  source = "./provider_configuration"

  provider_configurations        = local.provider_configurations
  provider_configuration_secrets = local.provider_configuration_secrets
}

###########################
# VCS Providers (./vcs_provider)
###########################
module "vcs_provider" {
  source = "./vcs_provider"

  account_id          = local.account_id
  vcs_providers       = local.vcs_provider_inputs
  vcs_provider_tokens = local.vcs_provider_tokens
}

###########################
# Environments (./environment)
###########################
module "environment" {
  source = "./environment"

  account_id   = local.account_id
  environments = local.environment_inputs
}

###########################
# Workspaces (./workspace)
###########################
module "workspace" {
  source = "./workspace"

  workspaces = local.workspace_inputs
}
