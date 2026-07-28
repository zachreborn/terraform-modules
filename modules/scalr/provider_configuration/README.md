<a name="readme-top"></a>

## scalr/provider_configuration

Manages [`scalr_provider_configuration`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/provider_configuration) resources with full multi-cloud coverage (`aws`, `azurerm`, `google`, `scalr`, and `custom` provider blocks), and composes the companion [`./default`](./default) submodule to optionally manage [`scalr_provider_configuration_default`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/provider_configuration_default) resources.

This submodule implements the `scalr_provider_configuration` resource for the `modules/scalr` root module, which composes it to manage all of its AWS, AzureRM, Google, and custom provider configurations. You can also call it directly when you need those provider configurations, or full AWS argument coverage (e.g. `credentials_source`, `default_tags`), outside the root module's YAML interface.

### Prerequisites

- For `aws`/`azurerm`/`google`/`scalr` credential-bearing entries, have the relevant secret values (access keys, client secrets, service account JSON, tokens) ready to pass via `provider_configuration_secrets` -- never inline them in `provider_configurations`.
- For `provider_configuration_defaults`, the referenced environment must already exist, and the provider configuration must already be shared with it (via `environments`).

### Usage

```hcl
module "provider_configuration" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/provider_configuration"

  provider_configurations = {
    aws_prod = {
      account_id   = "acc-xxxxxxxxxx"
      environments = ["*"]
      aws = {
        credentials_type = "oidc"
        role_arn         = "arn:aws:iam::123456789012:role/scalr-oidc-role"
        audience         = "aws.scalr-run-workload"
      }
    }

    azurerm_prod = {
      account_id = "acc-xxxxxxxxxx"
      azurerm = {
        client_id       = "my-client-id"
        tenant_id       = "my-tenant-id"
        subscription_id = "my-subscription-id"
      }
    }

    k8s = {
      account_id = "acc-xxxxxxxxxx"
      custom = {
        provider_name = "kubernetes"
        arguments = [
          { name = "host", value = "https://k8s.example.com" },
          { name = "password", sensitive = true },
        ]
      }
    }
  }

  # Sensitive values, keyed the same as the entries above that need them.
  provider_configuration_secrets = {
    azurerm_prod = {
      azurerm_client_secret = var.azurerm_client_secret # e.g. from a secret manager
    }
    k8s = {
      custom_argument_values = {
        password = var.k8s_password
      }
    }
  }

  # Optional: manage provider configuration defaults via the companion submodule.
  provider_configuration_defaults = {
    aws_prod_default = {
      provider_configuration_key = "aws_prod" # resolved internally to the configuration created above
      environment_id              = "env-xxxxxxxxxx"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Notes / Design Decisions

- `provider_configurations` is a `map(object({...}))` so callers can manage any number of configurations with a single module call (per [AGENTS.md §5](../../../AGENTS.md)). Each entry must set exactly one of the `aws`, `azurerm`, `google`, `scalr`, or `custom` blocks, matching the upstream provider's own constraint.
- **Sensitive fields are split into a separate variable.** `secret_key` (aws), `client_secret` (azurerm), `credentials` (google), `token` (scalr), and `custom` argument values marked `sensitive = true` are deliberately *not* part of `provider_configurations`. They live in `provider_configuration_secrets`, keyed by the same logical key. This is necessary because `provider_configurations` is this module's `for_each` source, and OpenTofu/Terraform forbid using a sensitive collection as a `for_each` argument (the engine needs to see the map keys in the plan). Marking the whole `provider_configurations` map sensitive would break `for_each`; splitting the truly sensitive leaf values into their own always-sensitive map avoids that while still keeping every real secret marked `sensitive = true`.
- `custom.arguments` entries with `sensitive = true` ignore their own `value` field in `provider_configurations` (even if set) and instead read from `provider_configuration_secrets[<key>].custom_argument_values[<argument name>]`.
- `provider_configuration_defaults` entries reference a provider configuration either by `provider_configuration_key` (an entry created by this same module call -- resolved internally to its ID) or by a literal, externally-managed `provider_configuration_id`. Exactly one of the two must be set.
- This module accepts `account_id` per-entry rather than resolving it internally via `data.scalr_current_account`, so `tofu test` can run fully offline with `mock_provider`.

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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_default"></a> [default](#module\_default) | ./default | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| scalr_provider_configuration.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_provider_configuration_defaults"></a> [provider\_configuration\_defaults](#input\_provider\_configuration\_defaults) | Map of scalr\_provider\_configuration\_default resources to create via the companion ./default<br/>submodule, keyed by a caller-chosen logical name. Set exactly one of:<br/>  - provider\_configuration\_key: The map key of an entry in var.provider\_configurations whose ID<br/>                                is resolved internally by this module (composition wiring).<br/>  - provider\_configuration\_id:  A literal, externally-managed provider configuration ID (format<br/>                                "pcfg-<RANDOM STRING>").<br/>Fields:<br/>  - environment\_id: (Required) ID of the environment, in the format "env-<RANDOM STRING>". | <pre>map(object({<br/>    provider_configuration_key = optional(string)<br/>    provider_configuration_id  = optional(string)<br/>    environment_id             = string<br/>  }))</pre> | `{}` | no |
| <a name="input_provider_configuration_secrets"></a> [provider\_configuration\_secrets](#input\_provider\_configuration\_secrets) | Map of sensitive credential values for var.provider\_configurations, keyed by the same logical<br/>key. Kept in a separate, wholly `sensitive = true` variable so that var.provider\_configurations<br/>itself can remain non-sensitive (required, since it is the for\_each source for<br/>scalr\_provider\_configuration.this). Populate only the field(s) relevant to the corresponding<br/>entry's provider block:<br/>  - aws\_secret\_key:         scalr\_provider\_configuration.aws.secret\_key<br/>  - azurerm\_client\_secret:  scalr\_provider\_configuration.azurerm.client\_secret<br/>  - google\_credentials:     scalr\_provider\_configuration.google.credentials<br/>  - scalr\_token:            scalr\_provider\_configuration.scalr.token<br/>  - custom\_argument\_values: map of custom.argument name => sensitive value, for arguments whose<br/>    `sensitive = true` in the corresponding var.provider\_configurations[<key>].custom.arguments entry. | <pre>map(object({<br/>    aws_secret_key         = optional(string)<br/>    azurerm_client_secret  = optional(string)<br/>    google_credentials     = optional(string)<br/>    scalr_token            = optional(string)<br/>    custom_argument_values = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_provider_configurations"></a> [provider\_configurations](#input\_provider\_configurations) | Map of Scalr Provider Configurations (scalr\_provider\_configuration) to create, keyed by a<br/>caller-chosen logical name. Each entry must set exactly one of the aws / azurerm / google /<br/>scalr / custom blocks. Fields:<br/>  - name:                    (Optional) Name of the provider configuration, unique per account.<br/>                            Defaults to the entry's map key.<br/>  - account\_id:               (Optional) The account that owns the object, in the format "acc-<RANDOM STRING>".<br/>  - apply\_only:               (Optional) When enabled, the provider configuration is used only during the<br/>                            apply phase of a run. Currently supported for AWS only. Set only at creation time.<br/>  - environments:             (Optional) Set of environment IDs the configuration is shared to. Use ["*"] to<br/>                            share with all environments.<br/>  - export\_shell\_variables:   (Optional) Export provider variables into the run environment. Available for<br/>                            built-in (Scalr, AWS, AzureRM, Google) providers only.<br/>  - owners:                   (Optional) Set of team IDs the provider configuration belongs to.<br/>  - tag\_ids:                  (Optional) Set of tag IDs associated with the provider configuration.<br/>  - aws:                      (Optional) AWS provider settings. See below.<br/>  - azurerm:                  (Optional) AzureRM provider settings. See below.<br/>  - google:                   (Optional) Google provider settings. See below.<br/>  - scalr:                    (Optional) Scalr provider settings. See below.<br/>  - custom:                   (Optional) Settings for a provider without built-in Scalr support. See below.<br/><br/>aws fields:<br/>  - credentials\_type:    (Required) One of "access\_keys", "role\_delegation", "oidc".<br/>  - access\_key:          (Optional) AWS access key. Required with "access\_keys".<br/>  - account\_type:        (Optional) One of "regular", "gov-cloud", "cn-cloud".<br/>  - audience:            (Optional) The "aud" claim value for the identity token. Required with "oidc".<br/>  - credentials\_source:  (Optional) One of "Ec2InstanceMetadata", "EcsContainer". Used with "role\_delegation"<br/>                         and "aws\_service" trusted\_entity\_type.<br/>  - external\_id:         (Optional) External ID for assuming the role. Required with "role\_delegation" and<br/>                         "aws\_account" trusted\_entity\_type.<br/>  - role\_arn:            (Optional) ARN of the IAM role to assume. Required with "role\_delegation"/"oidc".<br/>  - trusted\_entity\_type: (Optional) One of "aws\_account", "aws\_service". Required with "role\_delegation".<br/>  - default\_tags:        (Optional) { tags = map(string), strategy = "skip"\|"update" }.<br/>  - secret\_key:          Sensitive -- supplied via var.provider\_configuration\_secrets[<key>].aws\_secret\_key,<br/>                         not here. Required with "access\_keys".<br/><br/>azurerm fields:<br/>  - client\_id:       (Required) The Client ID to use.<br/>  - tenant\_id:       (Required) The Tenant ID to use.<br/>  - audience:        (Optional) The "aud" claim value for the identity token. Required with auth\_type "oidc".<br/>  - auth\_type:       (Optional) One of "client-secrets" (default), "oidc".<br/>  - subscription\_id: (Optional) The Subscription ID to use.<br/>  - client\_secret:   Sensitive -- supplied via var.provider\_configuration\_secrets[<key>].azurerm\_client\_secret,<br/>                     not here. Required when auth\_type is "client-secrets".<br/><br/>google fields:<br/>  - auth\_type:              (Optional) One of "service-account-key" (default), "oidc".<br/>  - project:                (Optional) The default project ID to manage resources in.<br/>  - service\_account\_email:  (Optional) Required when auth\_type is "oidc".<br/>  - use\_default\_project:    (Optional) Whether the project a credential is created in is used by default.<br/>  - workload\_provider\_name: (Optional) Required when auth\_type is "oidc".<br/>  - default\_labels:         (Optional) { labels = map(string), strategy = "skip"\|"update" }.<br/>  - credentials:            Sensitive -- supplied via var.provider\_configuration\_secrets[<key>].google\_credentials,<br/>                            not here. Required when auth\_type is "service-account-key".<br/><br/>scalr fields:<br/>  - hostname: (Required) The Scalr hostname to use.<br/>  - token:    Sensitive -- supplied via var.provider\_configuration\_secrets[<key>].scalr\_token, not here.<br/><br/>custom fields:<br/>  - provider\_name: (Required) The name of the Terraform/OpenTofu provider, e.g. "kubernetes".<br/>  - arguments:      (Required, min 1) List of { name, value, description, hcl, sensitive }. When an<br/>                    argument's `sensitive` is true, its `value` here is ignored; supply the real value via<br/>                    var.provider\_configuration\_secrets[<key>].custom\_argument\_values[<argument name>] instead.<br/><br/>Sensitive credential fields are intentionally NOT part of this variable -- see<br/>var.provider\_configuration\_secrets. Keeping them out of this map lets var.provider\_configurations<br/>remain non-sensitive, which is required because it is this module's for\_each source (OpenTofu/<br/>Terraform disallow for\_each over a sensitive collection). | <pre>map(object({<br/>    name                   = optional(string)<br/>    account_id             = optional(string)<br/>    apply_only             = optional(bool, false)<br/>    environments           = optional(set(string))<br/>    export_shell_variables = optional(bool, false)<br/>    owners                 = optional(set(string))<br/>    tag_ids                = optional(set(string))<br/><br/>    aws = optional(object({<br/>      credentials_type    = string<br/>      access_key          = optional(string)<br/>      account_type        = optional(string)<br/>      audience            = optional(string)<br/>      credentials_source  = optional(string)<br/>      external_id         = optional(string)<br/>      role_arn            = optional(string)<br/>      trusted_entity_type = optional(string)<br/>      default_tags = optional(object({<br/>        tags     = optional(map(string))<br/>        strategy = optional(string)<br/>      }))<br/>    }))<br/><br/>    azurerm = optional(object({<br/>      client_id       = string<br/>      tenant_id       = string<br/>      audience        = optional(string)<br/>      auth_type       = optional(string, "client-secrets")<br/>      subscription_id = optional(string)<br/>    }))<br/><br/>    google = optional(object({<br/>      auth_type              = optional(string, "service-account-key")<br/>      project                = optional(string)<br/>      service_account_email  = optional(string)<br/>      use_default_project    = optional(bool)<br/>      workload_provider_name = optional(string)<br/>      default_labels = optional(object({<br/>        labels   = optional(map(string))<br/>        strategy = optional(string)<br/>      }))<br/>    }))<br/><br/>    scalr = optional(object({<br/>      hostname = string<br/>    }))<br/><br/>    custom = optional(object({<br/>      provider_name = string<br/>      arguments = optional(list(object({<br/>        name        = string<br/>        value       = optional(string)<br/>        description = optional(string)<br/>        hcl         = optional(bool, false)<br/>        sensitive   = optional(bool, false)<br/>      })), [])<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_default_ids"></a> [default\_ids](#output\_default\_ids) | Map of Provider Configuration Default IDs (from the companion ./default submodule), keyed by the same keys as var.provider\_configuration\_defaults. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Provider Configuration IDs, keyed by the same keys as var.provider\_configurations. |
| <a name="output_resolved_defaults"></a> [resolved\_defaults](#output\_resolved\_defaults) | Map of environment\_id/provider\_configuration\_id pairs actually passed to the companion ./default submodule, keyed by the same keys as var.provider\_configuration\_defaults. Useful to verify composition wiring. |
<!-- END_TF_DOCS -->
