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

<h3 align="center">Datadog Azure Integration</h3>
  <p align="center">
    This module manages Datadog - Microsoft Azure integrations. Each entry in the map registers one Azure subscription (app registration) with Datadog, enabling metrics, resource collection, Cloud Security Posture Management, and more.
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

- An Azure Active Directory app registration with the appropriate permissions (Monitoring Reader at the subscription level).
- The app registration's tenant ID, client ID, and client secret (or federated credential for secretless auth).
- Use `modules/azuread` to provision the Azure app registration before calling this module.

## Usage

### Client Secret Authentication

```hcl
module "datadog_azure" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/azure"

  azure_integrations = {
    prod_subscription = {
      tenant_name   = "my-tenant.onmicrosoft.com"
      client_id     = "<AZURE_APP_REGISTRATION_CLIENT_ID>"
      client_secret = "<AZURE_APP_REGISTRATION_CLIENT_SECRET>"
      automute      = true
      cspm_enabled  = true
      resource_collection_enabled = true
      host_filters  = "env:prod"
    }
  }
}
```

### Secretless (Federated) Authentication (Preview)

```hcl
module "datadog_azure_secretless" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/azure"

  azure_integrations = {
    prod_subscription_secretless = {
      tenant_name             = "my-tenant.onmicrosoft.com"
      client_id               = "<AZURE_APP_REGISTRATION_CLIENT_ID>"
      secretless_auth_enabled = true
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- `azure_integrations` contains a sensitive field (`client_secret`). The variable is not marked `sensitive = true` (doing so would prevent `for_each` on the resource), so callers should pass the client secret via an environment variable (`TF_VAR_azure_integrations`), Terraform Cloud/HCP sensitive variables, or a secrets manager integration rather than in plain-text `.tfvars` files.
- `secretless_auth_enabled` is a preview feature that uses federated workload identity credentials instead of a client secret. When `true`, omit `client_secret`. The app registration must have a Datadog federated credential configured. Defaults to `false`.
- `cspm_enabled` requires `resource_collection_enabled = true`.
- `resource_provider_configs` allows per-namespace metrics enablement overrides. Each entry's `namespace` corresponds to an Azure resource provider namespace (e.g., `Microsoft.Compute`).
- `host_filters`, `app_service_plan_filters`, and `container_app_filters` accept comma-separated `key:value` tag strings (e.g., `"env:prod,team:platform"`).

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
| [datadog_integration_azure.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_azure) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_azure_integrations"></a> [azure\_integrations](#input\_azure\_integrations) | Map of Azure integrations keyed by a logical name. Each entry creates one Datadog - Azure subscription integration. The client\_secret is sensitive. | <pre>map(object({<br/>    tenant_name                 = string<br/>    client_id                   = string<br/>    client_secret               = optional(string)<br/>    secretless_auth_enabled     = optional(bool, false)<br/>    automute                    = optional(bool, false)<br/>    cspm_enabled                = optional(bool, false)<br/>    custom_metrics_enabled      = optional(bool, false)<br/>    metrics_enabled             = optional(bool, true)<br/>    metrics_enabled_default     = optional(bool, true)<br/>    usage_metrics_enabled       = optional(bool, true)<br/>    resource_collection_enabled = optional(bool)<br/>    host_filters                = optional(string, "")<br/>    app_service_plan_filters    = optional(string, "")<br/>    container_app_filters       = optional(string, "")<br/>    resource_provider_configs = optional(list(object({<br/>      namespace       = optional(string)<br/>      metrics_enabled = optional(bool)<br/>    })))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_azure_integration_ids"></a> [azure\_integration\_ids](#output\_azure\_integration\_ids) | Map of Azure integration IDs keyed by logical name. |
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
