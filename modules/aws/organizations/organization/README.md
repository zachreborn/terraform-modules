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

<h3 align="center">AWS Organization Module</h3>
  <p align="center">
    This module generates and manages an AWS Organization.
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
    source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/organization"

    aws_service_access_principals = [
        "aws-artifact-account-sync.amazonaws.com",
        "backup.amazonaws.com",
        "cloudtrail.amazonaws.com",
        "sso.amazonaws.com",
    ]
    enabled_policy_types          = ["TAG_POLICY"]
}
```

### Identity Center Service Control Policy

By default this module creates and attaches a Service Control Policy (SCP) to the
organization root which denies `sso:CreateInstance` organization-wide. This
prevents member (child) accounts from creating their own account-level IAM
Identity Center (AWS SSO) instances, keeping Identity Center management
centralized in the management account / delegated administrator.

**Prerequisite:** SCP support must be enabled on the organization. Include
`"SERVICE_CONTROL_POLICY"` in `enabled_policy_types`, otherwise the apply fails
with a precondition error. The organization `feature_set` must be `ALL`.

```
module "organization" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/organization"

    # Required so the SCP can be created and attached.
    enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]

    # The following are the defaults and may be omitted.
    enable_identity_center_scp = true
    attach_identity_center_scp = true
}
```

To opt out entirely (no new resources, clean plan), set
`enable_identity_center_scp = false`. To create the policy without enforcing it,
set `attach_identity_center_scp = false`. To attach the SCP to specific OUs or
accounts instead of the organization root, set `identity_center_scp_target_ids`.

### Centralized Security Services

The default `aws_service_access_principals` enables AWS Organizations trusted
access for the centralized security services this module library integrates
with: Security Hub (both Security Hub CSPM and the unified Security Hub),
GuardDuty, Config, IAM Access Analyzer, and Inspector. Keeping these in the
organization module makes it the single source of truth for trusted access, so
the delegated-administrator modules (`security_hub/organization`,
`guardduty/organization`, `config/organization`, etc.) do not enable a principal
out-of-band and cause perpetual drift on the next apply of this module.

**Caveat:** once a service has a registered delegated administrator, AWS will not
let you remove its principal from this list until the delegated administrator is
deregistered. Remove the delegated-administrator resource first, then drop the
principal.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.78.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.78.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_centralized_backup"></a> [centralized\_backup](#module\_centralized\_backup) | ../policy | n/a |
| <a name="module_centralized_root"></a> [centralized\_root](#module\_centralized\_root) | ../../iam/organizations_features | n/a |
| <a name="module_identity_center_scp"></a> [identity\_center\_scp](#module\_identity\_center\_scp) | ../policy | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | resource |
| [aws_organizations_policy_attachment.identity_center_scp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_attach_identity_center_scp"></a> [attach\_identity\_center\_scp](#input\_attach\_identity\_center\_scp) | (Optional) If true, attaches the Identity Center deny SCP to the targets in identity\_center\_scp\_target\_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true. | `bool` | `true` | no |
| <a name="input_aws_service_access_principals"></a> [aws\_service\_access\_principals](#input\_aws\_service\_access\_principals) | (Optional) List of AWS service principal names for which you want to enable trusted access (integration) with your organization. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com. Organization must have feature\_set set to ALL. The default list enables the centralized security services this module library integrates with (Security Hub, GuardDuty, Config, IAM Access Analyzer, and Inspector) so that their delegated-administrator modules do not create trusted-access drift. Note: once a service has a registered delegated administrator, removing its principal from this list will fail until the delegated administrator is deregistered. For additional information, see the AWS Organizations User Guide. | `list(string)` | <pre>[<br/>  "access-analyzer.amazonaws.com",<br/>  "account.amazonaws.com",<br/>  "aws-artifact-account-sync.amazonaws.com",<br/>  "backup.amazonaws.com",<br/>  "cloudtrail.amazonaws.com",<br/>  "config.amazonaws.com",<br/>  "guardduty.amazonaws.com",<br/>  "health.amazonaws.com",<br/>  "inspector2.amazonaws.com",<br/>  "securityhub.amazonaws.com",<br/>  "sso.amazonaws.com"<br/>]</pre> | no |
| <a name="input_enable_identity_center_scp"></a> [enable\_identity\_center\_scp](#input\_enable\_identity\_center\_scp) | (Optional) If true, creates a Service Control Policy (SCP) which denies sso:CreateInstance organization-wide so member accounts cannot create account-level IAM Identity Center instances. Defaults to true. Requires SERVICE\_CONTROL\_POLICY in enabled\_policy\_types. | `bool` | `true` | no |
| <a name="input_enable_organization_backup"></a> [enable\_organization\_backup](#input\_enable\_organization\_backup) | (Optional) If true, enables the organization backup policy. Defaults to false. | `bool` | `false` | no |
| <a name="input_enabled_features"></a> [enabled\_features](#input\_enabled\_features) | A list of IAM organization features which will be enabled. Valid values are RootCredentialsManagement and RootSessions. | `list(string)` | <pre>[<br/>  "RootCredentialsManagement",<br/>  "RootSessions"<br/>]</pre> | no |
| <a name="input_enabled_policy_types"></a> [enabled\_policy\_types](#input\_enabled\_policy\_types) | (Optional) List of Organizations policy types to enable in the Organization Root. Organization must have feature\_set set to ALL. For additional information about valid policy types (e.g., AISERVICES\_OPT\_OUT\_POLICY, BACKUP\_POLICY, SERVICE\_CONTROL\_POLICY, and TAG\_POLICY), see the AWS Organizations API Reference. | `list(string)` | `null` | no |
| <a name="input_feature_set"></a> [feature\_set](#input\_feature\_set) | (Optional) Specify 'ALL' (default) or 'CONSOLIDATED\_BILLING'. | `string` | `"ALL"` | no |
| <a name="input_identity_center_scp_description"></a> [identity\_center\_scp\_description](#input\_identity\_center\_scp\_description) | (Optional) Description of the Identity Center deny SCP. | `string` | `"Denies sso:CreateInstance org-wide so member accounts cannot create account-level IAM Identity Center instances."` | no |
| <a name="input_identity_center_scp_name"></a> [identity\_center\_scp\_name](#input\_identity\_center\_scp\_name) | (Optional) Name of the Identity Center deny SCP. Used as the name of the aws\_organizations\_policy created via the policy module. | `string` | `"DenyMemberAccountIdentityCenter"` | no |
| <a name="input_identity_center_scp_target_ids"></a> [identity\_center\_scp\_target\_ids](#input\_identity\_center\_scp\_target\_ids) | (Optional) List of organization root, OU, or account IDs to attach the Identity Center deny SCP to. When null and attach\_identity\_center\_scp is true, the SCP is attached to the organization root. Defaults to null. | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the AWS Organization. Tags are key-value pairs that help organize and manage resources. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_accounts"></a> [accounts](#output\_accounts) | List of organization accounts.All elements have these attributes: arn, email, id, name, status. |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the organization |
| <a name="output_id"></a> [id](#output\_id) | ID of the organization |
| <a name="output_identity_center_scp_arn"></a> [identity\_center\_scp\_arn](#output\_identity\_center\_scp\_arn) | ARN of the Identity Center deny SCP, or null when enable\_identity\_center\_scp is false. |
| <a name="output_identity_center_scp_attachment_target_ids"></a> [identity\_center\_scp\_attachment\_target\_ids](#output\_identity\_center\_scp\_attachment\_target\_ids) | List of target IDs the Identity Center deny SCP was attached to. Empty when attachment is disabled. |
| <a name="output_identity_center_scp_id"></a> [identity\_center\_scp\_id](#output\_identity\_center\_scp\_id) | ID of the Identity Center deny SCP, or null when enable\_identity\_center\_scp is false. |
| <a name="output_master_account_arn"></a> [master\_account\_arn](#output\_master\_account\_arn) | ARN of the master account |
| <a name="output_master_account_email"></a> [master\_account\_email](#output\_master\_account\_email) | Email address of the master account |
| <a name="output_master_account_id"></a> [master\_account\_id](#output\_master\_account\_id) | ID of the master account |
| <a name="output_roots"></a> [roots](#output\_roots) | List of organization roots.All elements have these attributes: arn, id, name, policy\_types. |
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
