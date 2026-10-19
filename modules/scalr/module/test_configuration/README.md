<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Module Test Configuration Module</h3>
  <p align="center">
    This module manages <code>scalr_module_test_configuration</code> resources in Scalr, configuring how <code>tofu test</code> runs for modules in the Private Module Registry.
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

- Scalr provider `>= 3.20.0` (`scalr_module_test_configuration` was first released in v3.20.0).
- An existing module in the Scalr Private Module Registry (`module_id`, format `mod-<RANDOM STRING>`), for example one created by the sibling [`modules/scalr/module`](../README.md) module.
- A Scalr server that supports module testing. The v3.20.0 provider changelog does not state a minimum server version, so confirm your Scalr instance supports it before applying.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "module_test_configurations" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/module/test_configuration"

  module_test_configurations = {
    vpc = {
      module_id                      = "mod-xxxxxxxxxx"
      enabled                        = true
      failure_behavior               = "failure" # "failure" or "notify" (default)
      trigger_on_new_version_enabled = true
      trigger_on_pr_activity_enabled = true
    }
  }
}
```

### Wired to the Private Module Registry module

```hcl
module "registry" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/module"

  modules = {
    vpc = {
      vcs_provider_id = "vcs-xxxxxxxxxx"
      vcs_repo = {
        identifier = "my-org/terraform-aws-vpc"
      }
    }
  }
}

module "module_test_configurations" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/module/test_configuration"

  module_test_configurations = {
    vpc = {
      module_id = module.registry.ids["vpc"]
    }
  }
}
```

To give the tests cloud credentials, pass `module.module_test_configurations.ids` to the sibling [`test_provider_configuration`](../test_provider_configuration) module.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `module_test_configurations` is a `map(object({...}))` keyed by a caller-chosen logical name, so a single module call can configure tests for any number of modules.
- **One test configuration per module.** Scalr has a single test configuration per module (the provider creates it on first use and updates it afterwards). The module therefore rejects two entries with the same `module_id`, because they would manage the same remote object and fight over its settings.
- **Destroy disables, it does not delete.** Scalr has no delete endpoint for a test configuration. Removing an entry (or running `destroy`) sets `enabled = false` on the remote object instead of removing it.
- **Defaults mirror the provider:** `enabled = true`, `failure_behavior = "notify"`, and both trigger flags `false`. `failure_behavior` is validated against the provider's accepted values (`failure`, `notify`).
- **Import** uses the module ID (not the `tc-` ID): `terraform import 'module.module_test_configurations.scalr_module_test_configuration.this["vpc"]' mod-xxxxxxxxxx`.
- The `ids` output returns the `tc-...` test configuration IDs, which is what `modules/scalr/module/test_provider_configuration` expects as `test_configuration_id`.
- **Tool versions.** The module itself needs Terraform `>= 1.3.0` (for `optional()` object attributes with defaults); every OpenTofu release satisfies this. Its validations only reference their own variable, so the `>= 1.9.0` floor used by modules with cross-variable validation does not apply. Running the bundled tests (`tofu test`) additionally needs OpenTofu `>= 1.8.0` or Terraform `>= 1.7.0`, because they use `mock_provider`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
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
| scalr_module_test_configuration.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_module_test_configurations"></a> [module\_test\_configurations](#input\_module\_test\_configurations) | Map of Scalr module test configurations (`scalr_module_test_configuration`) to manage, keyed by a<br/>caller-chosen logical name. Each entry manages the `tofu test` configuration of one module in the<br/>Private Module Registry.<br/><br/>A module has exactly one test configuration, so module\_id must be unique across the entries of this<br/>map. Scalr has no delete endpoint for a test configuration: destroying an entry disables it<br/>(enabled = false) rather than removing it.<br/><br/>Fields:<br/>  - module\_id:                      (Required) ID of the module, in the format "mod-<RANDOM STRING>".<br/>  - enabled:                        (Optional) Whether the test configuration is enabled. Defaults to true.<br/>  - failure\_behavior:               (Optional) The behavior to apply when a test run fails. Valid values are<br/>                                    "failure" and "notify". Defaults to "notify".<br/>  - trigger\_on\_new\_version\_enabled: (Optional) Whether a test run is triggered when a new module version is<br/>                                    synced. Defaults to false.<br/>  - trigger\_on\_pr\_activity\_enabled: (Optional) Whether a test run is triggered on pull request activity.<br/>                                    Defaults to false.<br/><br/>Example:<br/>  module\_test\_configurations = {<br/>    vpc = {<br/>      module\_id                      = "mod-xxxxxxxxxx"<br/>      failure\_behavior               = "failure"<br/>      trigger\_on\_new\_version\_enabled = true<br/>      trigger\_on\_pr\_activity\_enabled = true<br/>    }<br/>  } | <pre>map(object({<br/>    module_id                      = string<br/>    enabled                        = optional(bool, true)<br/>    failure_behavior               = optional(string, "notify")<br/>    trigger_on_new_version_enabled = optional(bool, false)<br/>    trigger_on_pr_activity_enabled = optional(bool, false)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of module test configuration IDs (format 'tc-<RANDOM STRING>'), keyed by the same keys as var.module\_test\_configurations. Pass these to the sibling module/test\_provider\_configuration as test\_configuration\_id. |
| <a name="output_test_configurations"></a> [test\_configurations](#output\_test\_configurations) | Map of the resolved settings (id, module\_id, enabled, failure\_behavior, trigger\_on\_new\_version\_enabled, trigger\_on\_pr\_activity\_enabled) of each test configuration, keyed by the same keys as var.module\_test\_configurations. None of these values are sensitive. |
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
