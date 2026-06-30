<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Datadog Monitor Config Policy</h3>
  <p align="center">
    Manages Datadog monitor config policies (datadog_monitor_config_policy) that enforce tag requirements on monitors.
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
    <li><a href="#description">Description</a></li>
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

## Description

This module manages one or more [Datadog monitor config policies](https://docs.datadoghq.com/monitors/settings/) (`datadog_monitor_config_policy`). Monitor config policies allow you to enforce tag requirements on monitors — for example, requiring that all monitors have an `env` tag set to either `staging` or `prod`.

## Prerequisites

- A Datadog account with an API key and Application key configured in the provider.
- The Datadog Terraform provider (`DataDog/datadog >= 4.0.0`) configured in the calling module or root.

## Usage

### Enforce required environment tags on monitors

```hcl
module "monitor_config_policies" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/monitors/config_policy"

  config_policies = {
    env_policy = {
      policy_type = "tag"
      tag_policy = {
        tag_key          = "env"
        tag_key_required = true
        valid_tag_values = ["staging", "prod"]
      }
    }
  }
}
```

### Multiple policies with optional and required tags

```hcl
module "monitor_config_policies" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/monitors/config_policy"

  config_policies = {
    env_required = {
      policy_type = "tag"
      tag_policy = {
        tag_key          = "env"
        tag_key_required = true
        valid_tag_values = ["dev", "staging", "prod"]
      }
    }
    team_optional = {
      policy_type = "tag"
      tag_policy = {
        tag_key          = "team"
        tag_key_required = false
        valid_tag_values = ["platform", "backend", "frontend", "data"]
      }
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **`required_version >= 1.3.0`**: This module uses the two-argument form of `optional()` (e.g. `optional(object({...}), null)`) for object-attribute defaults, which was introduced in Terraform 1.3.0 / OpenTofu 1.6.0. This is stricter than the default `>= 1.0.0` used in AWS modules and matches the other Datadog modules in this library.
- **Only `tag` policy type**: As of the current Datadog provider version, `tag` is the only supported `policy_type`. A validation block enforces this, and the `tag_policy` block must be set whenever `policy_type = "tag"`.
- **Enforcement scope**: Monitor config policies are org-wide. Each policy applies to all monitors in the Datadog organization. Creating multiple policies for the same tag key is allowed but may produce unexpected behavior — use one policy per tag key.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_datadog"></a> [datadog](#requirement\_datadog) | >= 4.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_datadog"></a> [datadog](#provider\_datadog) | 4.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [datadog_monitor_config_policy.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/monitor_config_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config_policies"></a> [config\_policies](#input\_config\_policies) | Map of Datadog monitor config policy configurations keyed by logical name. Each entry maps to one datadog\_monitor\_config\_policy resource. | <pre>map(object({<br/>    ###########################<br/>    # Required Fields<br/>    ###########################<br/>    policy_type = string<br/><br/>    ###########################<br/>    # tag_policy Block<br/>    ###########################<br/>    # Required when policy_type is "tag". Defines a tag enforcement policy for monitors.<br/>    tag_policy = optional(object({<br/>      tag_key          = string<br/>      tag_key_required = bool<br/>      valid_tag_values = list(string)<br/>    }), null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_config_policies"></a> [config\_policies](#output\_config\_policies) | Full map of all datadog\_monitor\_config\_policy resource objects, keyed by logical name. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of config policy logical names to their Datadog config policy IDs. |
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

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/zachreborn/terraform-modules.svg?style=for-the-badge
[contributors-url]: https://github.com/zachreborn/terraform-modules/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/zachreborn/terraform-modules.svg?style=for-the-badge
[forks-url]: https://github.com/zachreborn/terraform-modules/network/members
[stars-shield]: https://img.shields.io/github/stars/zachreborn/terraform-modules.svg?style=for-the-badge
[stars-url]: https://github.com/zachreborn/terraform-modules/stargazers
[issues-shield]: https://img.shields.io/github/issues/zachreborn/terraform-modules.svg?style=for-the-badge
[issues-url]: https://github.com/zachreborn/terraform-modules/issues
[license-shield]: https://img.shields.io/github/license/zachreborn/terraform-modules.svg?style=for-the-badge
[license-url]: https://github.com/zachreborn/terraform-modules/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
[product-screenshot]: /images/screenshot.webp
[Terraform.io]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform
[Terraform-url]: https://terraform.io
