<a name="readme-top"></a>

# scalr/iam/service_account/token

Manages [`scalr_service_account_token`](https://github.com/Scalr/terraform-provider-scalr/blob/master/docs/resources/service_account_token.md) resources -- authentication tokens issued to a Scalr Service Account.

This is a companion submodule to `modules/scalr/iam/service_account`, which composes it automatically. It can also be called directly against an existing Service Account.

## Prerequisites

- A Scalr account and an authenticated `scalr` provider (see the [Scalr Terraform Provider docs](https://docs.scalr.io/terraform-provider)).
- The referenced Service Account (`service_account_id`, or a `service_account_key` resolved via `service_account_ids`) must already exist -- provision it with `modules/scalr/iam/service_account` first.

## Usage

```hcl
module "service_account_tokens" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/iam/service_account/token"

  tokens = {
    ci = {
      service_account_id = "sa-xxxxxxxxxx"
      description         = "CI/CD pipeline token"
      expires_in           = 1440
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `tokens` is a `map(object({...}))` so callers can manage many tokens via a single module call. Each entry must set exactly one of `service_account_id` (a literal ID) or `service_account_key` (a key into `service_account_ids`) -- the same key/id resolution pattern used by `modules/aws/organizations/account`'s `parent_id`/`parent_key`.
- `service_account_ids` lets a parent module (e.g. `modules/scalr/iam/service_account`) wire in the IDs of Service Accounts it just created, without this submodule needing to know about that resource directly.
- The `token` attribute is the token's secret value and is marked `sensitive = true` on both the resource's output and the `tokens` output map.

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
| scalr_service_account_token.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_service_account_ids"></a> [service\_account\_ids](#input\_service\_account\_ids) | (Optional) Map of Scalr Service Account IDs keyed by logical name, e.g. the `ids` output of modules/scalr/iam/service\_account. Referenced by each tokens entry's service\_account\_key. | `map(string)` | `{}` | no |
| <a name="input_tokens"></a> [tokens](#input\_tokens) | (Optional) Map of Scalr Service Account tokens to create, keyed by a caller-chosen logical name<br/>(e.g. "default"). Each entry must set exactly one of:<br/>  - service\_account\_id:  A literal Scalr Service Account ID (format 'sa-').<br/>  - service\_account\_key: A key into var.service\_account\_ids (e.g. the `ids` output of<br/>                          modules/scalr/iam/service\_account) identifying the service account this<br/>                          token should be issued for.<br/>Other fields:<br/>  - description: (Optional) Description of the token.<br/>  - expires\_in:  (Optional) Number of minutes until the token expires.<br/>  - name:        (Optional) Name of the token. | <pre>map(object({<br/>    service_account_id  = optional(string)<br/>    service_account_key = optional(string)<br/>    description         = optional(string)<br/>    expires_in          = optional(number)<br/>    name                = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Service Account Token IDs, keyed by the same keys as var.tokens. |
| <a name="output_service_account_ids"></a> [service\_account\_ids](#output\_service\_account\_ids) | Map of the service\_account\_id actually passed to each scalr\_service\_account\_token resource, keyed by the same keys as var.tokens. Useful for callers/tests that need to prove which service account was actually wired into each token. |
| <a name="output_tokens"></a> [tokens](#output\_tokens) | Map of the issued Service Account token values, keyed by the same keys as var.tokens. Sensitive. |
<!-- END_TF_DOCS -->
