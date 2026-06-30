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

<h3 align="center">Datadog AWS CUR Config</h3>
  <p align="center">
    Manages Datadog AWS Cost and Usage Report (CUR) configurations for Cloud Cost Management.
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

Manages one or more `datadog_aws_cur_config` resources. Each configuration connects Datadog Cloud Cost Management to an AWS Cost and Usage Report (CUR), allowing Datadog to ingest billing data from your AWS account(s). Multiple configurations are managed via a single `map(object({...}))` input variable using `for_each`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- An active Datadog AWS integration for the billing/payer account (see `modules/datadog/integrations/aws`).
- An existing AWS Cost and Usage Report configured in AWS Billing preferences with the exact `report_name` and `report_prefix` you specify.
- An S3 bucket containing the CUR files with IAM permissions granting Datadog read access (typically via the Datadog IAM policy attached to the AWS integration role).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

### Simple Example

```hcl
module "aws_cur_config" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost/aws_cur_config"

  aws_cur_configs = {
    primary = {
      account_id    = "123456789012"
      bucket_name   = "my-cur-bucket"
      bucket_region = "us-east-1"
      report_name   = "my-cur-report"
      report_prefix = "cur-reports/"
    }
  }
}
```

### With Account Filters

```hcl
module "aws_cur_config" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost/aws_cur_config"

  aws_cur_configs = {
    org_billing = {
      account_id    = "123456789012"
      bucket_name   = "org-cur-bucket"
      bucket_region = "us-east-1"
      report_name   = "org-cur-report"
      report_prefix = "billing/cur/"

      account_filters = {
        # Include all new accounts automatically, but exclude a specific account
        include_new_accounts = true
        excluded_accounts    = ["111111111111"]
      }
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **`required_version >= 1.3.0`**: The two-argument `optional(<type>, <default>)` form used in this module's variables requires Terraform or OpenTofu version 1.3.0 or later. This is a language constraint, not a provider constraint.
- **`account_filters` mutual exclusivity**: Within an `account_filters` block, `excluded_accounts` and `included_accounts` are mutually exclusive. Use `excluded_accounts` when `include_new_accounts = true`, and `included_accounts` when `include_new_accounts = false`. Setting both will result in an API error.
- **`for_each` pattern**: Multiple CUR configs (e.g., one per AWS Organization payer account) are managed with a single module invocation. The map key is a caller-defined logical name and does not need to match any AWS identifier.
- **Read-only attributes**: `status`, `status_updated_at`, `created_at`, `updated_at`, and `error_messages` are surfaced as outputs but cannot be set as inputs — they are populated by Datadog after the configuration is created.

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
| [datadog_aws_cur_config.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/aws_cur_config) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_cur_configs"></a> [aws\_cur\_configs](#input\_aws\_cur\_configs) | Map of AWS Cost and Usage Report (CUR) configurations to create. Each key is a logical name for the configuration. | <pre>map(object({<br/>    account_id    = string<br/>    bucket_name   = string<br/>    report_name   = string<br/>    report_prefix = string<br/>    bucket_region = optional(string, null)<br/>    account_filters = optional(object({<br/>      include_new_accounts = optional(bool, null)<br/>      excluded_accounts    = optional(list(string), null)<br/>      included_accounts    = optional(list(string), null)<br/>    }), null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_created_ats"></a> [created\_ats](#output\_created\_ats) | Map of logical names to the timestamps when each AWS CUR configuration was created. |
| <a name="output_error_messages"></a> [error\_messages](#output\_error\_messages) | Map of logical names to lists of error messages for each AWS CUR configuration. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of logical names to the IDs of the AWS CUR configurations. |
| <a name="output_status_updated_ats"></a> [status\_updated\_ats](#output\_status\_updated\_ats) | Map of logical names to the timestamps when each configuration status was last updated. |
| <a name="output_statuses"></a> [statuses](#output\_statuses) | Map of logical names to the current status of each AWS CUR configuration. |
| <a name="output_updated_ats"></a> [updated\_ats](#output\_updated\_ats) | Map of logical names to the timestamps when each AWS CUR configuration was last modified. |
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
