<a name="readme-top"></a>

# scalr/iam/role

Manages [`scalr_role`](https://github.com/Scalr/terraform-provider-scalr/blob/master/docs/resources/role.md) resources -- custom Scalr IAM roles that bundle a set of permissions for use with `scalr_access_policy`.

## Prerequisites

- A Scalr account and an authenticated `scalr` provider (see the [Scalr Terraform Provider docs](https://docs.scalr.io/terraform-provider)).
- No other modules in this repository must be provisioned first; roles have no dependency on tags, environments, or workspaces.

## Usage

```hcl
module "roles" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/iam/role"

  roles = {
    writer = {
      name        = "Writer"
      description = "Write access to all resources."
      permissions = [
        "*:create",
        "*:update",
        "*:delete",
      ]
    }
    reader = {
      permissions = ["*:read"]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `roles` is a `map(object({...}))` so callers can manage many roles via a single module call (per AGENTS.md's scalable-inputs guidance). Each entry's map key is used as the resource's `name` when the entry does not set an explicit `name`.
- `account_id` is exposed both as a per-entry override and as a module-wide `account_id` variable default (`each.value.account_id != null ? each.value.account_id : var.account_id`). The Scalr provider marks `account_id` as deprecated on this resource; new configurations should generally leave it unset and let the provider resolve the account from the caller's credentials.
- `permissions` is typed as `set(string)` to mirror the provider's "Set of String" attribute exactly.
- This submodule accepts `account_id` as a plain input variable rather than calling `data.scalr_current_account` internally, so `tofu test` can run fully offline via `mock_provider`.

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
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
| scalr_role.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Optional) Default ID of the account, in the format 'acc-', used for any roles entry that does<br/>not set its own account\_id. This attribute is deprecated upstream by the Scalr provider -- new<br/>configurations should generally leave both this and each entry's account\_id unset so the<br/>provider resolves the account from the caller's credentials. | `string` | `null` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | (Optional) Map of Scalr IAM roles to create, keyed by a caller-chosen logical name (e.g.<br/>"writer"). Each entry:<br/>  - name:        (Optional) Name of the role. Defaults to the entry's map key when unset.<br/>  - permissions: (Required) Set of permission names to grant (e.g. "*:update", "*:delete",<br/>                 "*:create"). Must be non-empty.<br/>  - account\_id:  (Optional) ID of the account, in the format 'acc-'. Deprecated upstream by the<br/>                 Scalr provider -- kept here for full attribute coverage per AGENTS.md, but new<br/>                 configurations should rely on the provider's default account resolution and<br/>                 leave this unset (falls back to var.account\_id).<br/>  - description: (Optional) Verbose description of the role. | <pre>map(object({<br/>    name        = optional(string)<br/>    permissions = set(string)<br/>    account_id  = optional(string)<br/>    description = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Role IDs, keyed by the same keys as var.roles. |
| <a name="output_is_system"></a> [is\_system](#output\_is\_system) | Map of booleans indicating whether each role is a built-in system role maintained by Scalr (and therefore cannot be edited), keyed by the same keys as var.roles. |
<!-- END_TF_DOCS -->
