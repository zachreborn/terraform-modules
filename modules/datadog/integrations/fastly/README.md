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

<h3 align="center">Datadog Fastly Integration</h3>
  <p align="center">
    This module manages Datadog - Fastly account and service integrations. It registers Fastly accounts with Datadog (enabling Content Delivery Network metrics collection) and links individual Fastly services to those accounts.
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

- A Fastly account with an API key that has read access to the services you want to monitor.
- Fastly service IDs for each service you want to register.

## Usage

### Complete Example

```hcl
module "datadog_fastly" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/fastly"

  fastly_accounts = {
    main = {
      name    = "my-fastly-account"
      api_key = "<YOUR_FASTLY_API_KEY>"
    }
  }

  fastly_services = {
    cdn_prod = {
      service_id = "ABCDEF1234567890"
      account_id = "<FASTLY_ACCOUNT_ID_FROM_OUTPUT>"
      tags       = ["env:prod", "team:platform"]
    }
    cdn_staging = {
      service_id = "GHIJKL0987654321"
      account_id = "<FASTLY_ACCOUNT_ID_FROM_OUTPUT>"
      tags       = ["env:staging"]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- `fastly_accounts` contains a sensitive field (`api_key`). The variable is not marked `sensitive = true` (doing so would prevent `for_each` on the resource), so callers should pass the API key via an environment variable (`TF_VAR_fastly_accounts`), Terraform Cloud/HCP sensitive variables, or a secrets manager integration rather than in plain-text `.tfvars` files.
- Two API key mechanisms are supported: `api_key` (standard) and `api_key_wo` / `api_key_wo_version` (write-only, requires Terraform 1.11+). Exactly one of `api_key` or `api_key_wo` must be set per account entry.
- `fastly_services` are not sensitive — only the account's API key is sensitive.
- The `account_id` in `fastly_services` should reference the ID output from a `fastly_accounts` entry. Use `module.<name>.fastly_account_ids["<key>"]`.

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
| [datadog_integration_fastly_account.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_fastly_account) | resource |
| [datadog_integration_fastly_service.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_fastly_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_fastly_accounts"></a> [fastly\_accounts](#input\_fastly\_accounts) | Map of Fastly account integrations keyed by a logical name. Each entry registers one Fastly account with Datadog. The api\_key is sensitive. | <pre>map(object({<br/>    name               = string<br/>    api_key            = optional(string)<br/>    api_key_wo         = optional(string)<br/>    api_key_wo_version = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_fastly_services"></a> [fastly\_services](#input\_fastly\_services) | Map of Fastly service integrations keyed by a logical name. Each entry links one Fastly service to a registered Fastly account in Datadog. | <pre>map(object({<br/>    service_id = string<br/>    account_id = optional(string)<br/>    tags       = optional(set(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_fastly_account_ids"></a> [fastly\_account\_ids](#output\_fastly\_account\_ids) | Map of Fastly account integration IDs keyed by logical name. |
| <a name="output_fastly_service_ids"></a> [fastly\_service\_ids](#output\_fastly\_service\_ids) | Map of Fastly service integration IDs keyed by logical name. |
<!-- END_TF_DOCS -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Acknowledgments

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasarus)
- [Brad Engberg](https://github.com/bradms98)

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
