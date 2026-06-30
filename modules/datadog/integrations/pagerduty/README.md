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

<h3 align="center">Datadog PagerDuty Integration</h3>
  <p align="center">
    This module manages the Datadog - PagerDuty integration. It provisions the top-level integration (subdomain + schedules) and any number of per-service objects that link individual PagerDuty services to Datadog monitors.
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

- A PagerDuty account with an API token.
- Service integration keys for each PagerDuty service you want to connect to Datadog.
- The PagerDuty integration must be activated in the Datadog UI before service objects can be managed via Terraform.

## Usage

### Complete Example

```hcl
module "datadog_pagerduty" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/pagerduty"

  pagerduty_integrations = {
    main = {
      subdomain = "mycompany"
      api_token = "<YOUR_PAGERDUTY_API_TOKEN>"
      schedules = [
        "https://mycompany.pagerduty.com/schedules/ABCDEF"
      ]
    }
  }

  service_objects = {
    platform_svc = {
      service_name = "platform-service"
      service_key  = "<YOUR_PAGERDUTY_INTEGRATION_KEY>"
    }
    payments_svc = {
      service_name = "payments-service"
      service_key  = "<YOUR_PAGERDUTY_INTEGRATION_KEY>"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- The `datadog_integration_pagerduty` resource is a singleton per Datadog org — typically only one entry in `pagerduty_integrations`. Use the map pattern for consistency with the rest of the module library.
- Service objects (`service_objects`) must be created after the integration (`pagerduty_integrations`). The provider handles ordering internally when both are in the same module, but if you create them in separate module calls, ensure the integration is applied first.
- Both `pagerduty_integrations` (`api_token`) and `service_objects` (`service_key`) contain sensitive fields. Neither variable is marked `sensitive = true` (doing so would prevent `for_each` on their resources), so callers should pass these values via environment variables, Terraform Cloud/HCP sensitive variables, or a secrets manager rather than in plain-text `.tfvars` files.
- The Datadog API never returns service keys after creation, so drift cannot be detected by Terraform. Taint the service object resource to recreate it if the key changes.

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
| [datadog_integration_pagerduty.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_pagerduty) | resource |
| [datadog_integration_pagerduty_service_object.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_pagerduty_service_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_pagerduty_integrations"></a> [pagerduty\_integrations](#input\_pagerduty\_integrations) | Map of PagerDuty integrations keyed by a logical name. Typically a single entry per Datadog org. Contains the api\_token which is sensitive. | <pre>map(object({<br/>    subdomain = string<br/>    api_token = optional(string)<br/>    schedules = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_service_objects"></a> [service\_objects](#input\_service\_objects) | Map of PagerDuty service objects keyed by a logical name. Each entry links one PagerDuty service to Datadog. The service\_key is sensitive. | <pre>map(object({<br/>    service_name = string<br/>    service_key  = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_pagerduty_integration_ids"></a> [pagerduty\_integration\_ids](#output\_pagerduty\_integration\_ids) | Map of PagerDuty integration IDs keyed by logical name. |
| <a name="output_service_object_ids"></a> [service\_object\_ids](#output\_service\_object\_ids) | Map of PagerDuty service object IDs keyed by logical name. |
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
