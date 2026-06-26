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

<h3 align="center">Datadog Cost Budget</h3>
  <p align="center">
    Manages Datadog cost budgets for tracking and alerting on cloud spending.
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

Manages one or more `datadog_cost_budget` resources. Each budget defines a monthly spending target tracked against a Datadog cost metrics query, with optional tag-based budget lines for per-dimension breakdowns. Multiple budgets are managed via a single `map(object({...}))` input variable using `for_each`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- Datadog Cloud Cost Management must be enabled in your Datadog organization.
- At least one cloud cost integration (AWS, Azure, or GCP) must be configured and ingesting data before budgets can track meaningful metrics.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

### Simple Budget (no tag breakdown)

```hcl
module "budgets" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost/budget"

  budgets = {
    aws_total = {
      name          = "Total AWS Budget"
      metrics_query = "sum:aws.cost.amortized{*}"
      start_month   = 202601
      end_month     = 202612

      budget_lines = [
        {
          amounts = {
            "202601" = 10000
            "202602" = 10000
            "202603" = 10000
            "202604" = 10000
            "202605" = 10000
            "202606" = 10000
            "202607" = 10000
            "202608" = 10000
            "202609" = 10000
            "202610" = 10000
            "202611" = 10000
            "202612" = 10000
          }
        }
      ]
    }
  }
}
```

### Budget with Tag Filters (per-environment breakdown)

```hcl
module "budgets" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost/budget"

  budgets = {
    env_breakdown = {
      name          = "Multi-Environment AWS Budget"
      metrics_query = "sum:aws.cost.amortized{*} by {environment}"
      start_month   = 202601
      end_month     = 202603

      budget_lines = [
        {
          amounts = {
            "202601" = 8000
            "202602" = 8000
            "202603" = 8000
          }
          tag_filters = [
            {
              tag_key   = "environment"
              tag_value = "production"
            }
          ]
        },
        {
          amounts = {
            "202601" = 2000
            "202602" = 2000
            "202603" = 2000
          }
          tag_filters = [
            {
              tag_key   = "environment"
              tag_value = "staging"
            }
          ]
        }
      ]
    }
  }
}
```

### Hierarchical Budget (parent/child tag structure)

```hcl
module "budgets" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost/budget"

  budgets = {
    team_env = {
      name          = "Team-Environment Hierarchical Budget"
      # Order of tags in "by {tag1,tag2}" determines hierarchy: tag1=parent, tag2=child
      metrics_query = "sum:aws.cost.amortized{*} by {team,environment}"
      start_month   = 202601
      end_month     = 202603

      budget_lines = [
        {
          amounts = {
            "202601" = 5000
            "202602" = 5500
            "202603" = 5000
          }
          parent_tag_filters = [
            { tag_key = "team", tag_value = "backend" }
          ]
          child_tag_filters = [
            { tag_key = "environment", tag_value = "production" }
          ]
        }
      ]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **`required_version >= 1.3.0`**: The two-argument `optional(<type>, <default>)` form used in this module's variables requires Terraform or OpenTofu version 1.3.0 or later. This is a language constraint, not a provider constraint.
- **`budget_lines` vs `entries`**: The `budget_lines` block is the current, preferred schema. The `entries` block is **deprecated** and included for backward compatibility only. Use `budget_lines` for all new budgets.
- **Hierarchical budgets**: Use `parent_tag_filters` + `child_tag_filters` together (never with `tag_filters`). The order of tags in the `metrics_query` (e.g., `by {team,environment}`) determines the parent/child hierarchy in the Datadog UI.
- **`tag_filters` mutual exclusivity**: `tag_filters` cannot be used in the same `budget_line` as `parent_tag_filters` or `child_tag_filters`.
- **`amounts` map key format**: Keys in the `amounts` map must be YYYYMM strings (e.g., `"202601"`), not integers. The corresponding months must fall within the `start_month`–`end_month` range.
- **`total_amount` is read-only**: Surfaced as an output for reference; it is computed by Datadog as the sum of all budget amounts.

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
| [datadog_cost_budget.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/cost_budget) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_budgets"></a> [budgets](#input\_budgets) | Map of cost budgets to create. Each key is a logical name for the budget. Prefer budget\_lines over entries (entries is deprecated). | <pre>map(object({<br/>    name          = string<br/>    metrics_query = string<br/>    start_month   = number<br/>    end_month     = number<br/>    budget_lines = optional(list(object({<br/>      amounts = map(number)<br/>      tag_filters = optional(list(object({<br/>        tag_key   = string<br/>        tag_value = string<br/>      })), [])<br/>      parent_tag_filters = optional(list(object({<br/>        tag_key   = string<br/>        tag_value = string<br/>      })), [])<br/>      child_tag_filters = optional(list(object({<br/>        tag_key   = string<br/>        tag_value = string<br/>      })), [])<br/>    })), [])<br/>    entries = optional(list(object({<br/>      month  = number<br/>      amount = number<br/>      tag_filters = optional(list(object({<br/>        tag_key   = string<br/>        tag_value = string<br/>      })), [])<br/>    })), [])<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of logical names to the IDs of the cost budgets. |
| <a name="output_total_amounts"></a> [total\_amounts](#output\_total\_amounts) | Map of logical names to the total amount (sum of all budget entries) for each budget. |
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
