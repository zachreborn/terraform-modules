<a name="readme-top"></a>

## scalr/environment

Manages [`scalr_environment`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/environment) resources with full argument coverage.

### Prerequisites

- An existing Scalr account (`account_id`, in the format `acc-<RANDOM STRING>`), either supplied per-entry or as the module-wide `account_id` fallback.
- Any referenced `default_provider_configurations`, `default_workspace_agent_pool_id`, `storage_profile_id`, or `tag_ids` values must already exist.

### Usage

```hcl
module "environment" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/environment"

  account_id = "acc-xxxxxxxxxx" # Used as a fallback for any entry that omits account_id.

  environments = {
    production = {
      default_provider_configurations = ["pcfg-xxxxxxxxxx", "pcfg-yyyyyyyyyy"]
      tag_ids                         = ["tag-xxxxxxxxxx"]
    }

    staging = {
      name                       = "staging-env"
      remote_backend_overridable = true
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Notes / Design Decisions

- `environments` is a `map(object({...}))` so callers can manage any number of environments with a single module call (per [AGENTS.md §5](../../../AGENTS.md)). Each entry's `name` defaults to its own map key via `coalesce(each.value.name, each.key)`.
- Each entry's `account_id` falls back to the module-wide `var.account_id` when unset (`each.value.account_id != null ? each.value.account_id : var.account_id`), so a single module call can create environments under one account without repeating `account_id` on every entry, while still allowing per-entry overrides.
- `mask_sensitive_output` defaults to `true` and `remote_backend` defaults to `true`, matching the upstream provider's defaults. `remote_backend_overridable` defaults to `false`. All three can be overridden per entry.
- `federated_environments` is deprecated upstream by the Scalr provider but is still exposed here for full argument coverage and backward compatibility with existing configurations.

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
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | 3.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_environment.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Optional) Default ID of the account, in the format 'acc-', used for any environments entry that does not set its own account\_id. | `string` | `null` | no |
| <a name="input_environments"></a> [environments](#input\_environments) | (Optional) Map of Scalr Environments (scalr\_environment) to create, keyed by a caller-chosen<br/>logical name (e.g. "production"). Each entry:<br/>  - name:                             (Optional) Name of the environment. Defaults to the<br/>                                      entry's map key when unset.<br/>  - account\_id:                       (Optional) ID of the account, in the format 'acc-'.<br/>                                      Falls back to var.account\_id when unset.<br/>  - default\_provider\_configurations:  (Optional) Set of IDs of provider configurations, used<br/>                                      in the environment workspaces by default.<br/>  - default\_workspace\_agent\_pool\_id:  (Optional) Default agent pool that will be set for the<br/>                                      entire environment. It will be used by a workspace if no<br/>                                      other pool is explicitly linked.<br/>  - federated\_environments:           (Optional, Deprecated upstream) Set of environment<br/>                                      identifiers that are allowed to access this environment.<br/>                                      Use ["*"] to share with all environments.<br/>  - mask\_sensitive\_output:            (Optional) Enable masking of the sensitive console<br/>                                      output. Defaults to true.<br/>  - remote\_backend:                   (Optional) If Scalr exports the remote backend<br/>                                      configuration and state storage for your infrastructure<br/>                                      management. Disabling this feature will also prevent the<br/>                                      ability to perform state locking, which ensures that<br/>                                      concurrent operations do not conflict. Additionally, it<br/>                                      will disable the capability to initiate CLI-driven runs<br/>                                      through Scalr. Defaults to true.<br/>  - remote\_backend\_overridable:       (Optional) Indicates if the remote backend configuration<br/>                                      can be overridden on the workspace level. Defaults to<br/>                                      false.<br/>  - storage\_profile\_id:               (Optional) The storage profile for this environment. If<br/>                                      not set, the account's default storage profile will be<br/>                                      used.<br/>  - tag\_ids:                          (Optional) Set of tag IDs associated with the<br/>                                      environment. | <pre>map(object({<br/>    name                            = optional(string)<br/>    account_id                      = optional(string)<br/>    default_provider_configurations = optional(set(string))<br/>    default_workspace_agent_pool_id = optional(string)<br/>    federated_environments          = optional(set(string))<br/>    mask_sensitive_output           = optional(bool, true)<br/>    remote_backend                  = optional(bool, true)<br/>    remote_backend_overridable      = optional(bool, false)<br/>    storage_profile_id              = optional(string)<br/>    tag_ids                         = optional(set(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_created_by"></a> [created\_by](#output\_created\_by) | Map of the details (email, full\_name, username) of the user that created each environment, keyed by the same keys as var.environments. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Environment IDs, keyed by the same keys as var.environments. |
| <a name="output_policy_groups"></a> [policy\_groups](#output\_policy\_groups) | Map of the list of policy-group IDs associated with each environment, keyed by the same keys as var.environments. |
| <a name="output_status"></a> [status](#output\_status) | Map of the status of each environment, keyed by the same keys as var.environments. |
<!-- END_TF_DOCS -->
