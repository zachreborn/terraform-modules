[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Datadog Opsgenie Integration</h3>
  <p align="center">
    This module manages Datadog - Opsgenie service object integrations. Each entry in the map connects one Opsgenie service to Datadog, enabling Datadog monitors to route alerts directly to Opsgenie.
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
    <li><a href="#resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Prerequisites

- An Opsgenie account (Opsgenie is an Atlassian product — this module provides the Atlassian alerting integration path).
- An Opsgenie API key for each service object. Keys can be generated in the Opsgenie Integrations settings.
- For `region = "custom"`, the `custom_url` must also be specified.

## Usage

### Simple Example

```hcl
module "datadog_opsgenie" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/opsgenie"

  service_objects = {
    platform_alerts = {
      name             = "platform-alerts"
      opsgenie_api_key = "<YOUR_OPSGENIE_API_KEY>"
      region           = "us"
    }
    eu_service = {
      name             = "eu-service"
      opsgenie_api_key = "<YOUR_OPSGENIE_API_KEY>"
      region           = "eu"
    }
    custom_region = {
      name             = "custom-service"
      opsgenie_api_key = "<YOUR_OPSGENIE_API_KEY>"
      region           = "custom"
      custom_url       = "https://api.eu.opsgenie.com"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- **Opsgenie is an Atlassian product.** This module provides the Atlassian alerting integration path in addition to the generic webhook module (`modules/datadog/integrations/webhook`).
- The `service_objects` variable is marked `sensitive = true` because it contains Opsgenie API keys.
- The Datadog API never returns Opsgenie API keys after creation, so drift cannot be detected by Terraform. If the key changes outside Terraform, taint the resource to recreate it.
- Valid `region` values: `us`, `eu`, `custom`. When using `custom`, `custom_url` is required.

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
| [datadog_integration_opsgenie_service_object.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_opsgenie_service_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_service_objects"></a> [service\_objects](#input\_service\_objects) | Map of Opsgenie service objects keyed by a logical name. Each entry creates one Datadog - Opsgenie service integration. The opsgenie\_api\_key is sensitive. | <pre>map(object({<br/>    name             = string<br/>    opsgenie_api_key = string<br/>    region           = string<br/>    custom_url       = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_opsgenie_service_object_ids"></a> [opsgenie\_service\_object\_ids](#output\_opsgenie\_service\_object\_ids) | Map of Opsgenie service object IDs keyed by logical name. |
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
