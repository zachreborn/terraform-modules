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

<h3 align="center">Datadog AWS EventBridge Integration</h3>
  <p align="center">
    This module manages Datadog - Amazon Web Services EventBridge event sources. Each entry in the map creates one EventBridge event source (and optionally an event bus) for a given AWS account and region.
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

- An existing Datadog - AWS account integration. Use `modules/datadog/integrations/aws` to provision it.
- The IAM role or access keys used by the integration must include the `events:CreateEventBus` permission if `create_event_bus = true`.

## Usage

### Simple Example

```hcl
module "datadog_aws_eventbridge" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/integrations/aws_event_bridge"

  event_bridges = {
    prod_us_east_1 = {
      account_id           = "123456789012"
      event_generator_name = "app-alerts"
      region               = "us-east-1"
      create_event_bus     = true
    }
    prod_eu_west_1 = {
      account_id           = "123456789012"
      event_generator_name = "app-alerts"
      region               = "eu-west-1"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `required_version = ">= 1.3.0"` — uses `optional()` with defaults inside object types, which requires Terraform/OpenTofu 1.3.0+. The Datadog provider itself mandates >= 1.1.5.
- `create_event_bus` defaults to `true`. Datadog creates the EventBridge event bus alongside the event source. Set to `false` if you manage the event bus separately.
- The `event_generator_name` combined with a Datadog-assigned suffix forms the full event source name visible in the AWS console.

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
| [datadog_integration_aws_event_bridge.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_aws_event_bridge) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_event_bridges"></a> [event\_bridges](#input\_event\_bridges) | Map of AWS EventBridge integrations keyed by a logical name. Each entry creates one Datadog - AWS EventBridge event source. | <pre>map(object({<br/>    account_id           = string<br/>    event_generator_name = string<br/>    region               = string<br/>    create_event_bus     = optional(bool, true)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_event_bridge_ids"></a> [event\_bridge\_ids](#output\_event\_bridge\_ids) | Map of EventBridge integration IDs keyed by logical name. |
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
