###########################
# Scalr Workspace
###########################
variable "workspaces" {
  description = <<-EOT
    Map of Scalr Workspaces (scalr_workspace) to create, keyed by a caller-chosen logical name.
    Fields:
      - name:                         (Optional) Name of the workspace. Defaults to the entry's map key.
      - environment_id:               (Required) ID of the environment, in the format "env-<RANDOM STRING>".
      - agent_pool_id:                (Optional) The identifier of an agent pool, in the format "apool-<RANDOM STRING>".
      - auto_apply:                   (Optional) Whether "apply" runs automatically when "plan" ends without error. Default false.
      - auto_queue_runs:              (Optional) One of "skip_first", "always", "never", "on_create_only". Default "always".
      - deletion_protection_enabled:  (Optional) Whether the workspace is protected from accidental state loss. Default true.
      - execution_mode:               (Optional) One of "remote", "local". Left unset by default so the
                                      upstream provider default (remote) applies and the deprecated
                                      operations field can still select the mode; set explicitly to override.
      - force_latest_run:             (Optional) Whether the latest new run is automatically raised in priority. Default false.
      - iac_platform:                 (Optional) One of "terraform", "opentofu". Default "opentofu".
      - module_version_id:            (Optional) ID of a module version, in the format "modver-<RANDOM STRING>". Conflicts with
                                      vcs_provider_id/vcs_repo.
      - operations:                   (Optional, Deprecated by the upstream provider) Whether the workspace performs remote
                                      execution. When false the workspace only stores state. Defaults to true upstream.
      - remote_backend:               (Optional) Whether Scalr manages the remote backend configuration and state storage.
                                      Default true.
      - remote_state_consumers:       (Optional) Set of workspace IDs allowed to read this workspace's state. Use ["*"] to
                                      share the state with all workspaces in the environment.
      - run_operation_timeout:        (Optional) Maximum number of minutes a run operation (plan or apply) may take before
                                      being automatically canceled.
      - ssh_key_id:                   (Optional) ID of the SSH key to use for the workspace.
      - tag_ids:                      (Optional) Set of tag IDs associated with the workspace.
      - terraform_version:            (Optional) The OpenTofu/Terraform version to use. Defaults to the latest available.
      - type:                         (Optional) One of "production", "staging", "testing", "development", "unmapped".
                                      Default "production".
      - var_files:                    (Optional) List of paths to the ".tfvars" file(s) for the workspace.
      - vcs_provider_id:              (Optional) ID of the VCS provider. Required if vcs_repo is set, and vice versa.
      - working_directory:            (Optional) Relative path OpenTofu/Terraform will run in. Defaults to the repository
                                      root.
      - hooks:                        (Optional) Custom hook commands. See below.
      - provider_configuration:       (Optional) List of provider configurations used in workspace runs. See below.
      - terragrunt:                   (Optional) Terragrunt settings. See below.
      - vcs_repo:                     (Optional) VCS repository settings. See below.

    hooks fields (all optional strings, one command each):
      - post_apply: Action called after the apply phase.
      - post_plan:  Action called after the plan phase.
      - pre_apply:  Action called before the apply phase.
      - pre_init:   Action called before the init phase.
      - pre_plan:   Action called before the plan phase.

    provider_configuration is a list because the upstream provider models it as a Block Set (multiple
    configurations -- including two sharing an alias, for plan/apply-only use -- are explicitly supported):
      - id:    (Required) The identifier of the provider configuration.
      - alias: (Optional) The alias of the provider configuration.

    terragrunt fields:
      - version:                        (Required) The Terragrunt version the workspace performs runs on.
      - include_external_dependencies:  (Optional) Whether the workspace includes external dependencies.
      - use_run_all:                    (Optional) Whether the workspace uses "terragrunt run-all".

    vcs_repo fields:
      - identifier:          (Required) Reference to the VCS repository, in the format ":org/:repo".
      - branch:              (Optional) Repository branch to run from. Conflicts with version_constraint.
      - dry_runs_enabled:    (Optional) Whether VCS-driven dry runs occur when a pull request is opened against the
                             configuration versions branch. Default true.
      - ingress_submodules:  (Optional) Whether to clone git submodules of the VCS repository. Default false.
      - path:                (Optional, Deprecated by the upstream provider) Repository subdirectory to run from.
      - trigger_patterns:    (Optional) A single gitignore-style pattern string for files whose changes trigger a run.
                             Conflicts with trigger_prefixes.
      - trigger_prefixes:    (Optional) List of paths whose changes trigger a run. Conflicts with trigger_patterns.
      - version_constraint:  (Optional) Terraform-like version constraint used to trigger a run for matching Git tags.
                             Conflicts with branch.
  EOT
  type = map(object({
    name                        = optional(string)
    environment_id              = string
    agent_pool_id               = optional(string)
    auto_apply                  = optional(bool, false)
    auto_queue_runs             = optional(string, "always")
    deletion_protection_enabled = optional(bool, true)
    execution_mode              = optional(string)
    force_latest_run            = optional(bool, false)
    iac_platform                = optional(string, "opentofu")
    module_version_id           = optional(string)
    operations                  = optional(bool)
    remote_backend              = optional(bool, true)
    remote_state_consumers      = optional(set(string))
    run_operation_timeout       = optional(number)
    ssh_key_id                  = optional(string)
    tag_ids                     = optional(set(string))
    terraform_version           = optional(string)
    type                        = optional(string, "production")
    var_files                   = optional(list(string))
    vcs_provider_id             = optional(string)
    working_directory           = optional(string)

    hooks = optional(object({
      post_apply = optional(string)
      post_plan  = optional(string)
      pre_apply  = optional(string)
      pre_init   = optional(string)
      pre_plan   = optional(string)
    }))

    provider_configuration = optional(list(object({
      id    = string
      alias = optional(string)
    })), [])

    terragrunt = optional(object({
      version                       = string
      include_external_dependencies = optional(bool)
      use_run_all                   = optional(bool)
    }))

    vcs_repo = optional(object({
      identifier         = string
      branch             = optional(string)
      dry_runs_enabled   = optional(bool, true)
      ingress_submodules = optional(bool, false)
      path               = optional(string)
      trigger_patterns   = optional(string)
      trigger_prefixes   = optional(list(string))
      version_constraint = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.workspaces : contains(["skip_first", "always", "never", "on_create_only"], v.auto_queue_runs)
    ])
    error_message = "Each workspaces entry's auto_queue_runs must be one of \"skip_first\", \"always\", \"never\", or \"on_create_only\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.workspaces : v.execution_mode == null || contains(["remote", "local"], v.execution_mode)
    ])
    error_message = "Each workspaces entry's execution_mode must be null, \"remote\", or \"local\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.workspaces : contains(["terraform", "opentofu"], v.iac_platform)
    ])
    error_message = "Each workspaces entry's iac_platform must be one of \"terraform\" or \"opentofu\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.workspaces : contains(["production", "staging", "testing", "development", "unmapped"], v.type)
    ])
    error_message = "Each workspaces entry's type must be one of \"production\", \"staging\", \"testing\", \"development\", or \"unmapped\"."
  }
}
