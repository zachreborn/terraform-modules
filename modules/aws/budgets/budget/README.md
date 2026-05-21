<!-- Blank module readme template: Do a search and replace with your text editor for the following: `module_name`, `module_description` -->
<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->

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

<h3 align="center">AWS Budgets Budget</h3>
  <p align="center">
    This module creates and manages an AWS Budget for cost and usage tracking. Supports COST, USAGE, RI, and Savings Plans budget types with configurable notifications and cost filters. Designed to be used individually or with for_each to apply budgets across multiple AWS accounts in an organization.
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
    <li><a href="#usage">Usage</a></li>
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

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

This example creates a monthly $100 cost budget with no notifications.

```
module "budget" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/budgets/budget"

  name         = "monthly-cost-budget"
  limit_amount = "100"
}
```

### Full Example with Notifications

This example creates a monthly cost budget with email alerts at 80% actual and 100% forecasted spend.

```
module "budget" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/budgets/budget"

  name         = "prod-monthly-cost-budget"
  budget_type  = "COST"
  limit_amount = "500"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification = [
    {
      comparison_operator        = "GREATER_THAN"
      notification_type          = "ACTUAL"
      threshold                  = 80
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = ["billing-alerts@example.com"]
    },
    {
      comparison_operator        = "GREATER_THAN"
      notification_type          = "FORECASTED"
      threshold                  = 100
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = ["billing-alerts@example.com"]
    }
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Organization Member Account Example

This example deploys a budget per member account when called with `for_each` from a management account context.

```
locals {
  accounts = {
    dev  = "111111111111"
    prod = "222222222222"
  }
}

module "account_budgets" {
  for_each = local.accounts

  source = "github.com/zachreborn/terraform-modules//modules/aws/budgets/budget"

  name         = "${each.key}-monthly-cost-budget"
  account_id   = each.value
  limit_amount = "200"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification = [
    {
      comparison_operator        = "GREATER_THAN"
      notification_type          = "ACTUAL"
      threshold                  = 90
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = ["billing-alerts@example.com"]
    }
  ]

  tags = {
    AccountName = each.key
    ManagedBy   = "terraform"
  }
}
```

### Example with Cost Filters

This example creates a budget scoped to a specific AWS service.

```
module "ec2_budget" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/budgets/budget"

  name         = "ec2-monthly-cost-budget"
  limit_amount = "150"

  cost_filter = [
    {
      name   = "Service"
      values = ["Amazon Elastic Compute Cloud - Compute"]
    }
  ]

  notification = [
    {
      comparison_operator        = "GREATER_THAN"
      notification_type          = "ACTUAL"
      threshold                  = 100
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = ["ec2-billing@example.com"]
    }
  ]
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_budgets_budget.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | (Optional) The ID of the target account for budget. Defaults to the current account if not specified. Useful when managing budgets for member accounts from a management account. | `string` | `null` | no |
| <a name="input_budget_type"></a> [budget\_type](#input\_budget\_type) | (Required) Whether this budget tracks monetary cost or usage. Valid values: COST, USAGE, SAVINGS\_PLANS\_UTILIZATION, SAVINGS\_PLANS\_COVERAGE, RI\_UTILIZATION, RI\_COVERAGE. | `string` | `"COST"` | no |
| <a name="input_cost_filter"></a> [cost\_filter](#input\_cost\_filter) | (Optional) List of cost filters to apply to the budget. Common filter names: LinkedAccount (filter by member account ID), Service (filter by AWS service), Region, TagKeyValue. | <pre>list(object({<br/>    name   = string<br/>    values = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_limit_amount"></a> [limit\_amount](#input\_limit\_amount) | (Required) The amount of cost or usage being measured for a budget. For COST budgets this is a dollar value (e.g. '100'). For USAGE budgets this is the usage type amount. | `string` | `null` | no |
| <a name="input_limit_unit"></a> [limit\_unit](#input\_limit\_unit) | (Required) The unit of measurement used for the budget. For COST budgets use 'USD'. For USAGE budgets use the service-specific unit (e.g. 'GB' for S3 storage). | `string` | `"USD"` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of a budget. Unique within accounts. | `string` | `null` | no |
| <a name="input_notification"></a> [notification](#input\_notification) | (Optional) List of notification configurations for the budget. Each entry creates a budget alert. comparison\_operator: LESS\_THAN, EQUAL\_TO, GREATER\_THAN. notification\_type: ACTUAL or FORECASTED. threshold\_type: PERCENTAGE or ABSOLUTE\_VALUE. | <pre>list(object({<br/>    comparison_operator        = string<br/>    notification_type          = string<br/>    threshold                  = number<br/>    threshold_type             = string<br/>    subscriber_email_addresses = optional(list(string), [])<br/>    subscriber_sns_topic_arns  = optional(list(string), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the budget resource. | `map(string)` | `{}` | no |
| <a name="input_time_period_end"></a> [time\_period\_end](#input\_time\_period\_end) | (Optional) The end of the time period covered by the budget. If not provided, defaults to 2087-06-15\_00:00. Format: YYYY-MM-DD\_HH:MM. | `string` | `null` | no |
| <a name="input_time_period_start"></a> [time\_period\_start](#input\_time\_period\_start) | (Optional) The start of the time period covered by the budget. If not provided, defaults to the beginning of the current month. Format: YYYY-MM-DD\_HH:MM. | `string` | `null` | no |
| <a name="input_time_unit"></a> [time\_unit](#input\_time\_unit) | (Required) The length of time until a budget resets the actual and forecasted spend. Valid values: DAILY, MONTHLY, QUARTERLY, ANNUALLY. | `string` | `"MONTHLY"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the budget. |
| <a name="output_id"></a> [id](#output\_id) | The unique identifier of the budget (same as the budget name). |
| <a name="output_name"></a> [name](#output\_name) | The name of the budget. |
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
