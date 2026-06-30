<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
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

<h3 align="center">Datadog Custom Allocation Rule</h3>
  <p align="center">
    Manages Datadog custom cost allocation rules and their evaluation order.
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
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Description

Manages one or more `datadog_custom_allocation_rule` resources and optionally manages their evaluation order via a `datadog_custom_allocation_rules` resource. Custom allocation rules let you redistribute unallocated cloud costs to specific teams, projects, or other dimensions based on tag-based filters and allocation strategies. Multiple rules are managed via a single `map(object({...}))` input variable using `for_each`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- Datadog Cloud Cost Management must be enabled in your Datadog organization.
- At least one cloud cost integration must be configured and ingesting data.
- `rule_name` is **immutable** — changing a rule's name in Terraform will force destruction and re-creation of that resource.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

### Simple Allocation Rule

```hcl
module "allocation_rules" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost/custom_allocation_rule"

  allocation_rules = {
    ec2_to_teams = {
      rule_name     = "ec2-to-teams"
      enabled       = true
      providernames = ["aws"]

      costs_to_allocate = [
        {
          condition = "is"
          tag       = "aws_product"
          value     = "AmazonEC2"
        }
      ]

      strategy = {
        allocated_by_tag_keys = ["team"]
        method                = "even"
        granularity           = "daily"
      }
    }
  }
}
```

### Multiple Rules with Managed Evaluation Order

`rule_order` accepts the **logical rule names** (the keys of `allocation_rules`), which the
module resolves to rule IDs internally. Rule creation and ordering therefore live in a
single module call — no need to pass IDs back in.

```hcl
module "allocation_rules" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost/custom_allocation_rule"

  allocation_rules = {
    ec2_costs = {
      rule_name     = "allocate-ec2-costs"
      enabled       = true
      providernames = ["aws"]

      costs_to_allocate = [
        {
          condition = "is"
          tag       = "aws_product"
          value     = "AmazonEC2"
        }
      ]

      strategy = {
        allocated_by_tag_keys = ["team"]
        based_on_costs = [
          {
            condition = "is"
            tag       = "aws_product"
            value     = "AmazonEC2"
          }
        ]
        method      = "proportional"
        granularity = "daily"
      }
    }

    s3_costs = {
      rule_name     = "allocate-s3-costs"
      enabled       = true
      providernames = ["aws"]

      costs_to_allocate = [
        {
          condition = "is"
          tag       = "aws_product"
          value     = "AmazonS3"
        }
      ]

      strategy = {
        allocated_by_tag_keys = ["team"]
        method                = "even"
      }
    }
  }

  # Manage evaluation order by logical name — ec2_costs runs before s3_costs
  enable_rule_order = true
  rule_order        = ["ec2_costs", "s3_costs"]
}
```

> For a single YAML file that drives this module together with budgets, CUR, and CCM
> configs, see the parent module at
> `modules/datadog/cloud_cost`.

### Percentage-Based Allocation

```hcl
module "allocation_rules" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost/custom_allocation_rule"

  allocation_rules = {
    shared_infra = {
      rule_name     = "shared-infra-split"
      enabled       = true
      providernames = ["aws"]

      costs_to_allocate = [
        {
          condition = "is not"
          tag       = "team"
          value     = ""
        }
      ]

      strategy = {
        method = "percent"
        allocated_by = [
          {
            percentage = 0.60
            allocated_tags = [
              { key = "team", value = "backend" }
            ]
          },
          {
            percentage = 0.40
            allocated_tags = [
              { key = "team", value = "frontend" }
            ]
          }
        ]
      }
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **`required_version >= 1.3.0`**: The two-argument `optional(<type>, <default>)` form used in this module's variables requires Terraform or OpenTofu version 1.3.0 or later. This is a language constraint, not a provider constraint.
- **`rule_name` is immutable**: Changing `rule_name` on an existing rule forces Terraform to destroy and re-create the resource. Plan carefully before renaming rules in production.
- **Rule evaluation order**: The `datadog_custom_allocation_rules` ordering resource (enabled via `enable_rule_order = true`) controls the order in which rules are applied. `rule_order` is a list of **logical rule names** (keys of `allocation_rules`); the module resolves them to rule IDs internally from the sibling rule resources, so creation and ordering happen in one module call with no dependency cycle. Without this resource, Datadog determines order automatically.
- **`override_ui_defined_resources`**: When `false` (default), Datadog-UI-created rules that appear at the end of the order are preserved. When `true`, Terraform becomes the sole source of truth and any UI-created rules are deleted.
- **`based_on_timeseries`**: An empty block that signals the strategy should use a time-series metric as the allocation basis. Set `based_on_timeseries = true` in the strategy object to render it.
- **`allocation_rules` defaults to `{}`**: The module can be instantiated with no rules by providing an empty map. Every name listed in `rule_order` must exist as a key in `allocation_rules`.
- **Valid `providernames` values**: `aws`, `azure`, `gcp`.
- **Valid `strategy.granularity` values**: `daily`, `monthly`.
- **Valid `strategy.method` values**: `even`, `proportional`, `proportional_timeseries`, `percent`.
- **Valid filter `condition` values**: `=`, `!=`, `is`, `is not`, `like`, `in`, `not in`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

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
| [datadog_custom_allocation_rule.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/custom_allocation_rule) | resource |
| [datadog_custom_allocation_rules.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/custom_allocation_rules) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allocation_rules"></a> [allocation\_rules](#input\_allocation\_rules) | Map of custom allocation rules to create. Each key is a logical name. Note: rule\_name is immutable — changing it forces resource replacement. | <pre>map(object({<br/>    rule_name     = string<br/>    enabled       = bool<br/>    providernames = list(string)<br/>    costs_to_allocate = optional(list(object({<br/>      condition = optional(string, null)<br/>      tag       = optional(string, null)<br/>      value     = optional(string, null)<br/>      values    = optional(list(string), null)<br/>    })), [])<br/>    strategy = optional(object({<br/>      allocated_by_tag_keys        = optional(list(string), null)<br/>      evaluate_grouped_by_tag_keys = optional(list(string), null)<br/>      granularity                  = optional(string, null)<br/>      method                       = optional(string, null)<br/>      allocated_by = optional(list(object({<br/>        percentage = optional(number, null)<br/>        allocated_tags = optional(list(object({<br/>          key   = optional(string, null)<br/>          value = optional(string, null)<br/>        })), [])<br/>      })), [])<br/>      allocated_by_filters = optional(list(object({<br/>        condition = optional(string, null)<br/>        tag       = optional(string, null)<br/>        value     = optional(string, null)<br/>        values    = optional(list(string), null)<br/>      })), [])<br/>      based_on_costs = optional(list(object({<br/>        condition = optional(string, null)<br/>        tag       = optional(string, null)<br/>        value     = optional(string, null)<br/>        values    = optional(list(string), null)<br/>      })), [])<br/>      based_on_timeseries = optional(bool, null)<br/>      evaluate_grouped_by_filters = optional(list(object({<br/>        condition = optional(string, null)<br/>        tag       = optional(string, null)<br/>        value     = optional(string, null)<br/>        values    = optional(list(string), null)<br/>      })), [])<br/>    }), null)<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_rule_order"></a> [enable\_rule\_order](#input\_enable\_rule\_order) | Whether to manage the evaluation order of custom allocation rules via the datadog\_custom\_allocation\_rules resource. Set to true to enable rule order management. | `bool` | `false` | no |
| <a name="input_override_ui_defined_resources"></a> [override\_ui\_defined\_resources](#input\_override\_ui\_defined\_resources) | Whether to override rules created via the Datadog UI. When true, UI-defined rules not present in rule\_order will be deleted and Terraform becomes the sole source of truth. When false, UI rules appended to the end of the order are preserved (rules inserted in the middle cause a plan-time error). Default is false. | `bool` | `false` | no |
| <a name="input_rule_order"></a> [rule\_order](#input\_rule\_order) | Ordered list of logical rule names (keys of var.allocation\_rules) that determines their evaluation sequence. Used when enable\_rule\_order is true. Names are resolved to rule IDs internally, so callers reference rules by their map key rather than passing IDs back in. Every name listed must exist in var.allocation\_rules. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_created"></a> [created](#output\_created) | Map of logical names to the timestamps (ISO 8601) when the custom allocation rules were created. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of logical names to the IDs of the custom allocation rules. |
| <a name="output_last_modified_user_uuids"></a> [last\_modified\_user\_uuids](#output\_last\_modified\_user\_uuids) | Map of logical names to the UUIDs of the users who last modified each custom allocation rule. |
| <a name="output_order_ids"></a> [order\_ids](#output\_order\_ids) | Map of logical names to the order IDs of the custom allocation rules. Use the datadog\_custom\_allocation\_rules resource (via enable\_rule\_order) to control evaluation order. |
| <a name="output_rejected"></a> [rejected](#output\_rejected) | Map of logical names to whether each custom allocation rule was rejected by the Datadog API during creation due to validation errors. |
| <a name="output_rule_order_id"></a> [rule\_order\_id](#output\_rule\_order\_id) | The ID of the custom allocation rules ordering resource. Only set when enable\_rule\_order is true. |
| <a name="output_updated"></a> [updated](#output\_updated) | Map of logical names to the timestamps (ISO 8601) when the custom allocation rules were last updated. |
| <a name="output_versions"></a> [versions](#output\_versions) | Map of logical names to the version numbers of the custom allocation rules. Increments on each update. |
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
