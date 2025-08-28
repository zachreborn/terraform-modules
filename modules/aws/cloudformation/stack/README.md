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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">Cloudformation Stack</h3>
  <p align="center">
    This module creates an AWS CloudFormation stack. This is helpful when you have a Cloudformation template which you'd like to be able to manage within Terraform or OpenTofu.
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

This example shows how a cloudformation template can be deployed using this module. In this case, a template from Tenable is being used to onboard AWS accounts to Tenable Cloud Security.

```
module "tenable_cloud_security" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloudformation/stack"

  capabilities = ["CAPABILITY_NAMED_IAM"]
  name         = "TenableCloudSecurityStack"
  template_url = "https://tenable-utilities.s3.us-east-2.amazonaws.com/Onboarding/AWS/CloudFormation/Template.json"

  parameters = {
    CloudTrailBucketName                       = "-"
    CloudTrailKeyArn                           = "-"
    RoleContainerImageRepositoryScanningPolicy = false
    RoleDataAnalysisScanningPolicy             = false
    RoleExternalId                             = "1234567-89101112"
    RoleJitPolicy                              = false
    RoleMonitoringPolicy                       = true
    RoleName                                   = "TenableCloudSecurityRole"
    RoleRemediationPolicy                      = false
    RoleTrustedPrincipalId                     = "93208139218011111"
    RoleVirtualMachineScanningPolicy           = false
  }

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
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 4.0.0 |

## Providers

| Name                                             | Version  |
| ------------------------------------------------ | -------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name                                                                                                                              | Type     |
| --------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [aws_cloudformation_stack.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |

## Inputs

| Name                                                                                    | Description                                                                                                                                                                                                                                                        | Type           | Default      | Required |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------- | ------------ | :------: |
| <a name="input_capabilities"></a> [capabilities](#input_capabilities)                   | A list of capabilities that AWS CloudFormation can use. Valid values are: CAPABILITY_IAM, CAPABILITY_NAMED_IAM, CAPABILITY_AUTO_EXPAND.                                                                                                                            | `list(string)` | `null`       |    no    |
| <a name="input_disable_rollback"></a> [disable_rollback](#input_disable_rollback)       | Whether to disable rollback on stack creation failures. Conflicts with 'on_failure' parameter.                                                                                                                                                                     | `bool`         | `false`      |    no    |
| <a name="input_iam_role_arn"></a> [iam_role_arn](#input_iam_role_arn)                   | The ARN of the IAM role to use for the CloudFormation stack. If this is not set, CloudFormation uses the role that was previously associated with the stack. If no role has been set, CloudFormation uses a temporary session generated from the user credentials. | `string`       | `null`       |    no    |
| <a name="input_name"></a> [name](#input_name)                                           | The name of the stack. Must be unique in the region in which you are creating the stack.                                                                                                                                                                           | `string`       | n/a          |   yes    |
| <a name="input_notification_arns"></a> [notification_arns](#input_notification_arns)    | A list of SNS topic ARNs to which stack-related events are published.                                                                                                                                                                                              | `list(string)` | `null`       |    no    |
| <a name="input_on_failure"></a> [on_failure](#input_on_failure)                         | Action to be taken if the stack fails to create. This must be one of: DO_NOTHING, ROLLBACK, or DELETE.                                                                                                                                                             | `string`       | `"ROLLBACK"` |    no    |
| <a name="input_parameters"></a> [parameters](#input_parameters)                         | A map of parameters to pass to the CloudFormation template.                                                                                                                                                                                                        | `map(string)`  | `null`       |    no    |
| <a name="input_policy_body"></a> [policy_body](#input_policy_body)                      | Structure containing the stack policy body. Conflicts with 'policy_url' parameter.                                                                                                                                                                                 | `string`       | `null`       |    no    |
| <a name="input_policy_url"></a> [policy_url](#input_policy_url)                         | URL of the stack policy. Conflicts with 'policy_body' parameter.                                                                                                                                                                                                   | `string`       | `null`       |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                           | A map of tags to assign to the stack.                                                                                                                                                                                                                              | `map(string)`  | `{}`         |    no    |
| <a name="input_template_file"></a> [template_file](#input_template_file)                | Structure containing the template body with a minimum length of 1 byte and a maximum length of 51,200 bytes. Conflicts with 'template_url' parameter.                                                                                                              | `string`       | `null`       |    no    |
| <a name="input_template_url"></a> [template_url](#input_template_url)                   | URL of the CloudFormation template. Conflicts with 'template_file' parameter.                                                                                                                                                                                      | `string`       | `null`       |    no    |
| <a name="input_timeout_in_minutes"></a> [timeout_in_minutes](#input_timeout_in_minutes) | The amount of time in minutes that CloudFormation waits for a stack to be created or updated before timing out.                                                                                                                                                    | `number`       | `60`         |    no    |

## Outputs

| Name                                                     | Description                                         |
| -------------------------------------------------------- | --------------------------------------------------- |
| <a name="output_id"></a> [id](#output_id)                | The unique ID of the stack.                         |
| <a name="output_outputs"></a> [outputs](#output_outputs) | A map containing all of the outputs from the stack. |

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
