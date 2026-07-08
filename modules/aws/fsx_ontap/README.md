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

<h3 align="center">FSx for NetApp ONTAP</h3>
  <p align="center">
    This module creates an Amazon FSx for NetApp ONTAP file system with a dedicated KMS key, and any number of Storage Virtual Machines and volumes.
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

### Multi-AZ file system with an SMB SVM and two volumes

```hcl
module "fsx_ontap" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/fsx_ontap"

  name                = "corp-ontap"
  deployment_type     = "MULTI_AZ_1"
  storage_capacity    = 2048
  throughput_capacity = 512
  subnet_ids          = ["subnet-0a1b2c3d", "subnet-4e5f6g7h"]
  preferred_subnet_id = "subnet-0a1b2c3d"
  route_table_ids     = ["rtb-0123456789abcdef0"]
  security_group_ids  = ["sg-0123456789abcdef0"]
  fsx_admin_password  = var.fsx_admin_password

  storage_virtual_machines = {
    corp = {
      root_volume_security_style = "NTFS"
      svm_admin_password         = var.svm_admin_password
      active_directory_configuration = {
        netbios_name = "CORP-ONTAP"
        self_managed_active_directory_configuration = {
          dns_ips                                 = ["10.11.1.100", "10.11.2.100"]
          domain_name                             = "corp.example.com"
          username                                = "FSxServiceAccount"
          password                                = var.fsx_service_account_password
          organizational_unit_distinguished_name = "OU=FSx,DC=corp,DC=example,DC=com"
        }
      }
    }
  }

  volumes = {
    sales = {
      storage_virtual_machine_key = "corp"
      junction_path               = "/sales"
      size_in_megabytes           = 1048576
      security_style              = "NTFS"
      tiering_policy = {
        name           = "AUTO"
        cooling_period = 31
      }
    }
    engineering = {
      storage_virtual_machine_key = "corp"
      junction_path               = "/engineering"
      size_in_megabytes           = 2097152
      security_style              = "NTFS"
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

- A VPC with one subnet (SINGLE_AZ deployments) or two subnets (MULTI_AZ deployments) reachable by your clients.
- For MULTI_AZ deployments: the route table IDs that should carry traffic to the file system's floating endpoint IPs, and (optionally) an `endpoint_ip_address_range` outside the VPC CIDR.
- For SMB access: a self-managed Active Directory the SVM can join, including a service account with domain-join permission and reachable DNS server IPs.
- Security group(s) permitting the relevant NFS/SMB/iSCSI and ONTAP management ports between clients and the file system.

## Notes / Design Decisions

- **Scales via maps.** The module creates one file system, then any number of Storage Virtual Machines (`storage_virtual_machines`) and volumes (`volumes`) keyed by logical name. Each volume references its parent SVM by that SVM's map key via `storage_virtual_machine_key`.
- **SMB-first defaults.** `root_volume_security_style` and volume `security_style` default to `NTFS` because the common case here is migrating Windows SMB shares off on-prem NetApp. Set `UNIX` or `MIXED` for NFS or dual-protocol workloads.
- **KMS by composition.** A dedicated customer-managed key is created via the `../kms` child module by default. Set `create_kms_key = false` and pass `kms_key_id` to bring your own.
- **No CloudWatch audit log group.** Unlike FSx for Windows, the ONTAP file system resource has no AWS-managed audit-log destination — auditing is configured inside ONTAP — so this module does not create a log group.
- **Throughput.** Set exactly one of `throughput_capacity` or `throughput_capacity_per_ha_pair`, appropriate to your `deployment_type` (Gen 2 deployments and multi-HA-pair file systems require the per-HA-pair form).
- **Credentials in state.** `fsx_admin_password`, `svm_admin_password`, and the AD service-account password are persisted in Terraform state in plaintext. Supply them from a secret store and protect state access accordingly.

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
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../kms | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_fsx_ontap_file_system.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fsx_ontap_file_system) | resource |
| [aws_fsx_ontap_storage_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fsx_ontap_storage_virtual_machine) | resource |
| [aws_fsx_ontap_volume.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fsx_ontap_volume) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_automatic_backup_retention_days"></a> [automatic\_backup\_retention\_days](#input\_automatic\_backup\_retention\_days) | (Optional) The number of days to retain automatic backups. Minimum of 0 and maximum of 90. Set to 0 to disable automatic backups. Defaults to 7. | `number` | `7` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | (Optional) Determines whether this module creates a dedicated KMS key (via the kms child module) to encrypt the file system. Set to false to supply your own key via kms\_key\_id. Defaults to true. | `bool` | `true` | no |
| <a name="input_daily_automatic_backup_start_time"></a> [daily\_automatic\_backup\_start\_time](#input\_daily\_automatic\_backup\_start\_time) | (Optional) The preferred time (in HH:MM format) to take daily automatic backups, in the UTC time zone. Requires automatic\_backup\_retention\_days to be greater than 0. Defaults to 23:59. | `string` | `"23:59"` | no |
| <a name="input_deployment_type"></a> [deployment\_type](#input\_deployment\_type) | (Optional) The file system deployment type. Valid values are SINGLE\_AZ\_1, SINGLE\_AZ\_2, MULTI\_AZ\_1, and MULTI\_AZ\_2. Defaults to MULTI\_AZ\_1. | `string` | `"MULTI_AZ_1"` | no |
| <a name="input_disk_iops_configuration"></a> [disk\_iops\_configuration](#input\_disk\_iops\_configuration) | (Optional) The SSD IOPS configuration for the file system. mode is AUTOMATIC (provisions 3 IOPS per GB) or USER\_PROVISIONED; iops sets the total provisioned IOPS when mode is USER\_PROVISIONED. Defaults to null, which lets the provider apply AUTOMATIC. | <pre>object({<br/>    iops = optional(number)<br/>    mode = optional(string, "AUTOMATIC")<br/>  })</pre> | `null` | no |
| <a name="input_endpoint_ip_address_range"></a> [endpoint\_ip\_address\_range](#input\_endpoint\_ip\_address\_range) | (Optional) The IP address range in which the endpoints to access the file system are created. Only supported on MULTI\_AZ deployment types; must be outside the VPC CIDR. Defaults to null. | `string` | `null` | no |
| <a name="input_fsx_admin_password"></a> [fsx\_admin\_password](#input\_fsx\_admin\_password) | (Optional) The ONTAP administrative password for the fsxadmin user used to administer the file system via the ONTAP CLI/REST API. Stored in Terraform state in plaintext; supply from a secret store. Defaults to null. | `string` | `null` | no |
| <a name="input_ha_pairs"></a> [ha\_pairs](#input\_ha\_pairs) | (Optional) The number of high-availability (HA) pairs for the file system. Valid values are 1 through 12. Only Gen 2 SINGLE\_AZ deployments support more than 1. Defaults to null, which lets the provider apply its default of 1. | `number` | `null` | no |
| <a name="input_kms_key_deletion_window_in_days"></a> [kms\_key\_deletion\_window\_in\_days](#input\_kms\_key\_deletion\_window\_in\_days) | (Optional) Duration in days after which the KMS key is deleted after destruction of the resource. Must be between 7 and 30 days. Defaults to 30. | `number` | `30` | no |
| <a name="input_kms_key_description"></a> [kms\_key\_description](#input\_kms\_key\_description) | (Optional) The description applied to the KMS key created by this module. | `string` | `"KMS key used to encrypt Amazon FSx for NetApp ONTAP data at rest."` | no |
| <a name="input_kms_key_enable_key_rotation"></a> [kms\_key\_enable\_key\_rotation](#input\_kms\_key\_enable\_key\_rotation) | (Optional) Specifies whether automatic key rotation is enabled on the KMS key created by this module. Defaults to true. | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) ARN of an existing KMS key used to encrypt the file system. Required when create\_kms\_key is false. | `string` | `null` | no |
| <a name="input_kms_key_name_prefix"></a> [kms\_key\_name\_prefix](#input\_kms\_key\_name\_prefix) | (Optional) Creates a unique KMS alias beginning with the specified prefix. The alias/ prefix is added automatically if omitted. | `string` | `"fsx_ontap"` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The value of the Name tag applied to the file system and used as a friendly identifier. | `string` | n/a | yes |
| <a name="input_preferred_subnet_id"></a> [preferred\_subnet\_id](#input\_preferred\_subnet\_id) | (Required) The subnet in which the preferred file server is located. Must be one of the subnets listed in subnet\_ids. | `string` | n/a | yes |
| <a name="input_route_table_ids"></a> [route\_table\_ids](#input\_route\_table\_ids) | (Optional) A list of route table IDs that are associated with the file system. Used by MULTI\_AZ deployments so traffic to the floating endpoint IPs is routed correctly. Defaults to null. | `list(string)` | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | (Optional) A list of IDs for the security groups that apply to the network interfaces created for file system access. Defaults to null. | `list(string)` | `null` | no |
| <a name="input_storage_capacity"></a> [storage\_capacity](#input\_storage\_capacity) | (Required) The storage capacity (GiB) of the file system. Valid values are between 1024 and 1048576 GiB. | `number` | n/a | yes |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | (Optional) The storage type of the file system. The only valid value for FSx for NetApp ONTAP is SSD. Defaults to SSD. | `string` | `"SSD"` | no |
| <a name="input_storage_virtual_machines"></a> [storage\_virtual\_machines](#input\_storage\_virtual\_machines) | (Optional) Map of Storage Virtual Machines (SVMs) to create on the file system, keyed by a logical name. Per SVM: name (defaults to the map key), root\_volume\_security\_style (UNIX, NTFS, or MIXED — defaults to NTFS for SMB workloads), svm\_admin\_password (vsadmin password; stored in state in plaintext), and an optional active\_directory\_configuration for SMB access (netbios\_name plus a self-managed AD config block with dns\_ips, domain\_name, username, password, and optional file\_system\_administrators\_group and organizational\_unit\_distinguished\_name). Defaults to {}. | <pre>map(object({<br/>    name                       = optional(string)<br/>    root_volume_security_style = optional(string, "NTFS")<br/>    svm_admin_password         = optional(string)<br/>    active_directory_configuration = optional(object({<br/>      netbios_name = string<br/>      self_managed_active_directory_configuration = object({<br/>        dns_ips                                = list(string)<br/>        domain_name                            = string<br/>        password                               = string<br/>        username                               = string<br/>        file_system_administrators_group       = optional(string)<br/>        organizational_unit_distinguished_name = optional(string)<br/>      })<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | (Required) A list of subnet IDs the file system will be accessible from. Provide one subnet for SINGLE\_AZ deployments and two for MULTI\_AZ deployments (with preferred\_subnet\_id set). | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_throughput_capacity"></a> [throughput\_capacity](#input\_throughput\_capacity) | (Optional) The sustained throughput (MB/s) of the file system. Valid values are 128, 256, 512, 1024, 2048, and 4096. Conflicts with throughput\_capacity\_per\_ha\_pair; set exactly one. Defaults to null. | `number` | `null` | no |
| <a name="input_throughput_capacity_per_ha_pair"></a> [throughput\_capacity\_per\_ha\_pair](#input\_throughput\_capacity\_per\_ha\_pair) | (Optional) The sustained throughput (MB/s) per HA pair. Required for Gen 2 deployment types and when ha\_pairs is greater than 1. Valid values are 128, 256, 512, 1024, 2048, 3072, 4096, and 6144. Conflicts with throughput\_capacity; set exactly one. Defaults to null. | `number` | `null` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | (Optional) Map of ONTAP volumes to create, keyed by a logical name. Per volume: name (defaults to the map key), storage\_virtual\_machine\_key (the key of the SVM in storage\_virtual\_machines this volume belongs to), junction\_path (SMB/NFS mount path, e.g. /sales), and exactly one of size\_in\_megabytes (FlexVol) or size\_in\_bytes (FlexGroup, a string). Additional tunables: security\_style (UNIX, NTFS, or MIXED — defaults to NTFS), snapshot\_policy, storage\_efficiency\_enabled (dedup/compression, defaults to true), ontap\_volume\_type (RW or DP, defaults to RW), volume\_style (FLEXVOL or FLEXGROUP), volume\_type, skip\_final\_backup/copy\_tags\_to\_backups/final\_backup\_tags, and bypass\_snaplock\_enterprise\_retention. Optional blocks: tiering\_policy (name one of SNAPSHOT\_ONLY, AUTO, ALL, NONE; cooling\_period in days); aggregate\_configuration (aggregates and constituents\_per\_aggregate, for FlexGroup); and snaplock\_configuration for WORM (snaplock\_type COMPLIANCE or ENTERPRISE, plus optional privileged\_delete, audit\_log\_volume, volume\_append\_mode\_enabled, autocommit\_period, and retention\_period with default/maximum/minimum\_retention type+value pairs). Defaults to {}. | <pre>map(object({<br/>    name                                 = optional(string)<br/>    storage_virtual_machine_key          = string<br/>    junction_path                        = optional(string)<br/>    size_in_megabytes                    = optional(number)<br/>    size_in_bytes                        = optional(string)<br/>    security_style                       = optional(string, "NTFS")<br/>    snapshot_policy                      = optional(string)<br/>    storage_efficiency_enabled           = optional(bool, true)<br/>    ontap_volume_type                    = optional(string, "RW")<br/>    volume_style                         = optional(string)<br/>    volume_type                          = optional(string)<br/>    skip_final_backup                    = optional(bool, false)<br/>    copy_tags_to_backups                 = optional(bool, false)<br/>    bypass_snaplock_enterprise_retention = optional(bool, false)<br/>    final_backup_tags                    = optional(map(string))<br/>    tiering_policy = optional(object({<br/>      name           = string<br/>      cooling_period = optional(number)<br/>    }))<br/>    aggregate_configuration = optional(object({<br/>      aggregates                 = optional(list(string))<br/>      constituents_per_aggregate = optional(number)<br/>    }))<br/>    snaplock_configuration = optional(object({<br/>      snaplock_type              = string<br/>      audit_log_volume           = optional(bool)<br/>      privileged_delete          = optional(string)<br/>      volume_append_mode_enabled = optional(bool)<br/>      autocommit_period = optional(object({<br/>        type  = string<br/>        value = optional(number)<br/>      }))<br/>      retention_period = optional(object({<br/>        default_retention = optional(object({<br/>          type  = string<br/>          value = optional(number)<br/>        }))<br/>        maximum_retention = optional(object({<br/>          type  = string<br/>          value = optional(number)<br/>        }))<br/>        minimum_retention = optional(object({<br/>          type  = string<br/>          value = optional(number)<br/>        }))<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_weekly_maintenance_start_time"></a> [weekly\_maintenance\_start\_time](#input\_weekly\_maintenance\_start\_time) | (Optional) The preferred start time (in d:HH:MM format) to perform weekly maintenance, in the UTC time zone. Defaults to 1:01:00. | `string` | `"1:01:00"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) of the file system. |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | The DNS name for the file system. |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | The management and intercluster endpoints (DNS names and IP addresses) used to access and replicate the file system. |
| <a name="output_id"></a> [id](#output\_id) | The identifier of the FSx for NetApp ONTAP file system. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the KMS key used to encrypt the file system. |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The key ID of the KMS key created by this module, or null when a caller-supplied key is used. |
| <a name="output_network_interface_ids"></a> [network\_interface\_ids](#output\_network\_interface\_ids) | The set of Elastic Network Interface IDs from which the file system is accessible. |
| <a name="output_owner_id"></a> [owner\_id](#output\_owner\_id) | The AWS account identifier that owns the file system. |
| <a name="output_storage_virtual_machine_arns"></a> [storage\_virtual\_machine\_arns](#output\_storage\_virtual\_machine\_arns) | Map of Storage Virtual Machine logical names to their ARNs. |
| <a name="output_storage_virtual_machine_endpoints"></a> [storage\_virtual\_machine\_endpoints](#output\_storage\_virtual\_machine\_endpoints) | Map of Storage Virtual Machine logical names to their endpoints (iSCSI, management, NFS, and SMB DNS names and IP addresses). |
| <a name="output_storage_virtual_machine_ids"></a> [storage\_virtual\_machine\_ids](#output\_storage\_virtual\_machine\_ids) | Map of Storage Virtual Machine logical names to their IDs. |
| <a name="output_storage_virtual_machine_uuids"></a> [storage\_virtual\_machine\_uuids](#output\_storage\_virtual\_machine\_uuids) | Map of Storage Virtual Machine logical names to their UUIDs. |
| <a name="output_volume_arns"></a> [volume\_arns](#output\_volume\_arns) | Map of volume logical names to their ARNs. |
| <a name="output_volume_ids"></a> [volume\_ids](#output\_volume\_ids) | Map of volume logical names to their IDs. |
| <a name="output_volume_uuids"></a> [volume\_uuids](#output\_volume\_uuids) | Map of volume logical names to their UUIDs. |
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
