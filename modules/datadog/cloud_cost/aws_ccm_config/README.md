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

<h3 align="center">Datadog AWS CCM Config</h3>
  <p align="center">
    Manages Cloud Cost Management (CCM) configuration linked to a Datadog AWS account integration.
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

Manages one or more `datadog_integration_aws_account_ccm_config` resources. Each configuration attaches Cloud Cost Management settings (including optional Cost and Usage Report data export configurations) to an existing Datadog AWS account integration. Multiple configurations are managed via a single `map(object({...}))` input variable using `for_each`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- An existing Datadog AWS account integration. The `aws_account_config_id` required by this module is the Datadog-internal UUID exposed as the `id` output of the `datadog_integration_aws_account` resource — **not** the AWS account ID (e.g., `123456789012`).
- If using `data_export_configs`, an existing AWS Cost and Usage Report and an S3 bucket with appropriate IAM permissions.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

### Simple Example

```hcl
module "aws_ccm_config" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost/aws_ccm_config"

  ccm_configs = {
    main = {
      aws_account_config_id = "00000000-0000-0000-0000-000000000000"
    }
  }
}
```

### With CUR Data Export

```hcl
module "aws_ccm_config" {
  source = "github.com/zachreborn/terraform-modules//modules/datadog/cloud_cost/aws_ccm_config"

  ccm_configs = {
    production = {
      # Obtain from: module.aws_integration.ids["production"]
      aws_account_config_id = "00000000-0000-0000-0000-000000000000"

      ccm_config = {
        data_export_configs = [
          {
            report_name   = "cost-and-usage-report"
            report_prefix = "reports"
            report_type   = "CUR2.0"
            bucket_name   = "my-billing-bucket"
            bucket_region = "us-east-1"
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
- **`aws_account_config_id` is a Datadog UUID**: This is the internal Datadog identifier for the AWS integration, **not** the 12-digit AWS account ID. Obtain it from `datadog_integration_aws_account.this[key].id` or the equivalent output of the `modules/datadog/integrations/aws` module.
- **`data_export_configs` is a list**: Multiple CUR report exports can be configured per CCM config by providing multiple entries in the `data_export_configs` list.
- **`for_each` pattern**: One CCM config per AWS account integration is typical, but the map input allows managing multiple integrations in a single module invocation.

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

| Name | Version |
| ---- | ------- |
| <a name="provider_datadog"></a> [datadog](#provider\_datadog) | 4.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [datadog_integration_aws_account_ccm_config.this](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/integration_aws_account_ccm_config) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ccm_configs"></a> [ccm\_configs](#input\_ccm\_configs) | Map of Cloud Cost Management (CCM) configurations to create. Each key is a logical name. The value's aws\_account\_config\_id is the Datadog-internal UUID from the AWS integration resource (not the AWS account ID). | <pre>map(object({<br/>    aws_account_config_id = string<br/>    ccm_config = optional(object({<br/>      data_export_configs = optional(list(object({<br/>        bucket_name   = optional(string, null)<br/>        bucket_region = optional(string, null)<br/>        report_name   = optional(string, null)<br/>        report_prefix = optional(string, null)<br/>        report_type   = optional(string, null)<br/>      })), null)<br/>    }), null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of logical names to the IDs of the CCM configurations. |
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
