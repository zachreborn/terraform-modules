<a name="readme-top"></a>

## scalr/provider_configuration/default

Manages [`scalr_provider_configuration_default`](https://registry.terraform.io/providers/Scalr/scalr/latest/docs/resources/provider_configuration_default) resources, which mark a provider configuration as the default for an environment. This is a companion submodule to [`../`](../), which composes it automatically for entries in `provider_configuration_defaults`; it may also be called standalone.

### Prerequisites

- The provider configuration referenced by `provider_configuration_id` must already exist and be shared with the target environment (see the `environments` attribute of `scalr_provider_configuration`).
- The environment referenced by `environment_id` must already exist.

### Usage

```hcl
module "provider_configuration_default" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/provider_configuration/default"

  provider_configuration_defaults = {
    aws_prod = {
      environment_id            = "env-xxxxxxxxxx"
      provider_configuration_id = "pcfg-xxxxxxxxxx"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Notes / Design Decisions

- `provider_configuration_defaults` is a `map(object({...}))` so callers can manage any number of defaults with a single module call.

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
| scalr_provider_configuration_default.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_provider_configuration_defaults"></a> [provider\_configuration\_defaults](#input\_provider\_configuration\_defaults) | Map of scalr\_provider\_configuration\_default resources to create, keyed by a caller-chosen<br/>logical name. Each entry marks a provider configuration as the default for an environment.<br/>Fields:<br/>  - environment\_id:            (Required) ID of the environment, in the format "env-<RANDOM STRING>".<br/>  - provider\_configuration\_id: (Required) ID of the provider configuration, in the format "pcfg-<RANDOM STRING>".<br/><br/>Note: to make a provider configuration default, it must already be shared with the specified<br/>environment -- see the `environments` attribute of scalr\_provider\_configuration. | <pre>map(object({<br/>    environment_id            = string<br/>    provider_configuration_id = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Provider Configuration Default IDs, keyed by the same keys as var.provider\_configuration\_defaults. |
<!-- END_TF_DOCS -->
