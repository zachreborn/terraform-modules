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

<h3 align="center">Security Hub CSPM Organization</h3>
  <p align="center">
    This module enables and delegates AWS Security Hub CSPM (Cloud Security Posture Management) across an AWS Organization.
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

## About: Security Hub CSPM vs. the unified AWS Security Hub

In 2026 AWS renamed the classic Security Hub service to **Security Hub CSPM**
(Cloud Security Posture Management) and reassigned the name **AWS Security Hub**
to a new unified service (OCSF schema, cross-service correlation, risk
analytics). The two services coexist and CSPM is **not** deprecated.

- **This module** manages Security Hub CSPM: the delegated administrator, the
  account-level enablement, cross-Region finding aggregation, and (optionally)
  central configuration policies.
- The new unified service ("V2") is managed by the sibling module at
  [`../v2`](../v2). Delegating CSPM to a non-management account (as this module
  does) automatically designates that account as the unified Security Hub
  delegated administrator too, so apply this module first.

## Usage

### Simple Example

This example enables Security Hub CSPM, delegates an admin account from the organization management account, and enables all-region aggregation of findings.

```
module "security_hub" {
  source    = "github.com/zachreborn/terraform-modules//modules/aws/security_hub/organization"
  providers = {
      aws.organization_management_account = aws.organization_management_account
      aws.organization_security_account   = aws.organization_security_account
  }
  admin_account_id = module.account_security.id
}
```

### Setting Specific Regions

This example configures security hub with an organization delegation and specifically aggregates the US regions.

```
module "security_hub" {
  source    = "github.com/zachreborn/terraform-modules//modules/aws/security_hub/organization"
  providers = {
      aws.organization_management_account = aws.organization_management_account
      aws.organization_security_account   = aws.organization_security_account
  }
  admin_account_id  = module.account_security.id
  linking_mode      = "SPECIFIED_REGIONS"
  specified_regions = ["us-east-1", "us-east-2", "us-west-1", "us-west-2"]
}
```

### Central Configuration

This example uses CENTRAL configuration and a configuration policy applied to the
organization root. With CENTRAL configuration, `auto_enable` and
`auto_enable_standards` are forced to `false`/`NONE` (the module handles this
automatically) because enablement is governed by the policy instead.

```
module "security_hub" {
  source    = "github.com/zachreborn/terraform-modules//modules/aws/security_hub/organization"
  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_security_account   = aws.organization_security_account
  }
  admin_account_id   = module.account_security.id
  configuration_type = "CENTRAL"

  configuration_policies = {
    "org-baseline" = {
      description           = "Baseline Security Hub CSPM policy for the whole organization."
      service_enabled       = true
      enabled_standard_arns = [
        "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0",
        "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0",
      ]
      # Provide either disabled_control_identifiers or enabled_control_identifiers.
      disabled_control_identifiers = []
      # Associate the policy with the organization root (or specific OU/account IDs).
      target_ids = [module.organization.roots[0].id]
    }
  }
}
```

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
| <a name="provider_aws.organization_management_account"></a> [aws.organization\_management\_account](#provider\_aws.organization\_management\_account) | 6.53.0 |
| <a name="provider_aws.organization_security_account"></a> [aws.organization\_security\_account](#provider\_aws.organization\_security\_account) | 6.53.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_securityhub_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_configuration_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy) | resource |
| [aws_securityhub_configuration_policy_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_configuration_policy_association) | resource |
| [aws_securityhub_finding_aggregator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_securityhub_organization_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account) | resource |
| [aws_securityhub_organization_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_account_id"></a> [admin\_account\_id](#input\_admin\_account\_id) | (Required) The 12-digit identifier of the AWS account designated as the Security Hub CSPM delegated administrator account. Per AWS, delegating CSPM to a non-management account also designates it as the delegated administrator for the unified AWS Security Hub. | `string` | n/a | yes |
| <a name="input_auto_enable"></a> [auto\_enable](#input\_auto\_enable) | (Optional) Whether to automatically enable Security Hub CSPM for new accounts in the organization. Only applies to LOCAL configuration; when configuration\_type is CENTRAL this is forced to false. Defaults to true. | `bool` | `true` | no |
| <a name="input_auto_enable_standards"></a> [auto\_enable\_standards](#input\_auto\_enable\_standards) | (Optional) Whether to automatically enable Security Hub CSPM default standards for new member accounts in the organization. Valid values are DEFAULT and NONE. Only applies to LOCAL configuration; when configuration\_type is CENTRAL this is forced to NONE. Defaults to DEFAULT. | `string` | `"DEFAULT"` | no |
| <a name="input_configuration_policies"></a> [configuration\_policies](#input\_configuration\_policies) | (Optional) Map of Security Hub CSPM central configuration policies keyed by policy name. Only used when configuration\_type is CENTRAL. Per policy: service\_enabled toggles Security Hub CSPM on/off for associated targets; enabled\_standard\_arns lists the standard ARNs to enable; provide either enabled\_control\_identifiers or disabled\_control\_identifiers (mutually exclusive - a non-empty enabled\_control\_identifiers takes precedence); target\_ids is the list of organization root, OU, or account IDs to associate with the policy. Defaults to an empty map (no policies). | <pre>map(object({<br/>    description                  = optional(string)<br/>    service_enabled              = optional(bool, true)<br/>    enabled_standard_arns        = optional(list(string), [])<br/>    enabled_control_identifiers  = optional(list(string), [])<br/>    disabled_control_identifiers = optional(list(string), [])<br/>    target_ids                   = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_configuration_type"></a> [configuration\_type](#input\_configuration\_type) | (Optional) Whether the organization uses LOCAL or CENTRAL configuration. LOCAL (default) preserves the historical behavior where each account/Region is configured independently and auto\_enable applies. CENTRAL enables configuration policies (see configuration\_policies), requires a finding aggregator, and forces auto\_enable to false and auto\_enable\_standards to NONE. Valid values: LOCAL, CENTRAL. | `string` | `"LOCAL"` | no |
| <a name="input_enable_default_standards"></a> [enable\_default\_standards](#input\_enable\_default\_standards) | (Optional) Whether to enable the security standards that Security Hub CSPM has designated as automatically enabled including: AWS Foundational Security Best Practices v1.0.0 and CIS AWS Foundations Benchmark v1.2.0. Defaults to true. | `bool` | `true` | no |
| <a name="input_linking_mode"></a> [linking\_mode](#input\_linking\_mode) | (Optional) Indicates whether to aggregate findings from all of the available Regions or from a specified list. The options are ALL\_REGIONS, ALL\_REGIONS\_EXCEPT\_SPECIFIED or SPECIFIED\_REGIONS. When ALL\_REGIONS or ALL\_REGIONS\_EXCEPT\_SPECIFIED are used, Security Hub CSPM will automatically aggregate findings from new Regions as Security Hub supports them and you opt into them. | `string` | `"ALL_REGIONS"` | no |
| <a name="input_specified_regions"></a> [specified\_regions](#input\_specified\_regions) | (Optional) List of regions to include or exclude (required if linking\_mode is set to ALL\_REGIONS\_EXCEPT\_SPECIFIED or SPECIFIED\_REGIONS) | `list(string)` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_arn"></a> [account\_arn](#output\_account\_arn) | ARN of the Security Hub CSPM account resource in the delegated security account. |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The AWS account ID where Security Hub CSPM is enabled (the delegated security account). |
| <a name="output_admin_account_id"></a> [admin\_account\_id](#output\_admin\_account\_id) | The 12-digit AWS account ID designated as the Security Hub CSPM delegated administrator. |
| <a name="output_configuration_policy_ids"></a> [configuration\_policy\_ids](#output\_configuration\_policy\_ids) | Map of configuration policy name to policy ID for policies created when configuration\_type is CENTRAL. Empty for LOCAL configuration. |
| <a name="output_finding_aggregator_arn"></a> [finding\_aggregator\_arn](#output\_finding\_aggregator\_arn) | ARN of the Security Hub CSPM finding aggregator. |
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
