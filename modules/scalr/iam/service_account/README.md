<a name="readme-top"></a>

# scalr/iam/service_account

Manages [`scalr_service_account`](https://github.com/Scalr/terraform-provider-scalr/blob/master/docs/resources/service_account.md) resources -- Scalr Service Accounts used for machine-to-machine authentication. Composes two companion submodules:

- `./token` ([`scalr_service_account_token`](https://github.com/Scalr/terraform-provider-scalr/blob/master/docs/resources/service_account_token.md)) -- authentication tokens issued to a service account.
- `./assume_policy` ([`scalr_assume_service_account_policy`](https://github.com/Scalr/terraform-provider-scalr/blob/master/docs/resources/assume_service_account_policy.md)) -- OIDC policies allowing an external workload identity to assume a service account.

Both companion submodules can also be called directly against an existing Service Account (e.g. one not managed by this module).

## Prerequisites

- A Scalr account and an authenticated `scalr` provider (see the [Scalr Terraform Provider docs](https://docs.scalr.io/terraform-provider)).
- `owners` entries (team IDs) referenced by `service_accounts`, if set, must already exist -- provision them with `modules/scalr/iam/team` first.
- `provider_id` values referenced by `assume_policies` must be an existing Workload Identity Provider ID (format `wip-`).

## Usage

```hcl
module "service_accounts" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/iam/service_account"

  service_accounts = {
    ci = {
      description = "CI/CD pipeline"
      status      = "Active"
    }
  }

  tokens = {
    ci_token = {
      service_account_key = "ci"
      description          = "Token used by the CI/CD pipeline"
      expires_in            = 1440
    }
  }

  assume_policies = {
    ga_scalr_staging = {
      service_account_key = "ci"
      provider_id          = "wip-xxxxxxxxxx"
      claim_conditions = [
        {
          claim    = "repository"
          value    = "GithubOrganization/repository"
          operator = "eq"
        }
      ]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- Follows the same parent/companion composition pattern as `modules/aws/organizations` (which composes `account` and `delegated_admin`): this module creates `scalr_service_account` resources directly, then calls `./token` and `./assume_policy` as child modules, wiring `{ for k, v in scalr_service_account.this : k => v.id }` through as their `service_account_ids` input.
- `tokens` and `assume_policies` entries may reference a service account created by this same module call via `service_account_key` (resolved against the internally-wired `service_account_ids`), or reference an existing, externally-managed service account directly via a literal `service_account_id`. Validation of "exactly one of the two" happens inside the child submodules themselves -- see their `variables.tf` and README for the full interface.
- `status` defaults to `"Active"` and is validated against the exact enum the provider documents (`Active`, `Inactive`).
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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_assume_policies"></a> [assume\_policies](#module\_assume\_policies) | ./assume_policy | n/a |
| <a name="module_tokens"></a> [tokens](#module\_tokens) | ./token | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| scalr_service_account.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Optional) Default ID of the account, in the format 'acc-', used for any service\_accounts entry that does not set its own account\_id. | `string` | `null` | no |
| <a name="input_assume_policies"></a> [assume\_policies](#input\_assume\_policies) | (Optional) Map of Scalr Assume Service Account Policies to create, forwarded as-is to the nested<br/>modules/scalr/iam/service\_account/assume\_policy submodule. Each entry must set exactly one of<br/>service\_account\_id (a literal ID) or service\_account\_key (a key into this same module call's<br/>var.service\_accounts). See that submodule's variables.tf for the full field list. | <pre>map(object({<br/>    service_account_id       = optional(string)<br/>    service_account_key      = optional(string)<br/>    name                     = optional(string)<br/>    provider_id              = string<br/>    maximum_session_duration = optional(number)<br/>    claim_conditions = optional(list(object({<br/>      claim    = string<br/>      value    = string<br/>      operator = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_service_accounts"></a> [service\_accounts](#input\_service\_accounts) | (Optional) Map of Scalr Service Accounts to create, keyed by a caller-chosen logical name (e.g.<br/>"ci"). Each entry:<br/>  - name:        (Optional) Name of the service account. Defaults to the entry's map key when<br/>                  unset.<br/>  - account\_id:  (Optional) ID of the account, in the format 'acc-'. Falls back to<br/>                  var.account\_id when unset.<br/>  - description: (Optional) Description of the service account.<br/>  - owners:       (Optional) Set of team IDs the service account belongs to.<br/>  - status:       (Optional) The status of the service account. One of "Active" or "Inactive".<br/>                  Defaults to "Active". | <pre>map(object({<br/>    name        = optional(string)<br/>    account_id  = optional(string)<br/>    description = optional(string)<br/>    owners      = optional(set(string))<br/>    status      = optional(string, "Active")<br/>  }))</pre> | `{}` | no |
| <a name="input_tokens"></a> [tokens](#input\_tokens) | (Optional) Map of Scalr Service Account tokens to create, forwarded as-is to the nested<br/>modules/scalr/iam/service\_account/token submodule. Each entry must set exactly one of<br/>service\_account\_id (a literal ID) or service\_account\_key (a key into this same module call's<br/>var.service\_accounts). See that submodule's variables.tf for the full field list. | <pre>map(object({<br/>    service_account_id  = optional(string)<br/>    service_account_key = optional(string)<br/>    description         = optional(string)<br/>    expires_in          = optional(number)<br/>    name                = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_assume_policy_ids"></a> [assume\_policy\_ids](#output\_assume\_policy\_ids) | Map of Scalr Assume Service Account Policy IDs, keyed by the same keys as var.assume\_policies. |
| <a name="output_assume_policy_service_account_ids"></a> [assume\_policy\_service\_account\_ids](#output\_assume\_policy\_service\_account\_ids) | Map of the service\_account\_id actually passed to each scalr\_assume\_service\_account\_policy resource (from the composed ./assume\_policy submodule), keyed by the same keys as var.assume\_policies. Useful for callers/tests that need to prove which service account was actually wired into each policy. |
| <a name="output_created_by"></a> [created\_by](#output\_created\_by) | Map of the details (email, full\_name, username) of the user that created each service account, keyed by the same keys as var.service\_accounts. |
| <a name="output_emails"></a> [emails](#output\_emails) | Map of Scalr Service Account emails, keyed by the same keys as var.service\_accounts. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Service Account IDs, keyed by the same keys as var.service\_accounts. |
| <a name="output_token_ids"></a> [token\_ids](#output\_token\_ids) | Map of Scalr Service Account Token IDs, keyed by the same keys as var.tokens. |
| <a name="output_token_service_account_ids"></a> [token\_service\_account\_ids](#output\_token\_service\_account\_ids) | Map of the service\_account\_id actually passed to each scalr\_service\_account\_token resource (from the composed ./token submodule), keyed by the same keys as var.tokens. Useful for callers/tests that need to prove which service account was actually wired into each token. |
| <a name="output_tokens"></a> [tokens](#output\_tokens) | Map of the issued Service Account token values, keyed by the same keys as var.tokens. Sensitive. |
<!-- END_TF_DOCS -->
