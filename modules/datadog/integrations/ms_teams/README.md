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

<h3 align="center">Datadog Microsoft Teams Integration</h3>
  <p align="center">
    This module manages Datadog - Microsoft Teams integration handles. It supports both tenant-based handles (for the native Teams integration) and Microsoft Workflows webhook handles (for Power Automate Workflows-based notifications).
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

- **Tenant-based handles**: The Microsoft Teams integration must be activated in the Datadog UI. The tenant, team, and channel names must exist in the connected Microsoft 365 tenant.
- **Workflows webhook handles**: A Microsoft Power Automate workflow must be configured with an HTTP trigger to produce the webhook URL.

## Usage

### Tenant-based Handle Example

```hcl
module "datadog_ms_teams" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/ms_teams"

  tenant_based_handles = {
    platform_alerts = {
      name         = "platform-alerts"
      tenant_name  = "my-tenant"
      team_name    = "Platform Engineering"
      channel_name = "Alerts"
    }
  }
}
```

### Workflows Webhook Handle Example

```hcl
module "datadog_ms_teams_webhooks" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/ms_teams"

  workflows_webhook_handles = {
    incidents = {
      name = "incidents-webhook"
      url  = "<YOUR_POWER_AUTOMATE_WEBHOOK_URL>"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- **Two resource types are managed**: `tenant_based_handles` uses the native Teams integration (requires the Teams app to be installed in Datadog), while `workflows_webhook_handles` uses Microsoft Power Automate workflows and does not require a native Teams-Datadog connection.
- `workflows_webhook_handles` contains a sensitive field (`url`, which embeds a secret token). The variable is not marked `sensitive = true` (doing so would prevent `for_each` on the resource), so callers should pass webhook URLs via an environment variable (`TF_VAR_workflows_webhook_handles`), Terraform Cloud/HCP sensitive variables, or a secrets manager integration rather than in plain-text `.tfvars` files.
- Both maps default to empty, so the module can be used for either or both handle types independently.

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
| [datadog_integration_ms_teams_tenant_based_handle.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_ms_teams_tenant_based_handle) | resource |
| [datadog_integration_ms_teams_workflows_webhook_handle.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_ms_teams_workflows_webhook_handle) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_tenant_based_handles"></a> [tenant\_based\_handles](#input\_tenant\_based\_handles) | Map of Microsoft Teams tenant-based handles keyed by a logical name. Each entry creates one tenant-based notification handle for use in Datadog monitors and alerts. | <pre>map(object({<br/>    name         = string<br/>    tenant_name  = string<br/>    team_name    = string<br/>    channel_name = string<br/>  }))</pre> | `{}` | no |
| <a name="input_workflows_webhook_handles"></a> [workflows\_webhook\_handles](#input\_workflows\_webhook\_handles) | Map of Microsoft Teams Workflows webhook handles keyed by a logical name. Each entry creates one Microsoft Workflows webhook handle. The url is sensitive. | <pre>map(object({<br/>    name = string<br/>    url  = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_tenant_based_handle_ids"></a> [tenant\_based\_handle\_ids](#output\_tenant\_based\_handle\_ids) | Map of Microsoft Teams tenant-based handle IDs keyed by logical name. |
| <a name="output_workflows_webhook_handle_ids"></a> [workflows\_webhook\_handle\_ids](#output\_workflows\_webhook\_handle\_ids) | Map of Microsoft Teams Workflows webhook handle IDs keyed by logical name. |
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
