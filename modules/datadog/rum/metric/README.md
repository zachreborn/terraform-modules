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

<h3 align="center">Datadog RUM Metric</h3>
  <p align="center">
    Manages Datadog Real User Monitoring (RUM) metrics via the datadog_rum_metric resource.
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

This module manages [Datadog RUM-based metrics](https://docs.datadoghq.com/real_user_monitoring/generate_metrics/) using the `datadog_rum_metric` resource. RUM-based metrics let you generate custom metrics from RUM events for use in monitors, dashboards, and SLOs.

Multiple metrics can be managed from a single module invocation using the `metrics` map input. Each metric supports optional `compute`, `filter`, `group_by`, and `uniqueness` nested configuration blocks, rendered via `dynamic` blocks.

## Prerequisites

- A Datadog account with RUM enabled.
- Datadog provider configured with a valid API key and application key that has RUM metrics write permissions.

## Usage

### Simple Example

```hcl
module "rum_metrics" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/rum/metric"

  metrics = {
    session_duration = {
      name       = "rum.session.duration"
      event_type = "session"
      compute = {
        aggregation_type    = "distribution"
        include_percentiles = true
        path                = "@duration"
      }
      filter = {
        query = "@service:web-ui"
      }
      group_by = [
        {
          path     = "@browser.name"
          tag_name = "browser_name"
        }
      ]
      uniqueness = {
        when = "match"
      }
    }
    action_count = {
      name       = "rum.action.count"
      event_type = "action"
      compute = {
        aggregation_type = "count"
      }
    }
  }
}
```

## Notes / Design Decisions

- **`required_version = ">= 1.3.0"`**: The Datadog Terraform provider requires Terraform/OpenTofu 1.1.5+, but this module uses `optional(type, default)` in variable type constraints, which requires Terraform/OpenTofu 1.3.0 or later.
- **`name` is immutable**: The `name` field on `datadog_rum_metric` cannot be changed after creation. Renaming a metric requires destroying and recreating it.
- **`compute.aggregation_type`**: Required when the `compute` block is specified. Use `"distribution"` for percentile metrics (which also unlocks `include_percentiles` and `path`).
- **`group_by` is a list**: Multiple grouping dimensions can be specified as a list of objects.
- **`uniqueness.when`**: Valid values are `"match"` (count on first seen) and `"end"` (count when event completes). Only relevant for updatable event types such as sessions and views.
- **All nested blocks are optional**: Omitting `compute`, `filter`, `group_by`, or `uniqueness` causes the provider to use its own defaults for those configurations.

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
| [datadog_rum_metric.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/rum_metric) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_metrics"></a> [metrics](#input\_metrics) | Map of RUM-based metrics to create, keyed by a logical name. Each entry maps to one datadog\_rum\_metric resource. | <pre>map(object({<br/>    name       = string<br/>    event_type = string<br/>    compute = optional(object({<br/>      aggregation_type    = string<br/>      include_percentiles = optional(bool, null)<br/>      path                = optional(string, null)<br/>    }), null)<br/>    filter = optional(object({<br/>      query = optional(string, null)<br/>    }), null)<br/>    group_by = optional(list(object({<br/>      path     = optional(string, null)<br/>      tag_name = optional(string, null)<br/>    })), null)<br/>    uniqueness = optional(object({<br/>      when = optional(string, null)<br/>    }), null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of metric logical name to RUM metric ID. |
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
- [Jake Jones](https://github.com/jakeasaurus)
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
