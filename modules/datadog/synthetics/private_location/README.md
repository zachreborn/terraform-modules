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

<h3 align="center">Datadog Synthetics Private Location</h3>
  <p align="center">
    Manages Datadog Synthetics private locations using a scalable map/for_each pattern.
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
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Description

Manages `datadog_synthetics_private_location` resources. Private locations allow you to run Datadog Synthetic tests against internal endpoints that are not accessible from the public internet. Each private location generates an installation JSON blob (the `config` output) that is used to configure the private location worker in your infrastructure.

## Prerequisites

- A Datadog account with Synthetics enabled.
- A Datadog provider configured with an API key and Application key that has the `synthetics_write` permission.
- Infrastructure to run the private location Docker container or Helm chart (the installation JSON from the `configs` output is required during setup).

## Usage

### Simple Example

```hcl
module "synthetics_private_locations" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/synthetics/private_location"

  private_locations = {
    datacenter_east = {
      name        = "US East Datacenter"
      description = "Private location for the US East datacenter"
      tags        = ["env:production", "region:us-east"]
    }

    datacenter_west = {
      name        = "US West Datacenter"
      description = "Private location for the US West datacenter"
      tags        = ["env:production", "region:us-west"]
    }
  }
}

# Use the configs output to install the private location workers
output "private_location_configs" {
  value     = module.synthetics_private_locations.configs
  sensitive = true
}
```

### Example with Metadata

```hcl
module "synthetics_private_location" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/synthetics/private_location"

  private_locations = {
    internal_api = {
      name        = "Internal API Location"
      description = "Private location for internal API testing"
      tags        = ["env:staging", "team:platform"]
      metadata = {
        restricted_roles = ["role-id-1", "role-id-2"]
      }
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **Sensitive `configs` output**: The `configs` output contains installation JSON blobs that include credentials. This output is marked `sensitive = true`. Ensure your Terraform state is encrypted when using this module.
- **`api_key` field**: The optional `api_key` field allows specifying an existing Datadog API key for generating the private location configuration. If omitted, Datadog generates an API key automatically. Because this field can contain a sensitive API key, pass it from a `sensitive` variable and ensure state encryption is enabled.
- **`restricted_roles` deprecated**: The `metadata.restricted_roles` field is deprecated by the Datadog API. Use a `datadog_restriction_policy` resource referencing the `restriction_policy_resource_ids` output instead.
- **required_version >= 1.0.0**: Follows the repo-wide convention. All modules require OpenTofu >= 1.6.0 or Terraform >= 1.0.0 — the `>= 1.0.0` constraint satisfies both, since OpenTofu 1.6.x >= 1.0.0.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
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
| [datadog_synthetics_private_location.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/synthetics_private_location) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_private_locations"></a> [private\_locations](#input\_private\_locations) | Map of Synthetics private location configurations keyed by logical name. The api\_key field is sensitive — pass it via a sensitive variable or use Terraform state encryption. | <pre>map(object({<br/>    name        = string<br/>    description = optional(string, "")<br/>    tags        = optional(list(string), [])<br/>    api_key     = optional(string, null)<br/>    metadata = optional(object({<br/>      restricted_roles = optional(set(string), null)<br/>    }), null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_configs"></a> [configs](#output\_configs) | Map of private location installation JSON configuration blobs keyed by logical name. These are sensitive and contain the credentials required to install the private location worker. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of private location IDs keyed by logical name. |
| <a name="output_restriction_policy_resource_ids"></a> [restriction\_policy\_resource\_ids](#output\_restriction\_policy\_resource\_ids) | Map of resource IDs keyed by logical name, for use when setting restrictions with a datadog\_restriction\_policy resource. |
<!-- END_TF_DOCS -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Acknowledgments

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
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
