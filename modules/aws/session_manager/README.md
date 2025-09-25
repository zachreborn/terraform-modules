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

<h3 align="center">Session Manager Module</h3>
  <p align="center">
    This module creates resources to enable and utilize session manager (SSM).
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

```
module "session_manager" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/session_manager"
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

| Name                                                                                                                                             | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [aws_iam_instance_profile.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile)             | resource    |
| [aws_iam_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                 | resource    |
| [aws_iam_role.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                     | resource    |
| [aws_iam_role_policy_attachment.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource    |
| [aws_ssm_document.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document)                             | resource    |
| [aws_iam_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy)                              | data source |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name                                                                                                                     | Description                                                           | Type           | Default                        | Required |
| ------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- | -------------- | ------------------------------ | :------: |
| <a name="input_ami"></a> [ami](#input_ami)                                                                               | The AMI to use for the instance.                                      | `string`       | `""`                           |    no    |
| <a name="input_cloudwatch_encryption_enabled"></a> [cloudwatch_encryption_enabled](#input_cloudwatch_encryption_enabled) | Specify true to indicate that encryption for CloudWatch Logs enabled. | `bool`         | `true`                         |    no    |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch_log_group_name](#input_cloudwatch_log_group_name)             | The name of the log group.                                            | `string`       | `""`                           |    no    |
| <a name="input_description"></a> [description](#input_description)                                                       | The description of the all resources.                                 | `string`       | `"Managed by Terraform"`       |    no    |
| <a name="input_iam_path"></a> [iam_path](#input_iam_path)                                                                | Path in which to create the IAM Role and the IAM Policy.              | `string`       | `"/"`                          |    no    |
| <a name="input_iam_policy"></a> [iam_policy](#input_iam_policy)                                                          | The policy document. This is a JSON formatted string.                 | `string`       | `""`                           |    no    |
| <a name="input_name"></a> [name](#input_name)                                                                            | The name of the Session Manager.                                      | `string`       | `"ssm-session-manager"`        |    no    |
| <a name="input_s3_bucket_name"></a> [s3_bucket_name](#input_s3_bucket_name)                                              | The name of the bucket.                                               | `string`       | `""`                           |    no    |
| <a name="input_s3_encryption_enabled"></a> [s3_encryption_enabled](#input_s3_encryption_enabled)                         | Specify true to indicate that encryption for S3 Bucket enabled.       | `bool`         | `true`                         |    no    |
| <a name="input_s3_key_prefix"></a> [s3_key_prefix](#input_s3_key_prefix)                                                 | The prefix for the specified S3 bucket.                               | `string`       | `""`                           |    no    |
| <a name="input_ssm_document_name"></a> [ssm_document_name](#input_ssm_document_name)                                     | The name of the document.                                             | `string`       | `"SSM-SessionManagerRunShell"` |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                            | A mapping of tags to assign to all resources.                         | `map(string)`  | `{}`                           |    no    |
| <a name="input_user_data"></a> [user_data](#input_user_data)                                                             | The user data to provide when launching the instance.                 | `string`       | `""`                           |    no    |
| <a name="input_vpc_security_group_ids"></a> [vpc_security_group_ids](#input_vpc_security_group_ids)                      | A list of security group IDs to associate with.                       | `list(string)` | `[]`                           |    no    |

## Outputs

| Name                                                                                                                                | Description                                                  |
| ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| <a name="output_iam_instance_profile_arn"></a> [iam_instance_profile_arn](#output_iam_instance_profile_arn)                         | The ARN assigned by AWS to the instance profile.             |
| <a name="output_iam_instance_profile_create_date"></a> [iam_instance_profile_create_date](#output_iam_instance_profile_create_date) | The creation timestamp of the instance profile.              |
| <a name="output_iam_instance_profile_id"></a> [iam_instance_profile_id](#output_iam_instance_profile_id)                            | The instance profile's ID.                                   |
| <a name="output_iam_instance_profile_name"></a> [iam_instance_profile_name](#output_iam_instance_profile_name)                      | The instance profile's name.                                 |
| <a name="output_iam_instance_profile_path"></a> [iam_instance_profile_path](#output_iam_instance_profile_path)                      | The path of the instance profile in IAM.                     |
| <a name="output_iam_instance_profile_role"></a> [iam_instance_profile_role](#output_iam_instance_profile_role)                      | The role assigned to the instance profile.                   |
| <a name="output_iam_instance_profile_unique_id"></a> [iam_instance_profile_unique_id](#output_iam_instance_profile_unique_id)       | The unique ID assigned by AWS.                               |
| <a name="output_iam_policy_arn"></a> [iam_policy_arn](#output_iam_policy_arn)                                                       | The ARN assigned by AWS to this IAM Policy.                  |
| <a name="output_iam_policy_description"></a> [iam_policy_description](#output_iam_policy_description)                               | The description of the IAM Policy.                           |
| <a name="output_iam_policy_document"></a> [iam_policy_document](#output_iam_policy_document)                                        | The policy document of the IAM Policy.                       |
| <a name="output_iam_policy_id"></a> [iam_policy_id](#output_iam_policy_id)                                                          | The IAM Policy's ID.                                         |
| <a name="output_iam_policy_name"></a> [iam_policy_name](#output_iam_policy_name)                                                    | The name of the IAM Policy.                                  |
| <a name="output_iam_policy_path"></a> [iam_policy_path](#output_iam_policy_path)                                                    | The path of the IAM Policy.                                  |
| <a name="output_iam_role_arn"></a> [iam_role_arn](#output_iam_role_arn)                                                             | The Amazon Resource Name (ARN) specifying the IAM Role.      |
| <a name="output_iam_role_create_date"></a> [iam_role_create_date](#output_iam_role_create_date)                                     | The creation date of the IAM Role.                           |
| <a name="output_iam_role_description"></a> [iam_role_description](#output_iam_role_description)                                     | The description of the IAM Role.                             |
| <a name="output_iam_role_name"></a> [iam_role_name](#output_iam_role_name)                                                          | The name of the IAM Role.                                    |
| <a name="output_iam_role_unique_id"></a> [iam_role_unique_id](#output_iam_role_unique_id)                                           | The stable and unique string identifying the IAM Role.       |
| <a name="output_ssm_document_default_version"></a> [ssm_document_default_version](#output_ssm_document_default_version)             | The default version of the document.                         |
| <a name="output_ssm_document_description"></a> [ssm_document_description](#output_ssm_document_description)                         | The description of the document.                             |
| <a name="output_ssm_document_hash"></a> [ssm_document_hash](#output_ssm_document_hash)                                              | The sha1 or sha256 of the document content.                  |
| <a name="output_ssm_document_hash_type"></a> [ssm_document_hash_type](#output_ssm_document_hash_type)                               | The hashing algorithm used when hashing the content.         |
| <a name="output_ssm_document_latest_version"></a> [ssm_document_latest_version](#output_ssm_document_latest_version)                | The latest version of the document.                          |
| <a name="output_ssm_document_owner"></a> [ssm_document_owner](#output_ssm_document_owner)                                           | The AWS user account of the person who created the document. |
| <a name="output_ssm_document_parameter"></a> [ssm_document_parameter](#output_ssm_document_parameter)                               | The parameters that are available to this document.          |
| <a name="output_ssm_document_platform_types"></a> [ssm_document_platform_types](#output_ssm_document_platform_types)                | A list of OS platforms compatible with this SSM document.    |
| <a name="output_ssm_document_schema_version"></a> [ssm_document_schema_version](#output_ssm_document_schema_version)                | The schema version of the document.                          |
| <a name="output_ssm_document_status"></a> [ssm_document_status](#output_ssm_document_status)                                        | The current status of the document.                          |

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
