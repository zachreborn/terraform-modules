<a name="readme-top"></a>

## scalr/workspace

Manages [`scalr_workspace`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/workspace) resources with full argument coverage, including VCS-driven, module-driven, and CLI-driven workspaces, custom hooks, multiple provider configurations, and Terragrunt settings.

This submodule implements the `scalr_workspace` resource for the `modules/scalr` root module, which composes it (alongside the `environment`, `vcs_provider`, and `provider_configuration` submodules) to manage workspaces from its YAML interface. You can also call it directly when you need a dedicated, scalable `map(object({...}))` interface for workspaces, or full argument coverage (e.g. `terragrunt`, `operations`, `hooks`), outside the root module.

### Prerequisites

- The referenced `environment_id` must already exist (e.g. via `scalr_environment` or the `modules/scalr` root module).
- For VCS-driven workspaces, a `vcs_provider_id` must already exist and the referenced repository must be accessible to it.
- For module-driven workspaces, the referenced `module_version_id` must already exist. `module_version_id` conflicts with `vcs_provider_id`/`vcs_repo`.

### Usage

```hcl
module "workspace" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/workspace"

  workspaces = {
    app_prod = {
      environment_id  = "env-xxxxxxxxxx"
      vcs_provider_id = "vcs-xxxxxxxxxx"

      working_directory = "environments/prod"

      vcs_repo = {
        identifier       = "my-org/my-repo"
        branch           = "main"
        trigger_prefixes = ["environments/prod", "modules/app"]
      }

      provider_configuration = [
        { id = "pcfg-xxxxxxxxxx", alias = "us_east1" },
      ]

      tag_ids = ["tag-xxxxxxxxxx"]
    }

    app_cli_driven = {
      environment_id     = "env-xxxxxxxxxx"
      working_directory  = "environments/sandbox"
      auto_apply         = true
      execution_mode     = "remote"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Notes / Design Decisions

- `workspaces` is a `map(object({...}))` so callers can manage any number of workspaces with a single module call (per [AGENTS.md §5](../../../AGENTS.md)). Each entry's `name` defaults to the entry's map key via `coalesce(each.value.name, each.key)`, matching the pattern used by the sibling `modules/scalr/provider_configuration` and `modules/scalr/var_set` submodules.
- `provider_configuration` is a list, not a single object, because the upstream provider models it as a Block Set: multiple provider configurations -- including two sharing an `alias`, for plan/apply-only use -- are explicitly supported by Scalr.
- `hooks`, `terragrunt`, and `vcs_repo` are each modeled as a single optional nested object and rendered via a `dynamic` block guarded on `!= null`, so omitting them entirely omits the corresponding block from the plan.
- `operations` is included for complete resource coverage even though the upstream provider marks it deprecated in favor of `execution_mode`. It defaults to `null` (unset) so the provider's own default applies unless a caller explicitly overrides it.
- `vcs_repo.trigger_patterns` is a single gitignore-style string (not a list), matching the upstream provider's schema. Use `trigger_prefixes` instead for a list-of-paths trigger strategy; the two are mutually exclusive upstream.
- This module accepts `environment_id` per-entry rather than resolving it internally, so `tofu test` can run fully offline with `mock_provider`.

<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.17.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_workspace.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_workspaces"></a> [workspaces](#input\_workspaces) | Map of Scalr Workspaces (scalr\_workspace) to create, keyed by a caller-chosen logical name.<br/>Fields:<br/>  - name:                         (Optional) Name of the workspace. Defaults to the entry's map key.<br/>  - environment\_id:               (Required) ID of the environment, in the format "env-<RANDOM STRING>".<br/>  - agent\_pool\_id:                (Optional) The identifier of an agent pool, in the format "apool-<RANDOM STRING>".<br/>  - auto\_apply:                   (Optional) Whether "apply" runs automatically when "plan" ends without error. Default false.<br/>  - auto\_queue\_runs:              (Optional) One of "skip\_first", "always", "never", "on\_create\_only". Default "always".<br/>  - deletion\_protection\_enabled:  (Optional) Whether the workspace is protected from accidental state loss. Default true.<br/>  - execution\_mode:               (Optional) One of "remote", "local". Default "remote".<br/>  - force\_latest\_run:             (Optional) Whether the latest new run is automatically raised in priority. Default false.<br/>  - iac\_platform:                 (Optional) One of "terraform", "opentofu". Default "opentofu".<br/>  - module\_version\_id:            (Optional) ID of a module version, in the format "modver-<RANDOM STRING>". Conflicts with<br/>                                  vcs\_provider\_id/vcs\_repo.<br/>  - operations:                   (Optional, Deprecated by the upstream provider) Whether the workspace performs remote<br/>                                  execution. When false the workspace only stores state. Defaults to true upstream.<br/>  - remote\_backend:               (Optional) Whether Scalr manages the remote backend configuration and state storage.<br/>                                  Default true.<br/>  - remote\_state\_consumers:       (Optional) Set of workspace IDs allowed to read this workspace's state. Use ["*"] to<br/>                                  share the state with all workspaces in the environment.<br/>  - run\_operation\_timeout:        (Optional) Maximum number of minutes a run operation (plan or apply) may take before<br/>                                  being automatically canceled.<br/>  - ssh\_key\_id:                   (Optional) ID of the SSH key to use for the workspace.<br/>  - tag\_ids:                      (Optional) Set of tag IDs associated with the workspace.<br/>  - terraform\_version:            (Optional) The OpenTofu/Terraform version to use. Defaults to the latest available.<br/>  - type:                         (Optional) One of "production", "staging", "testing", "development", "unmapped".<br/>                                  Default "production".<br/>  - var\_files:                    (Optional) List of paths to the ".tfvars" file(s) for the workspace.<br/>  - vcs\_provider\_id:              (Optional) ID of the VCS provider. Required if vcs\_repo is set, and vice versa.<br/>  - working\_directory:            (Optional) Relative path OpenTofu/Terraform will run in. Defaults to the repository<br/>                                  root.<br/>  - hooks:                        (Optional) Custom hook commands. See below.<br/>  - provider\_configuration:       (Optional) List of provider configurations used in workspace runs. See below.<br/>  - terragrunt:                   (Optional) Terragrunt settings. See below.<br/>  - vcs\_repo:                     (Optional) VCS repository settings. See below.<br/><br/>hooks fields (all optional strings, one command each):<br/>  - post\_apply: Action called after the apply phase.<br/>  - post\_plan:  Action called after the plan phase.<br/>  - pre\_apply:  Action called before the apply phase.<br/>  - pre\_init:   Action called before the init phase.<br/>  - pre\_plan:   Action called before the plan phase.<br/><br/>provider\_configuration is a list because the upstream provider models it as a Block Set (multiple<br/>configurations -- including two sharing an alias, for plan/apply-only use -- are explicitly supported):<br/>  - id:    (Required) The identifier of the provider configuration.<br/>  - alias: (Optional) The alias of the provider configuration.<br/><br/>terragrunt fields:<br/>  - version:                        (Required) The Terragrunt version the workspace performs runs on.<br/>  - include\_external\_dependencies:  (Optional) Whether the workspace includes external dependencies.<br/>  - use\_run\_all:                    (Optional) Whether the workspace uses "terragrunt run-all".<br/><br/>vcs\_repo fields:<br/>  - identifier:          (Required) Reference to the VCS repository, in the format ":org/:repo".<br/>  - branch:              (Optional) Repository branch to run from. Conflicts with version\_constraint.<br/>  - dry\_runs\_enabled:    (Optional) Whether VCS-driven dry runs occur when a pull request is opened against the<br/>                         configuration versions branch. Default true.<br/>  - ingress\_submodules:  (Optional) Whether to clone git submodules of the VCS repository. Default false.<br/>  - path:                (Optional, Deprecated by the upstream provider) Repository subdirectory to run from.<br/>  - trigger\_patterns:    (Optional) A single gitignore-style pattern string for files whose changes trigger a run.<br/>                         Conflicts with trigger\_prefixes.<br/>  - trigger\_prefixes:    (Optional) List of paths whose changes trigger a run. Conflicts with trigger\_patterns.<br/>  - version\_constraint:  (Optional) Terraform-like version constraint used to trigger a run for matching Git tags.<br/>                         Conflicts with branch. | <pre>map(object({<br/>    name                        = optional(string)<br/>    environment_id              = string<br/>    agent_pool_id               = optional(string)<br/>    auto_apply                  = optional(bool, false)<br/>    auto_queue_runs             = optional(string, "always")<br/>    deletion_protection_enabled = optional(bool, true)<br/>    execution_mode              = optional(string, "remote")<br/>    force_latest_run            = optional(bool, false)<br/>    iac_platform                = optional(string, "opentofu")<br/>    module_version_id           = optional(string)<br/>    operations                  = optional(bool)<br/>    remote_backend              = optional(bool, true)<br/>    remote_state_consumers      = optional(set(string))<br/>    run_operation_timeout       = optional(number)<br/>    ssh_key_id                  = optional(string)<br/>    tag_ids                     = optional(set(string))<br/>    terraform_version           = optional(string)<br/>    type                        = optional(string, "production")<br/>    var_files                   = optional(list(string))<br/>    vcs_provider_id             = optional(string)<br/>    working_directory           = optional(string)<br/><br/>    hooks = optional(object({<br/>      post_apply = optional(string)<br/>      post_plan  = optional(string)<br/>      pre_apply  = optional(string)<br/>      pre_init   = optional(string)<br/>      pre_plan   = optional(string)<br/>    }))<br/><br/>    provider_configuration = optional(list(object({<br/>      id    = string<br/>      alias = optional(string)<br/>    })), [])<br/><br/>    terragrunt = optional(object({<br/>      version                       = string<br/>      include_external_dependencies = optional(bool)<br/>      use_run_all                   = optional(bool)<br/>    }))<br/><br/>    vcs_repo = optional(object({<br/>      identifier         = string<br/>      branch             = optional(string)<br/>      dry_runs_enabled   = optional(bool, true)<br/>      ingress_submodules = optional(bool, false)<br/>      path               = optional(string)<br/>      trigger_patterns   = optional(string)<br/>      trigger_prefixes   = optional(list(string))<br/>      version_constraint = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_created_by"></a> [created\_by](#output\_created\_by) | Map of details about the user that created each workspace, keyed by the same keys as var.workspaces. |
| <a name="output_has_resources"></a> [has\_resources](#output\_has\_resources) | Map of whether each workspace currently has active resources in its state version, keyed by the same keys as var.workspaces. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Workspace IDs, keyed by the same keys as var.workspaces. |
<!-- END_TF_DOCS -->
