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

<h3 align="center">Datadog Cloudflare Integration</h3>
  <p align="center">
    This module manages Datadog - Cloudflare account integrations. Each entry in the map registers one Cloudflare account with Datadog, enabling collection of Cloudflare DNS, load balancer, web, and worker metrics.
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

- A Cloudflare API key or API token. If using an API key (not a token), the `email` field is also required.
- The Cloudflare account must be accessible from the key/token provided.

## Usage

### Simple Example

```hcl
module "datadog_cloudflare" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/cloudflare"

  cloudflare_accounts = {
    primary = {
      api_key   = "<YOUR_CLOUDFLARE_API_KEY_OR_TOKEN>"
      name      = "my-cloudflare-account"
      email     = "admin@example.com"
      resources = ["web", "dns", "lb"]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- `cloudflare_accounts` contains a sensitive field (`api_key`). The variable is not marked `sensitive = true` (doing so would prevent `for_each` on the resource), so callers should pass the API key via an environment variable (`TF_VAR_cloudflare_accounts`), Terraform Cloud/HCP sensitive variables, or a secrets manager integration rather than in plain-text `.tfvars` files.
- Valid `resources` values are: `web`, `dns`, `lb` (load balancer), `worker`. Omit to collect all available metric types.
- When using an API key (not a token), `email` is required. API tokens do not require the `email` field.

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
| [datadog_integration_cloudflare_account.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_cloudflare_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cloudflare_accounts"></a> [cloudflare\_accounts](#input\_cloudflare\_accounts) | Map of Cloudflare account integrations keyed by a logical name. The api\_key field is sensitive — pass it via an environment variable (TF\_VAR\_cloudflare\_accounts), Terraform Cloud/HCP sensitive variables, or a secrets manager rather than in plain-text .tfvars files. | <pre>map(object({<br/>    api_key   = string<br/>    name      = string<br/>    email     = optional(string)<br/>    resources = optional(set(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloudflare_account_ids"></a> [cloudflare\_account\_ids](#output\_cloudflare\_account\_ids) | Map of Cloudflare integration IDs keyed by logical name. |
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
