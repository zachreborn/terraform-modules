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

<h3 align="center">Storage Gateway (FSx File Gateway)</h3>
  <p align="center">
    This module registers an AWS Storage Gateway file gateway and manages its cache disks and Amazon FSx for Windows File Server associations.
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

### FSx File Gateway associating an FSx for Windows file system

```hcl
module "storage_gateway" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/storage_gateway"

  gateway_name     = "corp-file-gateway"
  gateway_type     = "FILE_FSX_SMB"
  gateway_timezone = "GMT-7:00"
  gateway_ip_address = "10.20.30.40" # or supply activation_key instead

  smb_active_directory_settings = {
    domain_name = "corp.example.com"
    username    = "GatewayServiceAccount"
    password    = var.gateway_service_account_password
  }

  # Local disks presented to the gateway VM, discovered via the
  # aws_storagegateway_local_disk data source.
  cache_disk_ids = ["/dev/sdb"]

  file_system_associations = {
    corp = {
      location_arn = module.fsx_windows.arn
      username     = "CORP\\FSxAdmin"
      password     = var.fsx_association_password
      cache_attributes = {
        cache_stale_timeout_in_seconds = 300
      }
    }
  }

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

> **Manual step — deploy and power on the gateway VM first.** The AWS resources in this module cannot be created until the on-premises Storage Gateway appliance exists. Deploy the Storage Gateway VM on your hypervisor (e.g. Hyper-V), attach a cache disk, and power it on. Then either:
>
> - retrieve its **activation key** (from the VM's local web UI or by letting AWS connect to it) and pass it as `activation_key`, **or**
> - pass the VM's reachable IP as `gateway_ip_address` and let the provider fetch the activation key during apply.
>
> Exactly one of `activation_key` or `gateway_ip_address` must be supplied.

- An Amazon FSx for Windows File Server file system to associate (its ARN feeds `file_system_associations[*].location_arn` — e.g. the `arn` output of the `fsx` module). FSx file system associations require `gateway_type = FILE_FSX_SMB`.
- A domain user with access to the FSx file system for each association, and (for SMB) Active Directory join settings via `smb_active_directory_settings`.
- One or more local disks presented to the gateway VM to serve as cache, identified via the `aws_storagegateway_local_disk` data source.

## Notes / Design Decisions

- **AWS-side only.** This module manages the AWS resources: gateway registration/activation, cache disk allocation, FSx file system associations, and an optional CloudWatch log group (with KMS) for gateway health logs. Deploying and activating the on-premises VM is a manual prerequisite by design.
- **File gateways only.** `gateway_type` is restricted to `FILE_FSX_SMB` and `FILE_S3`. TAPE/VTL gateway arguments (`tape_drive_type`, `medium_changer_type`) are intentionally out of scope for this module.
- **FSx association requires FILE_FSX_SMB.** `aws_storagegateway_file_system_association` only supports FSx for Windows File Server, so set `gateway_type = FILE_FSX_SMB` when supplying `file_system_associations`. This gateway type cannot front FSx for NetApp ONTAP.
- **Logging by composition.** When `create_cloudwatch_log_group = true`, a log group is created via the `../cloudwatch/log_group` child module and, when `create_kms_key = true`, encrypted with a key from the `../kms` child module. Supply `cloudwatch_log_group_arn` to use an existing log group instead.
- **Credentials in state.** `activation_key`, `smb_guest_password`, the AD service-account password, and each association password are persisted in Terraform state in plaintext. Supply them from a secret store and protect state access accordingly.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.51.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cloudwatch_log_group"></a> [cloudwatch\_log\_group](#module\_cloudwatch\_log\_group) | ../cloudwatch/log_group | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../kms | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_storagegateway_cache.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/storagegateway_cache) | resource |
| [aws_storagegateway_file_system_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/storagegateway_file_system_association) | resource |
| [aws_storagegateway_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/storagegateway_gateway) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_activation_key"></a> [activation\_key](#input\_activation\_key) | (Optional) Gateway activation key obtained after deploying and powering on the on-premises gateway VM. Mutually exclusive with gateway\_ip\_address; supply exactly one. Use this when you have already retrieved the activation key out of band. Stored in Terraform state in plaintext. | `string` | `null` | no |
| <a name="input_average_download_rate_limit_in_bits_per_sec"></a> [average\_download\_rate\_limit\_in\_bits\_per\_sec](#input\_average\_download\_rate\_limit\_in\_bits\_per\_sec) | (Optional) The average download bandwidth rate limit in bits per second. Defaults to null (no limit). | `number` | `null` | no |
| <a name="input_average_upload_rate_limit_in_bits_per_sec"></a> [average\_upload\_rate\_limit\_in\_bits\_per\_sec](#input\_average\_upload\_rate\_limit\_in\_bits\_per\_sec) | (Optional) The average upload bandwidth rate limit in bits per second. Defaults to null (no limit). | `number` | `null` | no |
| <a name="input_cache_disk_ids"></a> [cache\_disk\_ids](#input\_cache\_disk\_ids) | (Optional) Set of local disk IDs (as reported by the gateway, e.g. via the aws\_storagegateway\_local\_disk data source) to allocate as cache storage. Defaults to an empty set. | `set(string)` | `[]` | no |
| <a name="input_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#input\_cloudwatch\_log\_group\_arn) | (Optional) ARN of an existing CloudWatch log group to use for gateway health logs. When null and create\_cloudwatch\_log\_group is true, this module creates one. Defaults to null. | `string` | `null` | no |
| <a name="input_cloudwatch_name_prefix"></a> [cloudwatch\_name\_prefix](#input\_cloudwatch\_name\_prefix) | (Optional) Name prefix for the CloudWatch log group created for gateway health logs. Defaults to /aws/storagegateway/. | `string` | `"/aws/storagegateway/"` | no |
| <a name="input_cloudwatch_retention_in_days"></a> [cloudwatch\_retention\_in\_days](#input\_cloudwatch\_retention\_in\_days) | (Optional) Number of days to retain gateway log events in the CloudWatch log group. Set to 0 to retain indefinitely. Defaults to 90. | `number` | `90` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | (Optional) Determines whether this module creates a CloudWatch log group (via the cloudwatch/log\_group child module) for gateway health logs and wires it to the gateway. Ignored when cloudwatch\_log\_group\_arn is supplied. Defaults to true. | `bool` | `true` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | (Optional) Determines whether this module creates a dedicated KMS key (via the kms child module) to encrypt the CloudWatch log group. Used only when create\_cloudwatch\_log\_group is true. Set to false to supply your own key via kms\_key\_id. Defaults to true. | `bool` | `true` | no |
| <a name="input_file_system_associations"></a> [file\_system\_associations](#input\_file\_system\_associations) | (Optional) Map of FSx for Windows File Server associations keyed by a logical name. Per association: location\_arn (the FSx for Windows file system ARN — e.g. the arn output of the fsx module), username/password (a domain user with access to the file system; password is stored in state in plaintext), optional audit\_destination\_arn (CloudWatch log group ARN for SMB audit logs), and an optional cache\_attributes block with cache\_stale\_timeout\_in\_seconds. Requires gateway\_type FILE\_FSX\_SMB. Defaults to {}. | <pre>map(object({<br/>    location_arn          = string<br/>    password              = string<br/>    username              = string<br/>    audit_destination_arn = optional(string)<br/>    cache_attributes = optional(object({<br/>      cache_stale_timeout_in_seconds = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_gateway_ip_address"></a> [gateway\_ip\_address](#input\_gateway\_ip\_address) | (Optional) IP address of the gateway VM, used to fetch the activation key automatically during apply. Mutually exclusive with activation\_key; supply exactly one. The VM must be reachable from where Terraform runs. Defaults to null. | `string` | `null` | no |
| <a name="input_gateway_name"></a> [gateway\_name](#input\_gateway\_name) | (Required) Name of the gateway. Also used as the Name tag. | `string` | n/a | yes |
| <a name="input_gateway_timezone"></a> [gateway\_timezone](#input\_gateway\_timezone) | (Optional) Time zone for the gateway, in the format GMT, GMT-hh:mm, or GMT+hh:mm (e.g. GMT-7:00). Defaults to GMT. | `string` | `"GMT"` | no |
| <a name="input_gateway_type"></a> [gateway\_type](#input\_gateway\_type) | (Optional) Type of the gateway. This module manages file gateways, so valid values are FILE\_FSX\_SMB and FILE\_S3. Defaults to FILE\_FSX\_SMB. File system associations require FILE\_FSX\_SMB. | `string` | `"FILE_FSX_SMB"` | no |
| <a name="input_gateway_vpc_endpoint"></a> [gateway\_vpc\_endpoint](#input\_gateway\_vpc\_endpoint) | (Optional) VPC endpoint DNS name to use for the gateway's connection to the Storage Gateway service when using a private (VPC) endpoint. Defaults to null. | `string` | `null` | no |
| <a name="input_kms_key_deletion_window_in_days"></a> [kms\_key\_deletion\_window\_in\_days](#input\_kms\_key\_deletion\_window\_in\_days) | (Optional) Duration in days after which the KMS key is deleted after destruction of the resource. Must be between 7 and 30 days. Defaults to 30. | `number` | `30` | no |
| <a name="input_kms_key_description"></a> [kms\_key\_description](#input\_kms\_key\_description) | (Optional) The description applied to the KMS key created by this module. | `string` | `"KMS key used to encrypt AWS Storage Gateway CloudWatch logs."` | no |
| <a name="input_kms_key_enable_key_rotation"></a> [kms\_key\_enable\_key\_rotation](#input\_kms\_key\_enable\_key\_rotation) | (Optional) Specifies whether automatic key rotation is enabled on the KMS key created by this module. Defaults to true. | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) ARN of an existing KMS key used to encrypt the CloudWatch log group. Used only when create\_kms\_key is false. Defaults to null (the log group is unencrypted by a customer-managed key). | `string` | `null` | no |
| <a name="input_kms_key_name_prefix"></a> [kms\_key\_name\_prefix](#input\_kms\_key\_name\_prefix) | (Optional) Creates a unique KMS alias beginning with the specified prefix. The alias/ prefix is added automatically if omitted. | `string` | `"storage_gateway"` | no |
| <a name="input_maintenance_start_time"></a> [maintenance\_start\_time](#input\_maintenance\_start\_time) | (Optional) Weekly or monthly maintenance window. hour\_of\_day (0-23) and minute\_of\_hour (0-59); day\_of\_week (0-6, Sunday=0) for a weekly window or day\_of\_month (1-28) for a monthly window. Defaults to null, which lets the gateway pick a window. | <pre>object({<br/>    hour_of_day    = number<br/>    minute_of_hour = optional(number)<br/>    day_of_week    = optional(number)<br/>    day_of_month   = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_smb_active_directory_settings"></a> [smb\_active\_directory\_settings](#input\_smb\_active\_directory\_settings) | (Optional) Microsoft Active Directory join settings for SMB access. Required to associate an FSx for Windows file system on a FILE\_FSX\_SMB gateway. domain\_name, username, and password are the join credentials; domain\_controllers, organizational\_unit, and timeout\_in\_seconds are optional. The password is stored in Terraform state in plaintext. Defaults to null. | <pre>object({<br/>    domain_name         = string<br/>    password            = string<br/>    username            = string<br/>    domain_controllers  = optional(list(string))<br/>    organizational_unit = optional(string)<br/>    timeout_in_seconds  = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_smb_file_share_visibility"></a> [smb\_file\_share\_visibility](#input\_smb\_file\_share\_visibility) | (Optional) Whether file shares on this gateway are visible when listing shares for the gateway's domain. Defaults to null, which uses the service default. | `bool` | `null` | no |
| <a name="input_smb_guest_password"></a> [smb\_guest\_password](#input\_smb\_guest\_password) | (Optional) Guest password for guest access to SMB file shares. Stored in Terraform state in plaintext. Defaults to null. | `string` | `null` | no |
| <a name="input_smb_security_strategy"></a> [smb\_security\_strategy](#input\_smb\_security\_strategy) | (Optional) Specifies the type of security strategy for the gateway. Valid values are ClientSpecified, MandatorySigning, and MandatoryEncryption. Defaults to null, which uses the service default. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cache_disk_ids"></a> [cache\_disk\_ids](#output\_cache\_disk\_ids) | The set of local disk IDs allocated as cache storage on the gateway. |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | The ARN of the CloudWatch log group used for gateway health logs, or null when none is created or supplied. |
| <a name="output_ec2_instance_id"></a> [ec2\_instance\_id](#output\_ec2\_instance\_id) | The ID of the EC2 instance backing the gateway, when the gateway runs on EC2. |
| <a name="output_file_system_association_arns"></a> [file\_system\_association\_arns](#output\_file\_system\_association\_arns) | Map of file system association logical names to their ARNs. |
| <a name="output_gateway_arn"></a> [gateway\_arn](#output\_gateway\_arn) | The Amazon Resource Name (ARN) of the Storage Gateway. |
| <a name="output_gateway_id"></a> [gateway\_id](#output\_gateway\_id) | The identifier of the Storage Gateway. |
| <a name="output_gateway_network_interface"></a> [gateway\_network\_interface](#output\_gateway\_network\_interface) | The network interfaces of the gateway. |
| <a name="output_host_environment"></a> [host\_environment](#output\_host\_environment) | The type of hypervisor environment used by the gateway host. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the KMS key used to encrypt the gateway log group, or null when none is used. |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The key ID of the KMS key created by this module, or null when none is created. |
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
