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

<h3 align="center">Security Hub V2 (Unified)</h3>
  <p align="center">
    This module enables the unified AWS Security Hub ("V2") in the delegated security account, including cross-Region finding aggregation and OCSF automation rules.
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

## About: the unified AWS Security Hub vs. Security Hub CSPM

In 2026 AWS reassigned the name **AWS Security Hub** to a new unified security
operations service (OCSF schema, cross-service correlation, risk analytics,
exposure summaries) and renamed the classic posture manager to **Security Hub
CSPM**. This module manages the new unified service. The classic CSPM service is
managed by the sibling module at [`../organization`](../organization).

## Prerequisites

- **Delegate CSPM first.** Apply the [`../organization`](../organization) (Security
  Hub CSPM) module before this one. Per AWS, designating a non-management account
  as the Security Hub CSPM delegated administrator automatically makes that same
  account the delegated administrator for the unified Security Hub. There is no
  separate Terraform resource to delegate the unified service.
- **Organization trusted access.** `securityhub.amazonaws.com` must have trusted
  access enabled in the organization (the `organizations/organization` module
  enables this by default).

## Notes / Design Decisions

- **Scope is the delegated security account.** All V2 resources
  (`aws_securityhub_account_v2`, `aws_securityhub_aggregator_v2`,
  `aws_securityhub_automation_rule_v2`) are created in the delegated security
  (administrator) account, so this module takes a single
  `aws.organization_security_account` provider alias.
- **Org-wide member enablement is not yet available in Terraform.** The AWS
  provider does not expose a V2 equivalent of
  `aws_securityhub_organization_admin_account` or
  `aws_securityhub_organization_configuration`. Auto-enabling the unified service
  across member accounts is currently a console/API action (Security Hub
  configuration policies / deployments). Perform that step outside Terraform
  until the provider adds support.
- **Cost.** Enabling the unified service turns on the per-resource **Essentials
  plan** (30-day free trial, then billed). Usage-based add-ons (Threat analytics
  from GuardDuty, Lambda code scanning from Inspector) are billed separately.
  Set an AWS Budgets alarm before enabling anything paid, and scope Regions
  with intent via `region_linking_mode` / `linked_regions`.
- **Automation rules require an aggregator.** Automation rules must be created in
  the aggregation (home) Region and require an existing aggregator, so
  `automation_rules` requires `enable_finding_aggregation = true`.

## Usage

### Simple Example

Enables the unified Security Hub with all-Region aggregation in the delegated
security account.

```
module "security_hub_v2" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/security_hub/v2"
  providers = {
    aws.organization_security_account = aws.organization_security_account
  }
}
```

### Specified Regions

```
module "security_hub_v2" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/security_hub/v2"
  providers = {
    aws.organization_security_account = aws.organization_security_account
  }
  region_linking_mode = "SPECIFIED_REGIONS"
  linked_regions      = ["us-east-1", "us-east-2", "us-west-1", "us-west-2"]
}
```

### With an Automation Rule

Suppresses low-severity GuardDuty findings.

```
module "security_hub_v2" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/security_hub/v2"
  providers = {
    aws.organization_security_account = aws.organization_security_account
  }

  automation_rules = {
    "suppress-guardduty-low" = {
      description = "Suppress low severity GuardDuty findings"
      rule_order  = 100
      ocsf_finding_criteria_json = jsonencode({
        CompositeFilters = [
          {
            StringFilters = [
              {
                FieldName = "metadata.product.name"
                Filter = {
                  Comparison = "EQUALS"
                  Value      = "GuardDuty"
                }
              }
            ]
          }
        ]
        CompositeOperator = "AND"
      })
      finding_fields_update = {
        severity_id = 99
        status_id   = 3
        comment     = "Low severity GuardDuty finding suppressed"
      }
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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.46.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws.organization_security_account"></a> [aws.organization\_security\_account](#provider\_aws.organization\_security\_account) | >= 6.46.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_securityhub_account_v2.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account_v2) | resource |
| [aws_securityhub_aggregator_v2.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_aggregator_v2) | resource |
| [aws_securityhub_automation_rule_v2.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_automation_rule_v2) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_automation_rules"></a> [automation\_rules](#input\_automation\_rules) | (Optional) Map of Security Hub V2 automation rules keyed by rule name. Requires enable\_finding\_aggregation = true. Per rule: rule\_order sets priority (lower is higher priority); rule\_status is ENABLED or DISABLED; ocsf\_finding\_criteria\_json is the JSON-encoded OCSF finding criteria; action\_type is FINDING\_FIELDS\_UPDATE or EXTERNAL\_INTEGRATION; supply finding\_fields\_update for FINDING\_FIELDS\_UPDATE actions, or external\_integration\_connector\_arn for EXTERNAL\_INTEGRATION actions. Defaults to an empty map (no rules). | <pre>map(object({<br/>    description                = string<br/>    rule_order                 = number<br/>    rule_status                = optional(string, "ENABLED")<br/>    ocsf_finding_criteria_json = string<br/>    action_type                = optional(string, "FINDING_FIELDS_UPDATE")<br/>    finding_fields_update = optional(object({<br/>      comment     = optional(string)<br/>      severity_id = optional(number)<br/>      status_id   = optional(number)<br/>    }))<br/>    external_integration_connector_arn = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_finding_aggregation"></a> [enable\_finding\_aggregation](#input\_enable\_finding\_aggregation) | (Optional) Whether to create a Security Hub V2 cross-Region finding aggregator. Must be true to use automation\_rules. Defaults to true. | `bool` | `true` | no |
| <a name="input_linked_regions"></a> [linked\_regions](#input\_linked\_regions) | (Optional) List of Regions linked to the aggregation Region. Required when region\_linking\_mode is SPECIFIED\_REGIONS or ALL\_REGIONS\_EXCEPT\_SPECIFIED; otherwise leave null. Defaults to null. | `list(string)` | `null` | no |
| <a name="input_region_linking_mode"></a> [region\_linking\_mode](#input\_region\_linking\_mode) | (Optional) Determines how Regions are linked to the aggregator. Valid values: ALL\_REGIONS, ALL\_REGIONS\_EXCEPT\_SPECIFIED, SPECIFIED\_REGIONS. Only used when enable\_finding\_aggregation is true. Defaults to ALL\_REGIONS. | `string` | `"ALL_REGIONS"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the Security Hub V2 resources created by this module (account, aggregator, and automation rules). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_arn"></a> [account\_arn](#output\_account\_arn) | ARN of the unified Security Hub (V2) resource created in the security account. |
| <a name="output_aggregation_region"></a> [aggregation\_region](#output\_aggregation\_region) | The AWS Region where Security Hub V2 findings are aggregated, or null when enable\_finding\_aggregation is false. |
| <a name="output_aggregator_arn"></a> [aggregator\_arn](#output\_aggregator\_arn) | ARN of the Security Hub V2 aggregator, or null when enable\_finding\_aggregation is false. |
| <a name="output_automation_rule_arns"></a> [automation\_rule\_arns](#output\_automation\_rule\_arns) | Map of automation rule name to rule ARN for rules created by this module. Empty when no automation\_rules are supplied. |
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
