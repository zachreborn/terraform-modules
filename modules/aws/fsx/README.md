<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
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

<h3 align="center">FSx for Windows File Server</h3>
  <p align="center">
    This module creates an Amazon FSx for Windows File Server file system with a dedicated KMS key and optional CloudWatch audit logging.
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

### Self-managed Active Directory

```hcl
module "fsx_windows" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/fsx"

  name                = "corp-file-share"
  deployment_type     = "MULTI_AZ_1"
  storage_capacity    = 2048
  throughput_capacity = 64
  subnet_ids          = ["subnet-0a1b2c3d", "subnet-4e5f6g7h"]
  preferred_subnet_id = "subnet-0a1b2c3d"
  security_group_ids  = ["sg-0123456789abcdef0"]

  self_managed_active_directory = {
    dns_ips                                = ["10.11.1.100", "10.11.2.100"]
    domain_name                            = "corp.example.com"
    username                               = "FSxServiceAccount"
    password                               = var.fsx_service_account_password
    organizational_unit_distinguished_name = "OU=FSx,DC=corp,DC=example,DC=com"
  }

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

### AWS Managed Microsoft AD with a caller-supplied KMS key

```hcl
module "fsx_windows" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/fsx"

  name                = "corp-file-share"
  subnet_ids          = ["subnet-0a1b2c3d"]
  active_directory_id = "d-0123456789"

  create_kms_key = false
  kms_key_id     = "arn:aws:kms:us-east-1:111122223333:key/abcd1234-..."

  enable_audit_logs = false
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- A VPC with one subnet (SINGLE_AZ deployments) or two subnets (MULTI_AZ_1) reachable by your clients.
- An Active Directory the file system can join — either an AWS Managed Microsoft AD (supply `active_directory_id`) or a self-managed AD (supply `self_managed_active_directory`). Exactly one must be provided.
- For self-managed AD: a service account with permission to join machines to the domain, and DNS server IPs reachable from the file system subnets.
- Security group(s) permitting the SMB/Windows ports between clients and the file system network interfaces.

## Notes / Design Decisions

- **Active Directory is required by FSx.** Provide either `active_directory_id` (AWS Managed Microsoft AD) or the `self_managed_active_directory` object — never both. The provider rejects a file system with neither.
- **KMS by composition.** A dedicated customer-managed key is created via the `../kms` child module by default (`create_kms_key = true`). The key policy grants the FSx and CloudWatch Logs service principals the access they need. Set `create_kms_key = false` and pass `kms_key_id` to bring your own key.
- **Audit logging is optional but on by default.** When `enable_audit_logs = true` a CloudWatch log group is created via the `../cloudwatch/log_group` child module and the `audit_log_configuration` block is attached. When disabled, the block is omitted entirely so no log group is required.
- **Secure defaults.** Encryption at rest is always enabled, automatic backups default to 7 days, and audit logging defaults to `SUCCESS_AND_FAILURE`.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.53.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_audit_log_group"></a> [audit\_log\_group](#module\_audit\_log\_group) | ../cloudwatch/log_group | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../kms | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_fsx_windows_file_system.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fsx_windows_file_system) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_active_directory_id"></a> [active\_directory\_id](#input\_active\_directory\_id) | (Optional) The ID for an existing AWS Managed Microsoft Active Directory (Directory Service) instance that the file system should join. Conflicts with self\_managed\_active\_directory. Exactly one Active Directory configuration (this or self\_managed\_active\_directory) must be provided. | `string` | `null` | no |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | (Optional) A list of DNS alias names that you want to associate with the Amazon FSx file system. For more information, see Working with DNS Aliases. | `list(string)` | `null` | no |
| <a name="input_automatic_backup_retention_days"></a> [automatic\_backup\_retention\_days](#input\_automatic\_backup\_retention\_days) | (Optional) The number of days to retain automatic backups. Minimum of 0 and maximum of 90. Set to 0 to disable automatic backups. Defaults to 7. | `number` | `7` | no |
| <a name="input_backup_id"></a> [backup\_id](#input\_backup\_id) | (Optional) The ID of the source backup to create the file system from. | `string` | `null` | no |
| <a name="input_cloudwatch_name_prefix"></a> [cloudwatch\_name\_prefix](#input\_cloudwatch\_name\_prefix) | (Optional) Name prefix for the CloudWatch log group that receives FSx audit logs. FSx requires the prefix to begin with /aws/fsx/. Defaults to /aws/fsx/windows\_audit\_. | `string` | `"/aws/fsx/windows_audit_"` | no |
| <a name="input_cloudwatch_retention_in_days"></a> [cloudwatch\_retention\_in\_days](#input\_cloudwatch\_retention\_in\_days) | (Optional) Number of days to retain audit log events in the CloudWatch log group. Set to 0 to retain indefinitely. Defaults to 90. | `number` | `90` | no |
| <a name="input_copy_tags_to_backups"></a> [copy\_tags\_to\_backups](#input\_copy\_tags\_to\_backups) | (Optional) A boolean flag indicating whether tags on the file system should be copied to backups. Defaults to true. | `bool` | `true` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | (Optional) Determines whether this module creates a dedicated KMS key (via the kms child module) to encrypt the file system and audit logs. Set to false to supply your own key via kms\_key\_id. Defaults to true. | `bool` | `true` | no |
| <a name="input_daily_automatic_backup_start_time"></a> [daily\_automatic\_backup\_start\_time](#input\_daily\_automatic\_backup\_start\_time) | (Optional) The preferred time (in HH:MM format) to take daily automatic backups, in the UTC time zone. Defaults to 23:59. | `string` | `"23:59"` | no |
| <a name="input_deployment_type"></a> [deployment\_type](#input\_deployment\_type) | (Optional) Specifies the file system deployment type. Valid values are MULTI\_AZ\_1, SINGLE\_AZ\_1, and SINGLE\_AZ\_2. Defaults to SINGLE\_AZ\_1. | `string` | `"SINGLE_AZ_1"` | no |
| <a name="input_disk_iops_configuration"></a> [disk\_iops\_configuration](#input\_disk\_iops\_configuration) | (Optional) Configures the SSD IOPS provisioning for the file system. mode is AUTOMATIC (Amazon FSx automatically sizes and includes the IOPS, and does not bill separately for them) or USER\_PROVISIONED (you set iops and are billed for the provisioned amount). iops is the total provisioned SSD IOPS and is required when mode is USER\_PROVISIONED. If null, Amazon FSx applies the AUTOMATIC default. | <pre>object({<br/>    iops = optional(number)<br/>    mode = optional(string, "AUTOMATIC")<br/>  })</pre> | `null` | no |
| <a name="input_enable_audit_logs"></a> [enable\_audit\_logs](#input\_enable\_audit\_logs) | (Optional) Determines whether a CloudWatch log group is created and file/file-share access auditing is enabled on the file system. Defaults to true. | `bool` | `true` | no |
| <a name="input_file_access_audit_log_level"></a> [file\_access\_audit\_log\_level](#input\_file\_access\_audit\_log\_level) | (Optional) Sets which attempt type is logged by Amazon FSx for file and folder accesses. Valid values are SUCCESS\_ONLY, FAILURE\_ONLY, SUCCESS\_AND\_FAILURE, and DISABLED. Defaults to SUCCESS\_AND\_FAILURE. | `string` | `"SUCCESS_AND_FAILURE"` | no |
| <a name="input_file_share_access_audit_log_level"></a> [file\_share\_access\_audit\_log\_level](#input\_file\_share\_access\_audit\_log\_level) | (Optional) Sets which attempt type is logged by Amazon FSx for file share accesses. Valid values are SUCCESS\_ONLY, FAILURE\_ONLY, SUCCESS\_AND\_FAILURE, and DISABLED. Defaults to SUCCESS\_AND\_FAILURE. | `string` | `"SUCCESS_AND_FAILURE"` | no |
| <a name="input_final_backup_tags"></a> [final\_backup\_tags](#input\_final\_backup\_tags) | (Optional) A map of tags to apply to the file system's final backup. Only applied when skip\_final\_backup is false. | `map(string)` | `null` | no |
| <a name="input_kms_key_deletion_window_in_days"></a> [kms\_key\_deletion\_window\_in\_days](#input\_kms\_key\_deletion\_window\_in\_days) | (Optional) Duration in days after which the KMS key is deleted after destruction of the resource. Must be between 7 and 30 days. Defaults to 30. | `number` | `30` | no |
| <a name="input_kms_key_description"></a> [kms\_key\_description](#input\_kms\_key\_description) | (Optional) The description applied to the KMS key created by this module. | `string` | `"KMS key used to encrypt Amazon FSx for Windows File Server data at rest and its audit logs."` | no |
| <a name="input_kms_key_enable_key_rotation"></a> [kms\_key\_enable\_key\_rotation](#input\_kms\_key\_enable\_key\_rotation) | (Optional) Specifies whether automatic key rotation is enabled on the KMS key created by this module. Defaults to true. | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) ARN of an existing KMS key used to encrypt the file system and audit logs. Required when create\_kms\_key is false. | `string` | `null` | no |
| <a name="input_kms_key_name_prefix"></a> [kms\_key\_name\_prefix](#input\_kms\_key\_name\_prefix) | (Optional) Creates a unique KMS alias beginning with the specified prefix. The alias/ prefix is added automatically if omitted. | `string` | `"fsx_windows"` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The value of the Name tag applied to the file system and used as a friendly identifier. | `string` | n/a | yes |
| <a name="input_preferred_subnet_id"></a> [preferred\_subnet\_id](#input\_preferred\_subnet\_id) | (Optional) Specifies the subnet in which you want the preferred file server to be located. Required when deployment\_type is MULTI\_AZ\_1. | `string` | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | (Optional) A list of IDs for the security groups that apply to the specified network interfaces created for file system access. These security groups apply to all network interfaces. | `list(string)` | `null` | no |
| <a name="input_self_managed_active_directory"></a> [self\_managed\_active\_directory](#input\_self\_managed\_active\_directory) | (Optional) Configuration block for joining the file system to a self-managed Active Directory. Conflicts with active\_directory\_id. dns\_ips is a list of up to two DNS server/domain controller IPs; domain\_name is the fully qualified domain name; file\_system\_administrators\_group defaults to Domain Admins; organizational\_unit\_distinguished\_name is the OU the file system joins (e.g. OU=FSx,DC=example,DC=com). Supply exactly one credential method: domain\_join\_service\_account\_secret (the ARN of a Secrets Manager secret containing the service account credentials — the state-safe option), or username together with exactly one of password (persisted in Terraform state in plaintext — supply it from a secret store and protect state access accordingly) or password\_wo (a write-only argument that is never persisted to state; requires password\_wo\_version, and bump that version to rotate the password). | <pre>object({<br/>    dns_ips                                = list(string)<br/>    domain_name                            = string<br/>    domain_join_service_account_secret     = optional(string)<br/>    file_system_administrators_group       = optional(string, "Domain Admins")<br/>    organizational_unit_distinguished_name = optional(string)<br/>    password                               = optional(string)<br/>    password_wo                            = optional(string)<br/>    password_wo_version                    = optional(number)<br/>    username                               = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_skip_final_backup"></a> [skip\_final\_backup](#input\_skip\_final\_backup) | (Optional) When enabled, will skip the default final backup taken when the file system is deleted. Defaults to false. | `bool` | `false` | no |
| <a name="input_storage_capacity"></a> [storage\_capacity](#input\_storage\_capacity) | (Optional) Storage capacity (GiB) of the file system. Minimum of 32 and maximum of 65536. If the storage type is set to HDD the minimum value is 2000. Required when not creating the file system from a backup. Defaults to 32. | `number` | `32` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | (Optional) Specifies the storage type. Valid values are SSD and HDD. HDD is supported on SINGLE\_AZ\_2 and MULTI\_AZ\_1 deployment types. Defaults to SSD. | `string` | `"SSD"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | (Required) A list of IDs for the subnets that the file system will be accessible from. For SINGLE\_AZ deployments provide a single subnet; for MULTI\_AZ\_1 provide two subnets and set preferred\_subnet\_id. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_throughput_capacity"></a> [throughput\_capacity](#input\_throughput\_capacity) | (Optional) Throughput (megabytes per second) of the file system, in power of 2 increments. Minimum of 8 and maximum of 2048. Defaults to 32. | `number` | `32` | no |
| <a name="input_weekly_maintenance_start_time"></a> [weekly\_maintenance\_start\_time](#input\_weekly\_maintenance\_start\_time) | (Optional) The preferred start time (in d:HH:MM format) to perform weekly maintenance, in the UTC time zone. Defaults to 1:01:00. | `string` | `"1:01:00"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) of the file system. Used as the location\_arn when associating the file system with an FSx File Gateway. |
| <a name="output_audit_log_group_arn"></a> [audit\_log\_group\_arn](#output\_audit\_log\_group\_arn) | The ARN of the CloudWatch log group receiving FSx audit logs, or null when audit logging is disabled. |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | The DNS name for the file system. |
| <a name="output_id"></a> [id](#output\_id) | The identifier of the FSx for Windows File Server file system. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the KMS key used to encrypt the file system and audit logs. |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The key ID of the KMS key created by this module, or null when a caller-supplied key is used. |
| <a name="output_network_interface_ids"></a> [network\_interface\_ids](#output\_network\_interface\_ids) | The set of Elastic Network Interface IDs from which the file system is accessible. |
| <a name="output_owner_id"></a> [owner\_id](#output\_owner\_id) | The AWS account identifier that owns the file system. |
| <a name="output_preferred_file_server_ip"></a> [preferred\_file\_server\_ip](#output\_preferred\_file\_server\_ip) | The IP address of the primary, or preferred, file server. Use this IP for SMB clients that connect by IP rather than DNS name. |
| <a name="output_remote_administration_endpoint"></a> [remote\_administration\_endpoint](#output\_remote\_administration\_endpoint) | For MULTI\_AZ\_1 deployment types, use this endpoint when performing administrative tasks on the file system using Amazon FSx Remote PowerShell. For SINGLE\_AZ\_1 and SINGLE\_AZ\_2 deployment types, this is the DNS name of the file system. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The identifier of the Virtual Private Cloud for the file system. |
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
