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

<h3 align="center">Datadog Cloud Cost Management</h3>
  <p align="center">
    A single, YAML-driven module that manages all Datadog Cloud Cost Management resources by composing the cloud_cost submodules.
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

This is the top-level Datadog Cloud Cost Management (CCM) module. It composes the four `cloud_cost` submodules behind a single `config` object, so an entire cloud-cost footprint can be driven from one YAML file:

- `aws_cur_config` — `datadog_aws_cur_config` (AWS Cost and Usage Report integration)
- `aws_ccm_config` — `datadog_integration_aws_account_ccm_config` (CCM config linked to an AWS integration)
- `budget` — `datadog_cost_budget` (cost budgets)
- `custom_allocation_rule` — `datadog_custom_allocation_rule` + `datadog_custom_allocation_rules` (allocation rules and their evaluation order)

Each submodule remains independently usable; this module simply wires them together and re-exposes their outputs under a namespaced prefix. The submodules are not Terraform-coupled to one another — they are grouped here for a single operational control surface.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- Datadog Cloud Cost Management must be enabled in your Datadog organization.
- An active Datadog AWS integration (see `modules/datadog/integrations/aws`). The `ccm_configs[*].aws_account_config_id` value is the Datadog-internal UUID exposed as the `id` of the `datadog_integration_aws_account` resource — **not** the 12-digit AWS account ID.
- For `aws_cur_configs`: an existing AWS Cost and Usage Report and an S3 bucket with Datadog read permissions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

### YAML-driven (recommended)

Put your configuration in a single YAML file (see `cloud_cost.example.yaml` in this module for a full example) and decode it at the call site:

```hcl
module "cloud_cost" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost"

  config = yamldecode(file("${path.module}/cloud_cost.yaml"))
}
```

### Inline HCL

The `config` object can also be supplied inline. Every section is optional:

```hcl
module "cloud_cost" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost"

  config = {
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
            }
          }
        ]
      }
    }

    allocation_rules = {
      ec2_costs = {
        rule_name     = "allocate-ec2-costs"
        enabled       = true
        providernames = ["aws"]
        costs_to_allocate = [
          { condition = "is", tag = "aws_product", value = "AmazonEC2" }
        ]
        strategy = {
          allocated_by_tag_keys = ["team"]
          method                = "even"
        }
      }
    }

    enable_rule_order = true
    rule_order        = ["ec2_costs"]
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **Composition over inlining**: this module declares no resources of its own; it calls the four `cloud_cost` submodules. This follows the repository's module-composition rule (cross-cutting resources live in their own focused submodules) and keeps each submodule independently reusable.
- **Single `config` object**: all four submodule inputs are aggregated into one typed `config` variable so the whole footprint can come from one `yamldecode(file(...))`. The typed schema preserves each submodule's `optional()` defaults, so YAML files only need the fields they use.
- **Rule ordering by logical name**: `config.rule_order` is a list of allocation-rule **names** (the keys of `config.allocation_rules`). The `custom_allocation_rule` submodule resolves them to IDs internally, so there is no self-referential dependency cycle and no need for a second module instance. Every name in `rule_order` must exist in `allocation_rules`.
- **`required_version >= 1.3.0`**: the two-argument `optional(<type>, <default>)` form used in the `config` schema requires Terraform or OpenTofu 1.3.0 or later.
- **`datadog >= 4.11.0`**: this module transitively manages `datadog_integration_aws_account_ccm_config`, which was introduced in provider v4.11.0, so the aggregate floor is 4.11.0 even though the other three resources predate it.
- **Namespaced outputs**: submodule outputs are re-exposed with a prefix (e.g. `budget_ids`, `allocation_rule_ids`, `aws_cur_config_statuses`) to avoid collisions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_datadog"></a> [datadog](#requirement\_datadog) | >= 4.11.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_aws_ccm_config"></a> [aws\_ccm\_config](#module\_aws\_ccm\_config) | ./aws_ccm_config | n/a |
| <a name="module_aws_cur_config"></a> [aws\_cur\_config](#module\_aws\_cur\_config) | ./aws_cur_config | n/a |
| <a name="module_budget"></a> [budget](#module\_budget) | ./budget | n/a |
| <a name="module_custom_allocation_rule"></a> [custom\_allocation\_rule](#module\_custom\_allocation\_rule) | ./custom_allocation_rule | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_config"></a> [config](#input\_config) | Single aggregated configuration object for all Datadog Cloud Cost Management resources.<br/>Intended to be populated from one YAML file via `config = yamldecode(file("cloud_cost.yaml"))`.<br/>Each top-level key maps to one of the underlying submodules:<br/>  - aws\_cur\_configs  -> AWS Cost and Usage Report configurations<br/>  - ccm\_configs      -> Cloud Cost Management configs linked to AWS integrations<br/>  - budgets          -> Cost budgets<br/>  - allocation\_rules -> Custom allocation rules<br/>Rule evaluation order is controlled by enable\_rule\_order + rule\_order (a list of logical<br/>rule names that are resolved to IDs internally). | <pre>object({<br/>    # AWS CUR configurations -> datadog_aws_cur_config<br/>    aws_cur_configs = optional(map(object({<br/>      account_id    = string<br/>      bucket_name   = string<br/>      report_name   = string<br/>      report_prefix = string<br/>      bucket_region = optional(string, null)<br/>      account_filters = optional(object({<br/>        include_new_accounts = optional(bool, null)<br/>        excluded_accounts    = optional(list(string), null)<br/>        included_accounts    = optional(list(string), null)<br/>      }), null)<br/>    })), {})<br/><br/>    # Cloud Cost Management configs -> datadog_integration_aws_account_ccm_config<br/>    ccm_configs = optional(map(object({<br/>      aws_account_config_id = string<br/>      ccm_config = optional(object({<br/>        data_export_configs = optional(list(object({<br/>          bucket_name   = optional(string, null)<br/>          bucket_region = optional(string, null)<br/>          report_name   = optional(string, null)<br/>          report_prefix = optional(string, null)<br/>          report_type   = optional(string, null)<br/>        })), null)<br/>      }), null)<br/>    })), {})<br/><br/>    # Cost budgets -> datadog_cost_budget<br/>    budgets = optional(map(object({<br/>      name          = string<br/>      metrics_query = string<br/>      start_month   = number<br/>      end_month     = number<br/>      budget_lines = optional(list(object({<br/>        amounts = map(number)<br/>        tag_filters = optional(list(object({<br/>          tag_key   = string<br/>          tag_value = string<br/>        })), [])<br/>        parent_tag_filters = optional(list(object({<br/>          tag_key   = string<br/>          tag_value = string<br/>        })), [])<br/>        child_tag_filters = optional(list(object({<br/>          tag_key   = string<br/>          tag_value = string<br/>        })), [])<br/>      })), [])<br/>      entries = optional(list(object({<br/>        month  = number<br/>        amount = number<br/>        tag_filters = optional(list(object({<br/>          tag_key   = string<br/>          tag_value = string<br/>        })), [])<br/>      })), [])<br/>    })), {})<br/><br/>    # Custom allocation rules -> datadog_custom_allocation_rule<br/>    allocation_rules = optional(map(object({<br/>      rule_name     = string<br/>      enabled       = bool<br/>      providernames = list(string)<br/>      costs_to_allocate = optional(list(object({<br/>        condition = optional(string, null)<br/>        tag       = optional(string, null)<br/>        value     = optional(string, null)<br/>        values    = optional(list(string), null)<br/>      })), [])<br/>      strategy = optional(object({<br/>        allocated_by_tag_keys        = optional(list(string), null)<br/>        evaluate_grouped_by_tag_keys = optional(list(string), null)<br/>        granularity                  = optional(string, null)<br/>        method                       = optional(string, null)<br/>        allocated_by = optional(list(object({<br/>          percentage = optional(number, null)<br/>          allocated_tags = optional(list(object({<br/>            key   = optional(string, null)<br/>            value = optional(string, null)<br/>          })), [])<br/>        })), [])<br/>        allocated_by_filters = optional(list(object({<br/>          condition = optional(string, null)<br/>          tag       = optional(string, null)<br/>          value     = optional(string, null)<br/>          values    = optional(list(string), null)<br/>        })), [])<br/>        based_on_costs = optional(list(object({<br/>          condition = optional(string, null)<br/>          tag       = optional(string, null)<br/>          value     = optional(string, null)<br/>          values    = optional(list(string), null)<br/>        })), [])<br/>        based_on_timeseries = optional(bool, null)<br/>        evaluate_grouped_by_filters = optional(list(object({<br/>          condition = optional(string, null)<br/>          tag       = optional(string, null)<br/>          value     = optional(string, null)<br/>          values    = optional(list(string), null)<br/>        })), [])<br/>      }), null)<br/>    })), {})<br/><br/>    # Custom allocation rule evaluation order<br/>    enable_rule_order             = optional(bool, false)<br/>    rule_order                    = optional(list(string), [])<br/>    override_ui_defined_resources = optional(bool, false)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_allocation_rule_created"></a> [allocation\_rule\_created](#output\_allocation\_rule\_created) | Map of logical names to the timestamps (ISO 8601) when the custom allocation rules were created. |
| <a name="output_allocation_rule_ids"></a> [allocation\_rule\_ids](#output\_allocation\_rule\_ids) | Map of logical names to the IDs of the custom allocation rules. |
| <a name="output_allocation_rule_last_modified_user_uuids"></a> [allocation\_rule\_last\_modified\_user\_uuids](#output\_allocation\_rule\_last\_modified\_user\_uuids) | Map of logical names to the UUIDs of the users who last modified each custom allocation rule. |
| <a name="output_allocation_rule_order_ids"></a> [allocation\_rule\_order\_ids](#output\_allocation\_rule\_order\_ids) | Map of logical names to the order IDs of the custom allocation rules. |
| <a name="output_allocation_rule_rejected"></a> [allocation\_rule\_rejected](#output\_allocation\_rule\_rejected) | Map of logical names to whether each custom allocation rule was rejected by the Datadog API during creation. |
| <a name="output_allocation_rule_updated"></a> [allocation\_rule\_updated](#output\_allocation\_rule\_updated) | Map of logical names to the timestamps (ISO 8601) when the custom allocation rules were last updated. |
| <a name="output_allocation_rule_versions"></a> [allocation\_rule\_versions](#output\_allocation\_rule\_versions) | Map of logical names to the version numbers of the custom allocation rules. |
| <a name="output_aws_cur_config_created_ats"></a> [aws\_cur\_config\_created\_ats](#output\_aws\_cur\_config\_created\_ats) | Map of logical names to the timestamps when each AWS CUR configuration was created. |
| <a name="output_aws_cur_config_error_messages"></a> [aws\_cur\_config\_error\_messages](#output\_aws\_cur\_config\_error\_messages) | Map of logical names to lists of error messages for each AWS CUR configuration. |
| <a name="output_aws_cur_config_ids"></a> [aws\_cur\_config\_ids](#output\_aws\_cur\_config\_ids) | Map of logical names to the IDs of the AWS CUR configurations. |
| <a name="output_aws_cur_config_status_updated_ats"></a> [aws\_cur\_config\_status\_updated\_ats](#output\_aws\_cur\_config\_status\_updated\_ats) | Map of logical names to the timestamps when each configuration status was last updated. |
| <a name="output_aws_cur_config_statuses"></a> [aws\_cur\_config\_statuses](#output\_aws\_cur\_config\_statuses) | Map of logical names to the current status of each AWS CUR configuration. |
| <a name="output_aws_cur_config_updated_ats"></a> [aws\_cur\_config\_updated\_ats](#output\_aws\_cur\_config\_updated\_ats) | Map of logical names to the timestamps when each AWS CUR configuration was last modified. |
| <a name="output_budget_ids"></a> [budget\_ids](#output\_budget\_ids) | Map of logical names to the IDs of the cost budgets. |
| <a name="output_budget_total_amounts"></a> [budget\_total\_amounts](#output\_budget\_total\_amounts) | Map of logical names to the total amount (sum of all budget entries) for each budget. |
| <a name="output_ccm_config_ids"></a> [ccm\_config\_ids](#output\_ccm\_config\_ids) | Map of logical names to the IDs of the CCM configurations. |
| <a name="output_rule_order_id"></a> [rule\_order\_id](#output\_rule\_order\_id) | The ID of the custom allocation rules ordering resource. Only set when config.enable\_rule\_order is true. |
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
