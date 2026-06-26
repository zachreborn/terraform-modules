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

<h3 align="center">Datadog RUM Retention Filter</h3>
  <p align="center">
    Manages Datadog RUM retention filters and their evaluation order via datadog_rum_retention_filter and datadog_rum_retention_filters_order.
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

This module manages [Datadog RUM retention filters](https://docs.datadoghq.com/real_user_monitoring/guide/rum-event-retention-filters/) using the `datadog_rum_retention_filter` resource, and optionally manages the evaluation order of all retention filters for a RUM application using the `datadog_rum_retention_filters_order` resource.

Retention filters control which RUM events are stored and at what sampling rate. Multiple filters can be managed from a single module invocation via the `retention_filters` map. The ordering resource (`datadog_rum_retention_filters_order`) is a singleton per RUM application and is opt-in via `enable_filter_order`.

## Prerequisites

- A Datadog account with RUM enabled.
- At least one RUM application (managed by the `modules/datadog/rum/application` module or created externally).
- The application ID(s) for the RUM application(s) to which filters belong.

## Usage

### Filters only

```hcl
module "rum_retention_filters" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/rum/retention_filter"

  retention_filters = {
    replay_sessions = {
      application_id = "<APPLICATION_ID>"
      name           = "Retain sessions with replay"
      event_type     = "session"
      sample_rate    = 100
      query          = "@session.has_replay:true"
      enabled        = true
    }
    error_actions = {
      application_id = "<APPLICATION_ID>"
      name           = "Retain error actions at 50%"
      event_type     = "action"
      sample_rate    = 50
      enabled        = true
    }
  }
}
```

### Filters with order management

```hcl
module "rum_retention_filters" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/rum/retention_filter"

  retention_filters = {
    high_value_sessions = {
      application_id = "<APPLICATION_ID>"
      name           = "High value sessions"
      event_type     = "session"
      sample_rate    = 100
      query          = "@session.has_replay:true"
      enabled        = true
    }
  }

  enable_filter_order         = true
  filter_order_application_id = "<APPLICATION_ID>"
  filter_order_ids = [
    "default-action",
    "default-error",
    module.rum_retention_filters.ids["high_value_sessions"],
  ]
}
```

## Notes / Design Decisions

- **`required_version = ">= 1.1.5"`**: The Datadog Terraform provider requires Terraform/OpenTofu 1.1.5 or later.
- **`datadog_rum_retention_filters_order` is a singleton**: Datadog maintains exactly one ordering resource per RUM application. Only one module instance per application should set `enable_filter_order = true`. Managing it from multiple module instances will cause conflicts.
- **Default filters**: Datadog automatically creates internal retention filters (with IDs prefixed by `"default"`) for each RUM application. When managing filter order, `filter_order_ids` must include these default filter IDs alongside any custom ones. Use the `datadog_rum_retention_filters` data source to discover the full list of current filter IDs before constructing the order list.
- **`sample_rate` range**: Must be between 0.1 and 100 (inclusive), supporting one decimal place.
- **`enabled` defaults to `true`**: Filters are active by default. Set `enabled = false` to create a filter in a disabled state.
- **`query` defaults to `""`**: An empty query matches all events of the specified type.

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.5 |
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
| [datadog_rum_retention_filter.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/rum_retention_filter) | resource |
| [datadog_rum_retention_filters_order.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/rum_retention_filters_order) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_enable_filter_order"></a> [enable\_filter\_order](#input\_enable\_filter\_order) | Whether to manage the retention filter order for a RUM application. When true, filter\_order\_application\_id and filter\_order\_ids must be provided. This is a singleton resource per application — only one module instance per application should set this to true. | `bool` | `false` | no |
| <a name="input_filter_order_application_id"></a> [filter\_order\_application\_id](#input\_filter\_order\_application\_id) | RUM application ID for the retention filter order resource. Required when enable\_filter\_order is true. | `string` | `null` | no |
| <a name="input_filter_order_ids"></a> [filter\_order\_ids](#input\_filter\_order\_ids) | Ordered list of all retention filter IDs for the application. Required when enable\_filter\_order is true. Must include all filter IDs for the application, including the default filters created internally by Datadog (those with IDs prefixed by 'default'). The order of IDs in this list defines the evaluation order of the filters. | `list(string)` | `[]` | no |
| <a name="input_retention_filters"></a> [retention\_filters](#input\_retention\_filters) | Map of RUM retention filters to create, keyed by a logical name. Each entry maps to one datadog\_rum\_retention\_filter resource. | <pre>map(object({<br/>    application_id = string<br/>    name           = string<br/>    event_type     = string<br/>    sample_rate    = number<br/>    enabled        = optional(bool, true)<br/>    query          = optional(string, "")<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_filter_order_id"></a> [filter\_order\_id](#output\_filter\_order\_id) | ID of the retention filters order resource. Only set when enable\_filter\_order is true. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of retention filter logical name to retention filter ID. |
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

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)

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
