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

<h3 align="center">Datadog RUM Application</h3>
  <p align="center">
    Manages Datadog Real User Monitoring (RUM) applications via the datadog_rum_application resource.
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
    <li><a href="#resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Description

This module manages [Datadog RUM applications](https://docs.datadoghq.com/real_user_monitoring/) using the `datadog_rum_application` resource. It supports creating and managing multiple RUM applications via a single `map(object)` input, enabling scalable management of browser, iOS, Android, React Native, and Flutter applications.

The `client_token` output is marked sensitive and must be embedded in your application's SDK initialization code. It is never logged by Terraform.

## Prerequisites

- A Datadog account with RUM enabled.
- Datadog provider configured with a valid API key and application key that has RUM write permissions.

## Usage

### Simple Example

```hcl
module "rum_applications" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/rum/application"

  applications = {
    web_frontend = {
      name                              = "web-frontend"
      type                              = "browser"
      rum_event_processing_state        = "ALL"
      product_analytics_retention_state = "MAX"
    }
    mobile_ios = {
      name = "mobile-ios"
      type = "ios"
    }
  }
}

output "web_client_token" {
  value     = module.rum_applications.client_tokens["web_frontend"]
  sensitive = true
}
```

## Notes / Design Decisions

- **`required_version = ">= 1.3.0"`**: The Datadog Terraform provider requires Terraform/OpenTofu 1.1.5+, but this module uses `optional(type, default)` in variable type constraints, which requires Terraform/OpenTofu 1.3.0 or later.
- **`client_token` is sensitive**: The client token is embedded in client-side SDK initialization. All `client_token` values are grouped under the `client_tokens` output which is marked `sensitive = true`. Reference it via `nonsensitive()` only in contexts where exposure is intentional.
- **`type` defaults to `"browser"`**: Matches the provider default. Override for mobile or cross-platform applications.
- **`rum_event_processing_state` and `product_analytics_retention_state`**: Both default to `null`, which causes the provider to use its own defaults. Set them explicitly to control event processing and retention behavior.
- **Validation**: The module validates `type`, `rum_event_processing_state`, and `product_analytics_retention_state` against their allowed values before any Terraform API call is made.

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
| [datadog_rum_application.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/rum_application) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_applications"></a> [applications](#input\_applications) | Map of RUM applications to create, keyed by a logical name. Each entry maps to one datadog\_rum\_application resource. | <pre>map(object({<br/>    name                              = string<br/>    type                              = optional(string, "browser")<br/>    rum_event_processing_state        = optional(string, null)<br/>    product_analytics_retention_state = optional(string, null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_api_key_ids"></a> [api\_key\_ids](#output\_api\_key\_ids) | Map of application logical name to the ID of the API key associated with the application. |
| <a name="output_client_tokens"></a> [client\_tokens](#output\_client\_tokens) | Map of application logical name to client token. Sensitive — do not log. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of application logical name to RUM application ID. |
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
- [Jake Jones](https://github.com/jakeasarus)
- [Brad Engberg](https://github.com/bradms98)

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
