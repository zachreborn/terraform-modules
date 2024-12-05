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

<h3 align="center">AWS Organization Delegated Administrator Module</h3>
  <p align="center">
    This module generates and manages AWS organization delegated administrators.
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

This example creates an AWS Organization with the default settings.

```
module "organization" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/organization"

    aws_service_access_principals = [
        "aws-artifact-account-sync.amazonaws.com",
        "backup.amazonaws.com",
        "cloudtrail.amazonaws.com",
        "sso.amazonaws.com",
    ]
    enabled_policy_types          = ["TAG_POLICY"]
}
```

### Delegated Admin Example

This example creates and AWS Organization and delegates administrative access to another account.

```
module "organization" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/organization"

    aws_service_access_principals = [
        "aws-artifact-account-sync.amazonaws.com",
        "backup.amazonaws.com",
        "cloudtrail.amazonaws.com",
        "sso.amazonaws.com",
    ]
    enabled_policy_types          = ["TAG_POLICY"]
    delegated_administrators = {
        "123456789012" = "service-abbreviation.amazonaws.com"
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

| Name                                                                                                                                                                | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [aws_organizations_delegated_administrator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization)                        | resource |

## Inputs

| Name                                                                                                                     | Description                                                                                                                                                                                                                                                                                                             | Type           | Default                                                                                                                                                                                                              | Required |
| ------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_aws_service_access_principals"></a> [aws_service_access_principals](#input_aws_service_access_principals) | (Optional) List of AWS service principal names for which you want to enable integration with your organization. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com. Organization must have feature_set set to ALL. For additional information, see the AWS Organizations User Guide.    | `list(string)` | <pre>[<br/> "account.amazonaws.com",<br/> "aws-artifact-account-sync.amazonaws.com",<br/> "backup.amazonaws.com",<br/> "cloudtrail.amazonaws.com",<br/> "health.amazonaws.com",<br/> "sso.amazonaws.com"<br/>]</pre> |    no    |
| <a name="input_delegated_administrators"></a> [delegated_administrators](#input_delegated_administrators)                | (Optional) Map of AWS account IDs and the service principal name to associate with the account. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com.                                                                                                                                     | `map(string)`  | `null`                                                                                                                                                                                                               |    no    |
| <a name="input_enabled_policy_types"></a> [enabled_policy_types](#input_enabled_policy_types)                            | (Optional) List of Organizations policy types to enable in the Organization Root. Organization must have feature_set set to ALL. For additional information about valid policy types (e.g., AISERVICES_OPT_OUT_POLICY, BACKUP_POLICY, SERVICE_CONTROL_POLICY, and TAG_POLICY), see the AWS Organizations API Reference. | `list(string)` | `null`                                                                                                                                                                                                               |    no    |
| <a name="input_feature_set"></a> [feature_set](#input_feature_set)                                                       | (Optional) Specify 'ALL' (default) or 'CONSOLIDATED_BILLING'.                                                                                                                                                                                                                                                           | `string`       | `"ALL"`                                                                                                                                                                                                              |    no    |

## Outputs

| Name                                                                                            | Description                                                                                     |
| ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| <a name="output_accounts"></a> [accounts](#output_accounts)                                     | List of organization accounts.All elements have these attributes: arn, email, id, name, status. |
| <a name="output_arn"></a> [arn](#output_arn)                                                    | ARN of the organization                                                                         |
| <a name="output_id"></a> [id](#output_id)                                                       | ID of the organization                                                                          |
| <a name="output_master_account_arn"></a> [master_account_arn](#output_master_account_arn)       | ARN of the master account                                                                       |
| <a name="output_master_account_email"></a> [master_account_email](#output_master_account_email) | Email address of the master account                                                             |
| <a name="output_master_account_id"></a> [master_account_id](#output_master_account_id)          | ID of the master account                                                                        |
| <a name="output_roots"></a> [roots](#output_roots)                                              | List of organization roots.All elements have these attributes: arn, id, name, policy_types.     |

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
