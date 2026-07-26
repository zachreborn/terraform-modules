<a name="readme-top"></a>

# scalr/iam/team

Manages [`scalr_iam_team`](https://github.com/Scalr/terraform-provider-scalr/blob/master/docs/resources/iam_team.md) resources -- Scalr IAM teams used to group users for access-policy assignment.

## Prerequisites

- A Scalr account and an authenticated `scalr` provider (see the [Scalr Terraform Provider docs](https://docs.scalr.io/terraform-provider)).
- If assigning `users`, the referenced user IDs (format `user-`) must already exist and the account's identity provider must be of type `scalr` -- otherwise team membership is managed externally and this attribute should be left unset.

## Usage

```hcl
module "teams" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/iam/team"

  teams = {
    dev = {
      name        = "dev"
      description = "Developers"
      users       = ["user-xxxxxxxxxx", "user-yyyyyyyyyy"]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `teams` is a `map(object({...}))` so callers can manage many teams via a single module call. Each entry's map key is used as the resource's `name` when the entry does not set an explicit `name`.
- `identity_provider_id` is deprecated upstream by the Scalr provider. It is still exposed here for full attribute coverage per AGENTS.md §1, but new configurations should generally leave it unset.
- `account_id` is exposed both as a per-entry override and as a module-wide `account_id` variable default (`each.value.account_id != null ? each.value.account_id : var.account_id`).
- This submodule accepts `account_id` as a plain input variable rather than calling `data.scalr_current_account` internally, so `tofu test` can run fully offline via `mock_provider`.

<!-- terraform-docs output will be input automatically below-->
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
| scalr_iam_team.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Optional) Default ID of the account, in the format 'acc-', used for any teams entry that does not set its own account\_id. | `string` | `null` | no |
| <a name="input_teams"></a> [teams](#input\_teams) | (Optional) Map of Scalr IAM teams to create, keyed by a caller-chosen logical name (e.g. "dev").<br/>Each entry:<br/>  - name:                  (Optional) A name of the team. Defaults to the entry's map key when<br/>                            unset.<br/>  - description:           (Optional) A verbose description of the team.<br/>  - users:                 (Optional) Set of user identifiers (format 'user-') to add to the<br/>                            team. Should not be used when the account's identity provider is not<br/>                            of type 'scalr', since team membership is then managed externally.<br/>  - account\_id:            (Optional) ID of the account, in the format 'acc-'. Falls back to<br/>                            var.account\_id when unset.<br/>  - identity\_provider\_id:  (Optional, DEPRECATED upstream) An identifier of the login identity<br/>                            provider, in the format 'idp-'. Kept here for full attribute coverage<br/>                            per AGENTS.md, but the Scalr provider deprecates this attribute --<br/>                            new configurations should generally leave it unset. | <pre>map(object({<br/>    name                 = optional(string)<br/>    description          = optional(string)<br/>    users                = optional(set(string))<br/>    account_id           = optional(string)<br/>    identity_provider_id = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr IAM Team IDs, keyed by the same keys as var.teams. |
<!-- END_TF_DOCS -->
