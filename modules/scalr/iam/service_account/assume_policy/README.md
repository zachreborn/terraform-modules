<a name="readme-top"></a>

# scalr/iam/service_account/assume_policy

Manages [`scalr_assume_service_account_policy`](https://github.com/Scalr/terraform-provider-scalr/blob/master/docs/resources/assume_service_account_policy.md) resources -- policies allowing an external workload identity (e.g. GitHub Actions, GitLab CI) to assume a Scalr Service Account via OIDC.

This is a companion submodule to `modules/scalr/iam/service_account`, which composes it automatically. It can also be called directly against an existing Service Account.

## Prerequisites

- A Scalr account and an authenticated `scalr` provider (see the [Scalr Terraform Provider docs](https://docs.scalr.io/terraform-provider)).
- The referenced Service Account (`service_account_id`, or a `service_account_key` resolved via `service_account_ids`) must already exist -- provision it with `modules/scalr/iam/service_account` first.
- A Workload Identity Provider (`provider_id`, format `wip-`) must already exist -- e.g. via the `data.scalr_workload_identity_provider` data source or the `modules/scalr/workload_identity_provider` submodule.

## Usage

```hcl
data "scalr_workload_identity_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

module "assume_policies" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/iam/service_account/assume_policy"

  assume_policies = {
    ga_scalr_staging = {
      name                     = "ga-scalr-staging"
      service_account_id       = "sa-xxxxxxxxxx"
      provider_id              = data.scalr_workload_identity_provider.github.id
      maximum_session_duration = 7200
      claim_conditions = [
        {
          claim    = "sub"
          value    = "repo:GithubOrganization/repository:environment:staging"
          operator = "startswith"
        },
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

- `assume_policies` is a `map(object({...}))` so callers can manage many policies via a single module call. Each entry must set exactly one of `service_account_id` (a literal ID) or `service_account_key` (a key into `service_account_ids`) -- the same key/id resolution pattern used by the sibling `modules/scalr/iam/service_account/token` submodule.
- `claim_conditions` is expressed as a `dynamic "claim_condition"` block; `operator` is validated against the exact enum the provider documents (`eq`, `contains`, `startswith`, `endswith`, `like`) when set, and left `null` (provider default) when omitted.
- `claim_conditions` requires **at least one entry**. The published provider docs list `claim_condition` as an Optional block, but the real v3.17.0 provider schema rejects a plan with zero `claim_condition` blocks (`"Block claim_condition must have a configuration value as the provider has marked it as required"`) -- verified directly against the downloaded provider binary. Requiring at least one entry here also matches secure-by-default practice: a policy with no claim conditions would otherwise let any holder of a valid OIDC token from the associated Workload Identity Provider assume the service account.
- `name` defaults to the entry's map key when unset, consistent with the other IAM submodules in this repository.

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
| scalr_assume_service_account_policy.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_assume_policies"></a> [assume\_policies](#input\_assume\_policies) | (Optional) Map of Scalr Assume Service Account Policies to create, keyed by a caller-chosen<br/>logical name (e.g. "ga-scalr-staging"). Each entry must set exactly one of:<br/>  - service\_account\_id:  A literal Scalr Service Account ID (format 'sa-') this policy is<br/>                          attached to.<br/>  - service\_account\_key: A key into var.service\_account\_ids (e.g. the `ids` output of<br/>                          modules/scalr/iam/service\_account) identifying the service account this<br/>                          policy is attached to.<br/>Other fields:<br/>  - name:                     (Optional) The name of the policy. Defaults to the entry's map key<br/>                               when unset.<br/>  - provider\_id:              (Required) The ID of the Workload Identity Provider (format<br/>                               'wip-') associated with this policy.<br/>  - maximum\_session\_duration: (Optional) The maximum session duration in seconds for the assumed<br/>                               role.<br/>  - claim\_conditions:         (Required, non-empty) List of claim conditions the caller's OIDC<br/>                               token must satisfy to assume the service account. The provider's<br/>                               published docs list this block as Optional, but the real v3.17.0<br/>                               provider schema rejects a plan with zero claim\_condition blocks<br/>                               ("Block claim\_condition must have a configuration value as the<br/>                               provider has marked it as required") -- verified directly against<br/>                               the downloaded provider binary. This module therefore requires at<br/>                               least one entry, which also matches secure-by-default practice: a<br/>                               policy with no claim conditions would otherwise let any holder of a<br/>                               valid OIDC token from the associated provider assume the service<br/>                               account.<br/>                                 - claim:    (Required) The claim to match (e.g. "sub").<br/>                                 - value:    (Required) The value to match for the claim.<br/>                                 - operator: (Optional) One of "eq", "contains", "startswith",<br/>                                             "endswith", or "like". Defaults to the provider's own<br/>                                             default when unset. | <pre>map(object({<br/>    service_account_id       = optional(string)<br/>    service_account_key      = optional(string)<br/>    name                     = optional(string)<br/>    provider_id              = string<br/>    maximum_session_duration = optional(number)<br/>    claim_conditions = optional(list(object({<br/>      claim    = string<br/>      value    = string<br/>      operator = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_service_account_ids"></a> [service\_account\_ids](#input\_service\_account\_ids) | (Optional) Map of Scalr Service Account IDs keyed by logical name, e.g. the `ids` output of modules/scalr/iam/service\_account. Referenced by each assume\_policies entry's service\_account\_key. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Assume Service Account Policy IDs, keyed by the same keys as var.assume\_policies. |
| <a name="output_service_account_ids"></a> [service\_account\_ids](#output\_service\_account\_ids) | Map of the service\_account\_id actually passed to each scalr\_assume\_service\_account\_policy resource, keyed by the same keys as var.assume\_policies. Useful for callers/tests that need to prove which service account was actually wired into each policy. |
<!-- END_TF_DOCS -->
