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

<h3 align="center">Cloudformation Stack Set</h3>
  <p align="center">
    This module creates an AWS CloudFormation Stack Set. This is helpful when you have a Cloudformation template which you'd like to be able to manage within Terraform or OpenTofu.
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

This example shows how a cloudformation template can be deployed using this module. In this case, a template from Tenable is being used to onboard AWS accounts in an organization to Tenable Cloud Security.

```
module "tenable_cloud_security_organization_admin" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloudformation/stack_set"

  capabilities              = ["CAPABILITY_NAMED_IAM"]
  description               = "Tenable Cloud Security Organization Admin Stack Set"
  enable_managed_execution  = true
  max_concurrent_percentage = 100
  name                      = "TenableCloudSecurityStackSet"
  template_url              = "https://tenable-utilities.s3.us-east-2.amazonaws.com/Onboarding/AWS/CloudFormation/Template.json"

  parameters = {
    CloudTrailBucketName                       = "-"
    CloudTrailKeyArn                           = "-"
    RoleContainerImageRepositoryScanningPolicy = true
    RoleDataAnalysisScanningPolicy             = true
    RoleExternalId                             = "12345-238219310-2132131"
    RoleJitPolicy                              = false
    RoleMonitoringPolicy                       = true
    RoleName                                   = "TenableCloudSecurityRole"
    RoleRemediationPolicy                      = false
    RoleTrustedPrincipalId                     = "387291839021"
    RoleVirtualMachineScanningPolicy           = true
  }

  # Deploy to the AWS Infrastructure and Workloads OUs
  organizational_unit_ids = [
    module.organization.roots[0].id
  ]

  tags = {
    created_by = "<YOU>>"
    terraform  = "true"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 6.0.0 |

## Providers

| Name                                             | Version  |
| ------------------------------------------------ | -------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name                                                                                                                                                        | Type     |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [aws_cloudformation_stack_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set)                   | resource |
| [aws_cloudformation_stack_set_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |

## Inputs

| Name                                                                                                                              | Description                                                                                                                                                                                                                                   | Type           | Default             | Required |
| --------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------------------- | :------: |
| <a name="input_account_filter_type"></a> [account_filter_type](#input_account_filter_type)                                        | Limit deployment targets to a specific type of account. Valid values are: DIFFERENCE, INTERSECTION, NONE, UNION.                                                                                                                              | `string`       | `null`              |    no    |
| <a name="input_accounts"></a> [accounts](#input_accounts)                                                                         | A list of AWS account IDs to deploy the stack set instances to.                                                                                                                                                                               | `list(string)` | `null`              |    no    |
| <a name="input_accounts_url"></a> [accounts_url](#input_accounts_url)                                                             | S3 URL of a file which contains a list of accounts to deploy the stack set instances to.                                                                                                                                                      | `string`       | `null`              |    no    |
| <a name="input_administration_role_arn"></a> [administration_role_arn](#input_administration_role_arn)                            | The ARN of the IAM role that CloudFormation assumes to perform stack operations. Must be set when using the SELF_MANAGED permission model                                                                                                     | `string`       | `null`              |    no    |
| <a name="input_call_as"></a> [call_as](#input_call_as)                                                                            | Specifies whether you are acting as an account administrator in the management account or as a delegated administrator in a member account. Valid values are: SELF, DELEGATED_ADMIN                                                           | `string`       | `"SELF"`            |    no    |
| <a name="input_capabilities"></a> [capabilities](#input_capabilities)                                                             | A list of capabilities that AWS CloudFormation can use. Valid values are: CAPABILITY_IAM, CAPABILITY_NAMED_IAM, CAPABILITY_AUTO_EXPAND.                                                                                                       | `list(string)` | `null`              |    no    |
| <a name="input_description"></a> [description](#input_description)                                                                | A description of the stack set.                                                                                                                                                                                                               | `string`       | `null`              |    no    |
| <a name="input_enable_auto_deployment"></a> [enable_auto_deployment](#input_enable_auto_deployment)                               | Whether to enable automatic deployment of stack set updates to AWS Organizations accounts that are added to the target organization or organizational unit (OU). Only available when using the SERVICE_MANAGED permission model.              | `bool`         | `true`              |    no    |
| <a name="input_enable_managed_execution"></a> [enable_managed_execution](#input_enable_managed_execution)                         | Whether to enable managed execution for stack set operations. When true, Stack Sets will perform non-conflicting operations concurrently and queue conflicting operations.                                                                    | `bool`         | `false`             |    no    |
| <a name="input_execution_role_name"></a> [execution_role_name](#input_execution_role_name)                                        | The name of the IAM role to use for the CloudFormation stack. When using the SELF_MANAGED permission mode, this defaults to AWSCloudFormationStackSetExecutionRole. When using the SERVICE_MANAGED permission model, this should remain null. | `string`       | `null`              |    no    |
| <a name="input_failure_tolerance_count"></a> [failure_tolerance_count](#input_failure_tolerance_count)                            | The number of failed accounts per region that CloudFormation tolerates before stopping the stack set operation in that region.                                                                                                                | `number`       | `0`                 |    no    |
| <a name="input_failure_tolerance_percentage"></a> [failure_tolerance_percentage](#input_failure_tolerance_percentage)             | The percentage of failed accounts per region that CloudFormation tolerates before stopping the stack set operation in that region.                                                                                                            | `number`       | `null`              |    no    |
| <a name="input_max_concurrent_count"></a> [max_concurrent_count](#input_max_concurrent_count)                                     | The maximum number of accounts in which to create or update the stack set instance at the same time.                                                                                                                                          | `number`       | `1`                 |    no    |
| <a name="input_max_concurrent_percentage"></a> [max_concurrent_percentage](#input_max_concurrent_percentage)                      | The maximum percentage of accounts in which to create or update the stack set instance at the same time.                                                                                                                                      | `number`       | `null`              |    no    |
| <a name="input_name"></a> [name](#input_name)                                                                                     | The name of the stack set. Must be unique in the region in which you are creating the stack set.                                                                                                                                              | `string`       | n/a                 |   yes    |
| <a name="input_organizational_unit_ids"></a> [organizational_unit_ids](#input_organizational_unit_ids)                            | A list of organization unit IDs to deploy the stack set instances to.                                                                                                                                                                         | `list(string)` | `null`              |    no    |
| <a name="input_parameters"></a> [parameters](#input_parameters)                                                                   | A map of parameters to pass to the CloudFormation template.                                                                                                                                                                                   | `map(string)`  | `null`              |    no    |
| <a name="input_permission_model"></a> [permission_model](#input_permission_model)                                                 | The permissions model to use to create the stack set. Valid values are: SERVICE_MANAGED, SELF_MANAGED                                                                                                                                         | `string`       | `"SERVICE_MANAGED"` |    no    |
| <a name="input_region_concurrency_type"></a> [region_concurrency_type](#input_region_concurrency_type)                            | The concurrency type of the stack set operation. Valid values are: SEQUENTIAL, PARALLEL                                                                                                                                                       | `string`       | `"SEQUENTIAL"`      |    no    |
| <a name="input_region_order"></a> [region_order](#input_region_order)                                                             | The order of the regions in which to create or update stack set instances.                                                                                                                                                                    | `list(string)` | `null`              |    no    |
| <a name="input_retain_stacks_on_account_removal"></a> [retain_stacks_on_account_removal](#input_retain_stacks_on_account_removal) | Whether to retain stack instances in accounts that are removed from the stack set.                                                                                                                                                            | `bool`         | `false`             |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                                     | A map of tags to assign to the stack.                                                                                                                                                                                                         | `map(string)`  | `{}`                |    no    |
| <a name="input_template_body"></a> [template_body](#input_template_body)                                                          | Structure containing the template body with a minimum length of 1 byte and a maximum length of 51,200 bytes. Conflicts with 'template_url' parameter.                                                                                         | `string`       | `null`              |    no    |
| <a name="input_template_url"></a> [template_url](#input_template_url)                                                             | URL of the CloudFormation template. Conflicts with 'template_body' parameter.                                                                                                                                                                 | `string`       | `null`              |    no    |

## Outputs

| Name                                            | Description                     |
| ----------------------------------------------- | ------------------------------- |
| <a name="output_arn"></a> [arn](#output_arn)    | The ARN of the stack set.       |
| <a name="output_id"></a> [id](#output_id)       | The unique ID of the stack set. |
| <a name="output_name"></a> [name](#output_name) | The name of the stack set.      |

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
