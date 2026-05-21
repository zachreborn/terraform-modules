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

<h3 align="center">IAM Access Analyzer</h3>
  <p align="center">
    This module enables AWS IAM Access Analyzer at the organization level, optionally registering a delegated administrator account and creating archive rules.
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

### Organization Delegated Admin Example

This example configures IAM Access Analyzer for an AWS Organization with a dedicated security account as the delegated administrator. Two provider aliases are required — one for the management account (to register delegated admin) and one for the security account (where the analyzer is created).

```hcl
provider "aws" {
  alias      = "organization_management_account"
  access_key = var.management_access_key
  secret_key = var.management_secret_key
  region     = var.region
}

provider "aws" {
  alias      = "organization_security_account"
  access_key = var.security_access_key
  secret_key = var.security_secret_key
  region     = var.region
}
```

```hcl
module "access_analyzer" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/access_analyzer"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_security_account   = aws.organization_security_account
  }

  analyzer_name            = "org-access-analyzer"
  analyzer_type            = "ORGANIZATION"
  admin_account_id         = "123456789012"
  register_delegated_admin = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### With Archive Rules

```hcl
module "access_analyzer" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/access_analyzer"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_security_account   = aws.organization_security_account
  }

  analyzer_name            = "org-access-analyzer"
  analyzer_type            = "ORGANIZATION"
  admin_account_id         = "123456789012"
  register_delegated_admin = true

  archive_rules = [
    {
      rule_name = "archive-internal-s3"
      filter = [
        {
          criteria = "principal.AWS"
          contains = ["arn:aws:iam::123456789012:root"]
        }
      ]
    }
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Skip Delegated Admin Registration

Use `register_delegated_admin = false` when the security account is already registered as a delegated admin (e.g., via AWS Config or a prior run).

```hcl
module "access_analyzer" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/access_analyzer"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_security_account   = aws.organization_security_account
  }

  analyzer_name            = "org-access-analyzer"
  analyzer_type            = "ORGANIZATION"
  admin_account_id         = "123456789012"
  register_delegated_admin = false
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
| <a name="provider_aws.organization_management_account"></a> [aws.organization\_management\_account](#provider\_aws.organization\_management\_account) | >= 6.0.0 |
| <a name="provider_aws.organization_security_account"></a> [aws.organization\_security\_account](#provider\_aws.organization\_security\_account) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_accessanalyzer_analyzer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/accessanalyzer_analyzer) | resource |
| [aws_organizations_delegated_administrator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_account_id"></a> [admin\_account\_id](#input\_admin\_account\_id) | (Required) The AWS account ID of the security/delegated admin account where the Access Analyzer will be created. | `string` | n/a | yes |
| <a name="input_analyzer_name"></a> [analyzer\_name](#input\_analyzer\_name) | (Required) Name of the Access Analyzer. Used as a fixed name to support import capability. | `string` | n/a | yes |
| <a name="input_analyzer_type"></a> [analyzer\_type](#input\_analyzer\_type) | (Optional) Type of analyzer to create. Valid values: ACCOUNT, ACCOUNT\_UNUSED\_ACCESS, ORGANIZATION, ORGANIZATION\_UNUSED\_ACCESS. Defaults to ORGANIZATION. | `string` | `"ORGANIZATION"` | no |
| <a name="input_archive_rules"></a> [archive\_rules](#input\_archive\_rules) | (Optional) List of archive rules to create on the analyzer. Each rule requires a rule\_name and one or more filter blocks. Each filter specifies a criteria property and exactly one of: eq (exact match list), neq (not-equal list), contains (substring match list), or exists (bool). | `list(object({...}))` | `[]` | no |
| <a name="input_register_delegated_admin"></a> [register\_delegated\_admin](#input\_register\_delegated\_admin) | (Optional) Whether to register the admin\_account\_id as a delegated administrator for access-analyzer.amazonaws.com. Set to false if the account is already registered. Defaults to true. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the Access Analyzer. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_analyzer_arn"></a> [analyzer\_arn](#output\_analyzer\_arn) | The ARN of the Access Analyzer. |
| <a name="output_analyzer_id"></a> [analyzer\_id](#output\_analyzer\_id) | The ID of the Access Analyzer. |
| <a name="output_analyzer_name"></a> [analyzer\_name](#output\_analyzer\_name) | The name of the Access Analyzer. |
| <a name="output_delegated_admin_id"></a> [delegated\_admin\_id](#output\_delegated\_admin\_id) | The ID of the delegated administrator resource, if created. Null if register\_delegated\_admin is false. |
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
