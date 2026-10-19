<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Module Test Provider Configuration Module</h3>
  <p align="center">
    This module manages <code>scalr_module_test_provider_configuration</code> resources in Scalr, attaching provider configurations (credentials) to module test configurations.
    <br />
    <a href="https://github.com/zachreborn/terraform-modules"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://zacharyhill.co">Zachary Hill</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Report Bug</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Prerequisites

- Scalr provider `>= 3.20.0` (`scalr_module_test_provider_configuration` was first released in v3.20.0).
- An existing module test configuration (`test_configuration_id`, format `tc-<RANDOM STRING>`), for example one created by the sibling [`test_configuration`](../test_configuration) module.
- An existing provider configuration (`provider_configuration_id`, format `pcfg-<RANDOM STRING>`), for example one created by [`modules/scalr/provider_configuration`](../../provider_configuration).

### Caller constraints Terraform cannot check

This module validates the ID formats only. Scalr enforces the following two rules server-side when the link is created, so an invalid combination fails on `apply`, not on `plan`:

1. **The provider configuration must allow module tests.** It must have `is_allowed_in_module_test = true`. Set this on the entry in `modules/scalr/provider_configuration` (or directly on `scalr_provider_configuration`).
2. **One provider configuration per provider type per test configuration.** A test configuration can be linked to only one provider configuration of each provider type, for example one `aws` and one `azurerm`, but not two `aws` configurations. Entries in this module's map that share a `test_configuration_id` must therefore point to provider configurations of different provider types.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "module_test_provider_configurations" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/module/test_provider_configuration"

  module_test_provider_configurations = {
    vpc_aws = {
      test_configuration_id     = "tc-xxxxxxxxxx"
      provider_configuration_id = "pcfg-xxxxxxxxxx"
    }
  }
}
```

### Wired to the sibling modules

```hcl
module "provider_configuration" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/provider_configuration"

  provider_configurations = {
    aws_module_test = {
      account_id                = "acc-xxxxxxxxxx"
      environments              = ["*"]
      is_allowed_in_module_test = true # required to link this configuration to a module test
      aws = {
        credentials_type = "oidc"
        role_arn         = "arn:aws:iam::123456789012:role/scalr-oidc-role"
        audience         = "aws.scalr-run-workload"
      }
    }
  }
}

module "module_test_configurations" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/module/test_configuration"

  module_test_configurations = {
    vpc = {
      module_id = "mod-xxxxxxxxxx"
    }
  }
}

module "module_test_provider_configurations" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/module/test_provider_configuration"

  module_test_provider_configurations = {
    vpc_aws = {
      test_configuration_id     = module.module_test_configurations.ids["vpc"]
      provider_configuration_id = module.provider_configuration.ids["aws_module_test"]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `module_test_provider_configurations` is a `map(object({...}))` keyed by a caller-chosen logical name, so a single module call can attach any number of provider configurations to any number of test configurations.
- **Light ID-format validation only.** `test_configuration_id` must start with `tc-` and `provider_configuration_id` must start with `pcfg-`. This catches the common mistake of passing a module ID (`mod-`) where a test configuration ID is expected. The two Scalr-side constraints listed under [Prerequisites](#caller-constraints-terraform-cannot-check) depend on remote state and cannot be checked at plan time.
- **Changing `test_configuration_id` replaces the link; changing `provider_configuration_id` updates it in place** (this is the provider's behavior).
- The link ID (the `ids` output) has the format `tpcfgl-<RANDOM STRING>` and is also the import ID: `terraform import 'module.module_test_provider_configurations.scalr_module_test_provider_configuration.this["vpc_aws"]' tpcfgl-xxxxxxxxxx`.
- The sibling `modules/scalr/provider_configuration` module exposes a read-only `is_used_in_module_test` output that reports whether a provider configuration is currently linked to a module test.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.20.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.20.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_module_test_provider_configuration.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_module_test_provider_configurations"></a> [module\_test\_provider\_configurations](#input\_module\_test\_provider\_configurations) | Map of links (`scalr_module_test_provider_configuration`) that attach a provider configuration<br/>(credentials) to a module test configuration, keyed by a caller-chosen logical name. The attached<br/>provider configuration is used while the module's tests run.<br/><br/>Constraints that Terraform cannot check at plan time (Scalr enforces them on apply):<br/>  - The provider configuration must have is\_allowed\_in\_module\_test = true (see the sibling<br/>    modules/scalr/provider\_configuration module).<br/>  - Only one provider configuration per provider type (for example one "aws") can be linked to a<br/>    given test configuration.<br/><br/>Fields:<br/>  - test\_configuration\_id:     (Required) ID of the module test configuration, in the format<br/>                               "tc-<RANDOM STRING>". Typically the output of modules/scalr/module/test\_configuration.<br/>  - provider\_configuration\_id: (Required) ID of the provider configuration to use as credentials for the<br/>                               module tests, in the format "pcfg-<RANDOM STRING>".<br/><br/>Example:<br/>  module\_test\_provider\_configurations = {<br/>    vpc\_aws = {<br/>      test\_configuration\_id     = "tc-xxxxxxxxxx"<br/>      provider\_configuration\_id = "pcfg-xxxxxxxxxx"<br/>    }<br/>  } | <pre>map(object({<br/>    test_configuration_id     = string<br/>    provider_configuration_id = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of module test provider configuration link IDs (format 'tpcfgl-<RANDOM STRING>'), keyed by the same keys as var.module\_test\_provider\_configurations. |
| <a name="output_links"></a> [links](#output\_links) | Map of the resolved link (id, test\_configuration\_id, provider\_configuration\_id) for each entry, keyed by the same keys as var.module\_test\_provider\_configurations. Useful for callers/tests that need to prove which test configuration / provider configuration pair was wired into each resource. |
<!-- END_TF_DOCS -->

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasaurus)
- [Brad Engberg](https://github.com/bradms98)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
