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

## Prerequisites

- An AWS Organization with `access-analyzer.amazonaws.com` enabled as a service principal (required for `ORGANIZATION*` analyzer types). This is typically enabled via the Organizations console or `aws_organizations_organization` with `aws_service_access_principals`.
- Two AWS provider aliases configured in the calling module: `aws.organization_management_account` (management/root account) and `aws.organization_security_account` (the account where the analyzer will be created). Both aliases are always required by this module even when `register_delegated_admin = false`, because Terraform resolves provider aliases at plan time regardless of `count`.
- The `admin_account_id` must be a member of the organization when using `ORGANIZATION*` types.

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

`archive_rules` is a map keyed by rule name, which ensures stable `for_each` iteration — adding or removing a rule does not cause unintended recreation of other rules.

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

  archive_rules = {
    archive-internal-s3 = {
      filter = [
        {
          criteria = "principal.AWS"
          contains = ["arn:aws:iam::123456789012:root"]
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Unused Access Analyzer with Configuration

For `ACCOUNT_UNUSED_ACCESS` or `ORGANIZATION_UNUSED_ACCESS` types, configure the age threshold and optional exclusions.

```hcl
module "access_analyzer" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/access_analyzer"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_security_account   = aws.organization_security_account
  }

  analyzer_name            = "org-unused-access-analyzer"
  analyzer_type            = "ORGANIZATION_UNUSED_ACCESS"
  admin_account_id         = "123456789012"
  register_delegated_admin = true

  unused_access_age = 90

  unused_access_analysis_rule_exclusions = [
    {
      account_ids = ["234567890123", "345678901234"]
    },
    {
      resource_tags = [{ Environment = "sandbox" }]
    }
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Internal Access Analyzer with Inclusion Rules

For `ACCOUNT_INTERNAL_ACCESS` or `ORGANIZATION_INTERNAL_ACCESS` types, scope findings to specific resource types or ARNs.

```hcl
module "access_analyzer" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/access_analyzer"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_security_account   = aws.organization_security_account
  }

  analyzer_name            = "org-internal-access-analyzer"
  analyzer_type            = "ORGANIZATION_INTERNAL_ACCESS"
  admin_account_id         = "123456789012"
  register_delegated_admin = true

  internal_access_analysis_rule_inclusions = [
    {
      resource_types = [
        "AWS::S3::Bucket",
        "AWS::RDS::DBSnapshot",
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

Use `register_delegated_admin = false` when the security account is already registered as a delegated admin (e.g., via AWS Config or a prior run). `admin_account_id` may be omitted in this case.

```hcl
module "access_analyzer" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/access_analyzer"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_security_account   = aws.organization_security_account
  }

  analyzer_name            = "org-access-analyzer"
  analyzer_type            = "ORGANIZATION"
  register_delegated_admin = false
}
```

## Notes / Design Decisions

- **Dual-provider requirement**: Both `aws.organization_management_account` and `aws.organization_security_account` provider aliases must always be passed by the caller, even when `register_delegated_admin = false`. Terraform resolves `configuration_aliases` at plan time regardless of resource `count`, so omitting either alias causes a plan-time error. If you only have a single account, point both aliases at the same provider.
- **`admin_account_id` is optional**: It is only required when `register_delegated_admin = true`. A `lifecycle precondition` on the delegated administrator resource enforces this at plan time.
- **`archive_rules` is a map**: The map key becomes the `rule_name`. Using a map (vs. a list) provides stable `for_each` keys so that removing one rule does not trigger recreation of others.
- **`configuration` block is omitted when not needed**: The `configuration`, `unused_access`, and `internal_access` blocks are only emitted when the relevant variables are set, keeping the resource lean for the common `ORGANIZATION` / `ACCOUNT` types that don't need them.
- **`depends_on` between delegated admin and analyzer**: The analyzer depends on the delegated administrator resource because AWS requires the account to be a registered delegated admin before an organization-scoped analyzer can be created in it.
- **IAM Access Analyzer is a regional service**: An analyzer covers only the region it is deployed in. For full coverage, instantiate this module once per active region. Unused access analyzers (`*_UNUSED_ACCESS`) analyze IAM (a global service), so a single region is typically sufficient for those.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws.organization_management_account"></a> [aws.organization\_management\_account](#provider\_aws.organization\_management\_account) | 6.46.0 |
| <a name="provider_aws.organization_security_account"></a> [aws.organization\_security\_account](#provider\_aws.organization\_security\_account) | 6.46.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_accessanalyzer_analyzer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/accessanalyzer_analyzer) | resource |
| [aws_accessanalyzer_archive_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/accessanalyzer_archive_rule) | resource |
| [aws_organizations_delegated_administrator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_account_id"></a> [admin\_account\_id](#input\_admin\_account\_id) | (Optional) The AWS account ID of the security/delegated admin account. Required when register\_delegated\_admin is true. | `string` | `null` | no |
| <a name="input_analyzer_name"></a> [analyzer\_name](#input\_analyzer\_name) | (Required) Name of the Access Analyzer. Used as a fixed name to support import capability. | `string` | n/a | yes |
| <a name="input_analyzer_type"></a> [analyzer\_type](#input\_analyzer\_type) | (Optional) Type of analyzer to create. Valid values: ACCOUNT, ACCOUNT\_INTERNAL\_ACCESS, ACCOUNT\_UNUSED\_ACCESS, ORGANIZATION, ORGANIZATION\_INTERNAL\_ACCESS, ORGANIZATION\_UNUSED\_ACCESS. Defaults to ORGANIZATION. | `string` | `"ORGANIZATION"` | no |
| <a name="input_archive_rules"></a> [archive\_rules](#input\_archive\_rules) | (Optional) Map of archive rules to create on the analyzer, keyed by rule name. Each rule requires one or more filter blocks. Each filter specifies a criteria property and exactly one of: eq (exact match list), neq (not-equal list), contains (substring match list), or exists (bool). | <pre>map(object({<br/>    filter = list(object({<br/>      criteria = string<br/>      eq       = optional(list(string), null)<br/>      neq      = optional(list(string), null)<br/>      contains = optional(list(string), null)<br/>      exists   = optional(bool, null)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_internal_access_analysis_rule_inclusions"></a> [internal\_access\_analysis\_rule\_inclusions](#input\_internal\_access\_analysis\_rule\_inclusions) | (Optional) List of inclusion rules for the internal access analyzer. Only resources matching an inclusion rule will generate findings. Each inclusion may specify account\_ids, resource\_arns, and/or resource\_types. Only applicable for ACCOUNT\_INTERNAL\_ACCESS and ORGANIZATION\_INTERNAL\_ACCESS analyzer types. | <pre>list(object({<br/>    account_ids    = optional(list(string), null)<br/>    resource_arns  = optional(list(string), null)<br/>    resource_types = optional(list(string), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_register_delegated_admin"></a> [register\_delegated\_admin](#input\_register\_delegated\_admin) | (Optional) Whether to register the admin\_account\_id as a delegated administrator for access-analyzer.amazonaws.com. Set to false if the account is already registered. Defaults to true. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the Access Analyzer. | `map(string)` | `{}` | no |
| <a name="input_unused_access_age"></a> [unused\_access\_age](#input\_unused\_access\_age) | (Optional) Number of days for which to generate findings for unused access. Only applicable for ACCOUNT\_UNUSED\_ACCESS and ORGANIZATION\_UNUSED\_ACCESS analyzer types. If null, the AWS default is used. | `number` | `null` | no |
| <a name="input_unused_access_analysis_rule_exclusions"></a> [unused\_access\_analysis\_rule\_exclusions](#input\_unused\_access\_analysis\_rule\_exclusions) | (Optional) List of exclusion rules for the unused access analyzer. Entities matching any exclusion will not generate findings. Each exclusion may specify account\_ids (list of AWS account IDs to exclude) and/or resource\_tags (list of tag key-value maps to exclude). Only applicable for ACCOUNT\_UNUSED\_ACCESS and ORGANIZATION\_UNUSED\_ACCESS analyzer types. | <pre>list(object({<br/>    account_ids   = optional(list(string), null)<br/>    resource_tags = optional(list(map(string)), null)<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_analyzer_arn"></a> [analyzer\_arn](#output\_analyzer\_arn) | The ARN of the Access Analyzer. |
| <a name="output_analyzer_id"></a> [analyzer\_id](#output\_analyzer\_id) | The ID of the Access Analyzer. |
| <a name="output_analyzer_name"></a> [analyzer\_name](#output\_analyzer\_name) | The name of the Access Analyzer. |
| <a name="output_archive_rule_ids"></a> [archive\_rule\_ids](#output\_archive\_rule\_ids) | Map of archive rule names to their resource IDs. |
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
