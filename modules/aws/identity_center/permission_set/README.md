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

<h3 align="center">Permission Set</h3>
  <p align="center">
    This module created a permission set, attaches a policy, and assigns the permission set to a list of groups and AWS accounts. This is utilized to manage the permissions of users in AWS Identity Center (formerly SSO).
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

### Managed Policy Example

This example will create a permission set, attach a managed policy to it, assign the permission set to a list of groups, and assigns the permission set to a list of AWS accounts. This is the recommended way to use this module as the built-in permission sets are managed policies.

```
module "admins_permissions" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/identity_center/permission_set"

  name        = "AdministratorAccess"
  description = "Admin permissions using the Managed Policy - AdministratorAccess"
  groups = [
    "admins"
  ]

  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  target_accounts = [
    module.organization.id,
    module.security.id,
    module.logging.id,
    module.network.id,
    module.infrastructure.id
  ]
}
```

### Customer Managed Policy Example

This example will create a permission set, attach a customer managed policy to it, assign the permission set to a list of groups, and assigns the permission set to a list of AWS accounts. This requires deploying the customer managed policy first to all accounts you plan to assign the permission set to. This does NOT deploy the IAM policy to the target accounts, it only attaches the policy to the permission set. This is useful if you have a custom policy that you want to use across multiple accounts and are managing the IAM policy across each account.

```
module "customer_managed_permissions" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/identity_center/permission_set"

  name        = "CustomerManagedPolicyPermissions"
  description = "Permissions test using a customer managed policy"
  groups = [
    "admins",
    "terraform"
  ]

  customer_managed_iam_policy_name = "test-policy"
  customer_managed_iam_policy_path = "/"
  target_accounts = [
    module.organization.id
  ]
}
```

### Inline Policy Example

This example will create a permission set, attach an inline policy to it, assign the permission set to a list of groups, and assigns the permission set to a list of AWS accounts. This is useful if you want to create a custom policy that is only used for a single permission set. This is the simplest way to deploy custom policies to multiple accounts. It should be noted that this does not allow for versioning of the policy. If you need to version your policy, you should use the customer managed policy example and deploy the policy to each account using the `aws_iam_policy` resource or modules.

```
module "inline_permissions" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/identity_center/permission_set"

  name        = "InlinePolicyPermissions"
  description = "Permissions test using an inline policy"
  groups = [
    "admins",
    "terraform"
  ]

  inline_policy = data.aws_iam_policy_document.example.json
  target_accounts = [
    module.organization.id,
    module.security.id,
    module.logging.id,
    module.network.id,
    module.infrastructure.id
  ]
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

| Name                                                                                                                                                                            | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_ssoadmin_account_assignment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_account_assignment)                                 | resource    |
| [aws_ssoadmin_customer_managed_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_customer_managed_policy_attachment) | resource    |
| [aws_ssoadmin_managed_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_managed_policy_attachment)                   | resource    |
| [aws_ssoadmin_permission_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set)                                         | resource    |
| [aws_ssoadmin_permission_set_inline_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set_inline_policy)             | resource    |
| [aws_identitystore_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/identitystore_group)                                              | data source |
| [aws_ssoadmin_instances.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances)                                                | data source |

## Inputs

| Name                                                                                                                              | Description                                                                                                                                                         | Type           | Default         | Required |
| --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | --------------- | :------: |
| <a name="input_customer_managed_iam_policy_name"></a> [customer_managed_iam_policy_name](#input_customer_managed_iam_policy_name) | (Optional) The name of the customer managed IAM policy to attach to a Permission Set. If this is set, the module will utilize a customer_managed_policy_attachment. | `string`       | `null`          |    no    |
| <a name="input_customer_managed_iam_policy_path"></a> [customer_managed_iam_policy_path](#input_customer_managed_iam_policy_path) | (Optional) The path of the customer managed IAM policy to attach to a Permission Set.                                                                               | `string`       | `"/"`           |    no    |
| <a name="input_description"></a> [description](#input_description)                                                                | (Optional) The description of the permission set.                                                                                                                   | `string`       | `null`          |    no    |
| <a name="input_group_attribute_path"></a> [group_attribute_path](#input_group_attribute_path)                                     | (Optional) The path of the group attribute in AWS SSO. This value is used to uniquely identify groups in AWS SSO.                                                   | `string`       | `"DisplayName"` |    no    |
| <a name="input_groups"></a> [groups](#input_groups)                                                                               | (Required) The group names to lookup and associate with the permission set.                                                                                         | `set(string)`  | n/a             |   yes    |
| <a name="input_inline_policy"></a> [inline_policy](#input_inline_policy)                                                          | (Optional) The IAM inline policy to attach to a Permission Set. If this is set, the module will utilize an inline_policy.                                           | `string`       | `null`          |    no    |
| <a name="input_managed_policy_arns"></a> [managed_policy_arns](#input_managed_policy_arns)                                        | (Optional) The ARN of the IAM managed policy to attach to a Permission Set. If this is set, the module will utilize a managed_policy_attachment.                    | `list(string)` | `[]`            |    no    |
| <a name="input_name"></a> [name](#input_name)                                                                                     | (Required) The name of the permission set.                                                                                                                          | `string`       | n/a             |   yes    |
| <a name="input_relay_state"></a> [relay_state](#input_relay_state)                                                                | (Optional) The relay state URL used to redirect users within the application during the federation authentication process.                                          | `string`       | `null`          |    no    |
| <a name="input_session_duration"></a> [session_duration](#input_session_duration)                                                 | (Optional) The length of time that the application user sessions are valid in the ISO-8601 standard.                                                                | `string`       | `"PT1H"`        |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                                     | (Optional) Key-value map of resource tags.                                                                                                                          | `map(string)`  | `{}`            |    no    |
| <a name="input_target_accounts"></a> [target_accounts](#input_target_accounts)                                                    | (Required) The list of AWS account IDs to assign the permission set to.                                                                                             | `set(string)`  | n/a             |   yes    |

## Outputs

| Name                                                                          | Description                                                                            |
| ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| <a name="output_arn"></a> [arn](#output_arn)                                  | The ARN of the permission set                                                          |
| <a name="output_assignment_ids"></a> [assignment_ids](#output_assignment_ids) | Map of the IDs of the permission set assignments and their corresponding configuration |
| <a name="output_created_date"></a> [created_date](#output_created_date)       | The date the permission set was created                                                |
| <a name="output_id"></a> [id](#output_id)                                     | The ID of the permission set                                                           |

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
