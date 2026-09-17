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

<h3 align="center">DRS Initialization Module</h3>
  <p align="center">
    This module creates the IAM roles, instance profiles, and service-linked role that AWS Elastic Disaster
    Recovery (DRS) initialization requires.
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
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
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

```
module "drs_initialization" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/drs/initialization"
}
```

### Skipping Roles Already Created by the Console

```
module "drs_initialization" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/drs/initialization"

  # DRS was already initialized through the console in this account/region; only manage
  # the service-linked role's lifecycle here, not the six service roles.
  create_service_roles = false
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- This module creates the seven IAM identities AWS documents in
  [Elastic Disaster Recovery initialization and permissions](https://docs.aws.amazon.com/drs/latest/userguide/getting-started-initializing.html):
  the six named service roles (`AWSElasticDisasterRecoveryAgentRole`, `AWSElasticDisasterRecoveryFailbackRole`,
  `AWSElasticDisasterRecoveryConversionServerRole`, `AWSElasticDisasterRecoveryRecoveryInstanceRole`,
  `AWSElasticDisasterRecoveryRecoveryInstanceWithLaunchActionsRole`,
  `AWSElasticDisasterRecoveryReplicationServerRole`) plus the `AWSServiceRoleForElasticDisasterRecovery`
  service-linked role.
- It does **not** call the `drs:InitializeService` API. There is no Terraform resource for that action; after
  applying this module (or confirming these identities already exist), you must still run
  `aws drs initialize-service` once per account per region, or visit the DRS console, before creating any
  replication configuration templates.
- In an account that has already been initialized through the DRS console, the role names below are already
  taken. Set `create_service_roles = false` and/or `create_service_linked_role = false` to avoid a naming
  collision, since AWS allows only one service-linked role per service per account.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- The six service roles are created through `modules/aws/iam/role` rather than inline `aws_iam_role` resources,
  per this repository's composition convention.
- `AWSElasticDisasterRecoveryAgentRole` and `AWSElasticDisasterRecoveryFailbackRole` trust `drs.amazonaws.com`
  with an `sts:SetSourceIdentity` action and a `StringLike` condition scoping `sts:SourceIdentity` to `s-*` /
  `i-*` respectively and `aws:SourceAccount` to the calling account. This is the confused-deputy guard AWS
  documents for these two roles; do not remove it when customizing this module.
- The four roles assumed by EC2 (conversion server, recovery instance, recovery instance with launch actions,
  and replication server) each get a matching `aws_iam_instance_profile`, matching what console-driven
  initialization creates automatically.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_role"></a> [role](#module\_role) | ../../iam/role | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_service_linked_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_policy_arns"></a> [additional\_policy\_arns](#input\_additional\_policy\_arns) | (Optional) Extra managed policy ARNs to attach on top of the AWS managed policies this module already attaches, keyed by DRS role name. Keys must be one of the six role names this module manages. | `map(list(string))` | `{}` | no |
| <a name="input_create_service_linked_role"></a> [create\_service\_linked\_role](#input\_create\_service\_linked\_role) | (Optional) Whether to create the AWSServiceRoleForElasticDisasterRecovery service-linked role. Set this to false in an account where the role already exists, since AWS allows only one service-linked role per service per account. | `bool` | `true` | no |
| <a name="input_create_service_roles"></a> [create\_service\_roles](#input\_create\_service\_roles) | (Optional) Whether to create the six Elastic Disaster Recovery service roles and their instance profiles. Set this to false in an account that has already been initialized through the DRS console, since the role names are fixed and would otherwise collide. | `bool` | `true` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | (Optional) Maximum session duration, in seconds, for each Elastic Disaster Recovery service role. Must be between 3600 and 43200. | `number` | `3600` | no |
| <a name="input_path"></a> [path](#input\_path) | (Optional) IAM path applied to the Elastic Disaster Recovery service roles and instance profiles. AWS documents /service-role/ for these roles; changing it is not recommended. | `string` | `"/service-role/"` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | (Optional) ARN of the policy used to set the permissions boundary on each Elastic Disaster Recovery service role. | `string` | `null` | no |
| <a name="input_service_linked_role_description"></a> [service\_linked\_role\_description](#input\_service\_linked\_role\_description) | (Optional) Description applied to the AWSServiceRoleForElasticDisasterRecovery service-linked role. | `string` | `"Service-linked role for AWS Elastic Disaster Recovery."` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags merged with a Name tag and applied to each role, instance profile, and the service-linked role. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_instance_profile_arns"></a> [instance\_profile\_arns](#output\_instance\_profile\_arns) | Map of instance profile ARNs for the EC2-assumed Elastic Disaster Recovery roles, keyed by role name. Empty when create\_service\_roles is false. |
| <a name="output_instance_profile_names"></a> [instance\_profile\_names](#output\_instance\_profile\_names) | Map of instance profile names for the EC2-assumed Elastic Disaster Recovery roles, keyed by role name. Empty when create\_service\_roles is false. |
| <a name="output_role_arns"></a> [role\_arns](#output\_role\_arns) | Map of Elastic Disaster Recovery service role ARNs, keyed by role name. Empty when create\_service\_roles is false. |
| <a name="output_role_names"></a> [role\_names](#output\_role\_names) | Map of Elastic Disaster Recovery service role names, keyed by role name. Empty when create\_service\_roles is false. |
| <a name="output_service_linked_role_arn"></a> [service\_linked\_role\_arn](#output\_service\_linked\_role\_arn) | ARN of the AWSServiceRoleForElasticDisasterRecovery service-linked role, or null when create\_service\_linked\_role is false. |
| <a name="output_service_linked_role_name"></a> [service\_linked\_role\_name](#output\_service\_linked\_role\_name) | Name of the AWSServiceRoleForElasticDisasterRecovery service-linked role, or null when create\_service\_linked\_role is false. |
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
