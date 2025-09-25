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

<h3 align="center">VeloCloud SDWAN Module</h3>
  <p align="center">
    This module deploys a VeloCloud SDWAN into your environment. Please see the <a href=https://docs.vmware.com/en/VMware-SD-WAN/index.html> VeloCloud documentation </a> for more information.
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

This example creates a VeloCloud vEdge instance in the VPC of your choosing. The instance will have a NIC in up to three subnets: public, private, and management. The public subnet will have an EIP attached to it. The instance will utilize the Velocloud variables to automatically activate against the Orchestrator.

```
module "aws_prod_sdwan" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vendor/velocloud"

    key_name                     = module.keypair.key_name
    public_subnet_ids            = module.vpc.public_subnet_ids
    private_subnet_ids           = module.vpc.private_subnet_ids
    velocloud_activation_keys    = ["1234-5678-90AB-CDEF"]
    velocloud_orchestrator       = "vco.example.com"
    velocloud_ignore_cert_errors = true
    velocloud_lan_cidr_blocks    = ["0.0.0.0/0"]
    vpc_id                       = module.vpc.vpc_id
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "aws_poc"
        backup      = "true"
        role        = "sdwan"
    }
}
```

### Custom AMI Example

This example creates a VeloCloud vEdge instance in the VPC of your choosing. The instance will have a NIC in up to three subnets: public, private, and management. The public subnet will have an EIP attached to it. The instance will utilize the Velocloud variables to automatically activate against the Orchestrator. The AMI ID is provided to use a custom AMI.

```
module "aws_prod_sdwan" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vendor/velocloud"

    ami_id                       = "ami-123456789e"
    key_name                     = module.keypair.key_name
    public_subnet_ids            = module.vpc.public_subnet_ids
    private_subnet_ids           = module.vpc.private_subnet_ids
    velocloud_activation_keys    = ["1234-5678-90AB-CDEF"]
    velocloud_orchestrator       = "vco.example.com"
    velocloud_ignore_cert_errors = true
    velocloud_lan_cidr_blocks    = ["0.0.0.0/0"]
    vpc_id                       = module.vpc.vpc_id
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "aws_poc"
        backup      = "true"
        role        = "sdwan"
    }
}
```

### Redundant vEdge's Example

This example creates two VeloCloud vEdge instance in the VPC of your choosing. The instances will have a NIC in up to three subnets: public, private, and management. The public subnet will have an EIP attached to it. The instances will utilize the Velocloud variables to automatically activate against the Orchestrator. The AMI ID is provided to use a custom AMI.

```
module "aws_prod_sdwan" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vendor/velocloud"

    ami_id                       = "ami-123456789e"
    key_name                     = module.keypair.key_name
    public_subnet_ids            = module.vpc.public_subnet_ids
    private_subnet_ids           = module.vpc.private_subnet_ids
    velocloud_activation_keys    = ["1234-5678-90AB-CDEF", "1234-5678-90AB-GHIJ"]
    velocloud_orchestrator       = "vco.example.com"
    velocloud_ignore_cert_errors = true
    velocloud_lan_cidr_blocks    = ["0.0.0.0/0"]
    vpc_id                       = module.vpc.vpc_id
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "aws_poc"
        backup      = "true"
        role        = "sdwan"
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
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 6.0.0 |

## Providers

| Name                                             | Version  |
| ------------------------------------------------ | -------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name                                                                                                                                        | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_cloudwatch_metric_alarm.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource    |
| [aws_cloudwatch_metric_alarm.system](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)   | resource    |
| [aws_eip.wan_external_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip)                                  | resource    |
| [aws_eip_association.wan_external_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association)          | resource    |
| [aws_instance.ec2_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)                           | resource    |
| [aws_network_interface.mgmt_nic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface)             | resource    |
| [aws_network_interface.private_nic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface)          | resource    |
| [aws_network_interface.public_nic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface)           | resource    |
| [aws_security_group.sdwan_mgmt_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)              | resource    |
| [aws_security_group.sdwan_wan_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)               | resource    |
| [aws_security_group.velocloud_lan_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)           | resource    |
| [aws_ami.velocloud](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)                                     | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                 | data source |

## Inputs

| Name                                                                                                                  | Description                                                                                                                                                                                                                                                                                                                                                                             | Type           | Default                                                                                                                       | Required |
| --------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_ami_id"></a> [ami_id](#input_ami_id)                                                                   | (Optional) The ID of the AMI to use for the instance. If this is not set, the AMI ID will be automated selected based on the `velocloud_version` defined.                                                                                                                                                                                                                               | `string`       | `null`                                                                                                                        |    no    |
| <a name="input_ebs_optimized"></a> [ebs_optimized](#input_ebs_optimized)                                              | (Optional) If true, the launched EC2 instance will be EBS-optimized. Note that if this is not set on an instance type that is optimized by default then this will show as disabled but if the instance type is optimized by default then there is no need to set this and there is no effect to disabling it. See the EBS Optimized section of the AWS User Guide for more information. | `bool`         | `true`                                                                                                                        |    no    |
| <a name="input_hibernation"></a> [hibernation](#input_hibernation)                                                    | (Optional) If true, the launched EC2 instance will support hibernation. (Available since v0.6.0)                                                                                                                                                                                                                                                                                        | `bool`         | `null`                                                                                                                        |    no    |
| <a name="input_http_endpoint"></a> [http_endpoint](#input_http_endpoint)                                              | (Optional) Whether the metadata service is available. Valid values include enabled or disabled. Defaults to enabled.                                                                                                                                                                                                                                                                    | `string`       | `"enabled"`                                                                                                                   |    no    |
| <a name="input_http_tokens"></a> [http_tokens](#input_http_tokens)                                                    | (Optional) Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2 (IMDSv2). Valid values include optional or required. Defaults to optional.                                                                                                                                                                              | `string`       | `"required"`                                                                                                                  |    no    |
| <a name="input_iam_instance_profile"></a> [iam_instance_profile](#input_iam_instance_profile)                         | (Optional) IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile. Ensure your credentials have the correct permission to assign the instance profile according to the EC2 documentation, notably iam:PassRole.                                                                                                                                | `string`       | `null`                                                                                                                        |    no    |
| <a name="input_instance_name_prefix"></a> [instance_name_prefix](#input_instance_name_prefix)                         | (Optional) Used to populate the Name tag.                                                                                                                                                                                                                                                                                                                                               | `string`       | `"aws_prod_sdwan"`                                                                                                            |    no    |
| <a name="input_instance_type"></a> [instance_type](#input_instance_type)                                              | (Optional) Instance type to use for the instance. Updates to this field will trigger a stop/start of the EC2 instance.                                                                                                                                                                                                                                                                  | `string`       | `"c5.xlarge"`                                                                                                                 |    no    |
| <a name="input_key_name"></a> [key_name](#input_key_name)                                                             | (Optional) Key name of the Key Pair to use for the instance; which can be managed using the aws_key_pair resource. Defaults to null.                                                                                                                                                                                                                                                    | `string`       | `null`                                                                                                                        |    no    |
| <a name="input_lan_sg_name"></a> [lan_sg_name](#input_lan_sg_name)                                                    | (Optional, Forces new resource) Name of the security group. If omitted, Terraform will assign a random, unique name.                                                                                                                                                                                                                                                                    | `string`       | `"velocloud_lan_sg"`                                                                                                          |    no    |
| <a name="input_mgmt_ips"></a> [mgmt_ips](#input_mgmt_ips)                                                             | (Optional) List of private IPs to assign to the ENI.                                                                                                                                                                                                                                                                                                                                    | `list(string)` | `null`                                                                                                                        |    no    |
| <a name="input_mgmt_nic_description"></a> [mgmt_nic_description](#input_mgmt_nic_description)                         | (Optional) Description for the network interface.                                                                                                                                                                                                                                                                                                                                       | `string`       | `"SDWAN mgmt nic Ge1 in VeloCloud"`                                                                                           |    no    |
| <a name="input_mgmt_sg_name"></a> [mgmt_sg_name](#input_mgmt_sg_name)                                                 | (Optional, Forces new resource) Name of the security group. If omitted, Terraform will assign a random, unique name.                                                                                                                                                                                                                                                                    | `string`       | `"velocloud_mgmt_sg"`                                                                                                         |    no    |
| <a name="input_monitoring"></a> [monitoring](#input_monitoring)                                                       | (Optional) If true, the launched EC2 instance will have detailed monitoring enabled. (Available since v0.6.0)                                                                                                                                                                                                                                                                           | `bool`         | `true`                                                                                                                        |    no    |
| <a name="input_private_ips"></a> [private_ips](#input_private_ips)                                                    | (Optional) List of private IPs to assign to the ENI.                                                                                                                                                                                                                                                                                                                                    | `list(string)` | `null`                                                                                                                        |    no    |
| <a name="input_private_nic_description"></a> [private_nic_description](#input_private_nic_description)                | (Optional) Description for the network interface.                                                                                                                                                                                                                                                                                                                                       | `string`       | `"SDWAN private nic Ge3 in VeloCloud"`                                                                                        |    no    |
| <a name="input_private_subnet_ids"></a> [private_subnet_ids](#input_private_subnet_ids)                               | (Required) Subnet IDs to create the ENI in.                                                                                                                                                                                                                                                                                                                                             | `list(string)` | n/a                                                                                                                           |   yes    |
| <a name="input_public_ips"></a> [public_ips](#input_public_ips)                                                       | (Optional) Private IP addresses to associate with the instance in a VPC.                                                                                                                                                                                                                                                                                                                | `list(string)` | `null`                                                                                                                        |    no    |
| <a name="input_public_nic_description"></a> [public_nic_description](#input_public_nic_description)                   | (Optional) Description for the network interface.                                                                                                                                                                                                                                                                                                                                       | `string`       | `"SDWAN public nic Ge2 in VeloCloud"`                                                                                         |    no    |
| <a name="input_public_subnet_ids"></a> [public_subnet_ids](#input_public_subnet_ids)                                  | (Required) Subnet IDs to create the ENI in.                                                                                                                                                                                                                                                                                                                                             | `list(string)` | n/a                                                                                                                           |   yes    |
| <a name="input_root_ebs_volume_encrypted"></a> [root_ebs_volume_encrypted](#input_root_ebs_volume_encrypted)          | (Optional) Whether to enable volume encryption on the root ebs volume. Defaults to true. Must be configured to perform drift detection.                                                                                                                                                                                                                                                 | `bool`         | `true`                                                                                                                        |    no    |
| <a name="input_root_volume_size"></a> [root_volume_size](#input_root_volume_size)                                     | (Optional) Size of the root volume in gibibytes (GiB).                                                                                                                                                                                                                                                                                                                                  | `number`       | `8`                                                                                                                           |    no    |
| <a name="input_root_volume_type"></a> [root_volume_type](#input_root_volume_type)                                     | (Optional) Type of volume. Valid values include standard, gp2, gp3, io1, io2, sc1, or st1. Defaults to gp3                                                                                                                                                                                                                                                                              | `string`       | `"gp3"`                                                                                                                       |    no    |
| <a name="input_snmp_mgmt_access_cidr_blocks"></a> [snmp_mgmt_access_cidr_blocks](#input_snmp_mgmt_access_cidr_blocks) | (Optional) List of CIDR blocks allowed to SNMP into the VeloCloud instance.                                                                                                                                                                                                                                                                                                             | `list(string)` | `[]`                                                                                                                          |    no    |
| <a name="input_source_dest_check"></a> [source_dest_check](#input_source_dest_check)                                  | (Optional) Whether to enable source destination checking for the ENI. Default false.                                                                                                                                                                                                                                                                                                    | `bool`         | `false`                                                                                                                       |    no    |
| <a name="input_ssh_mgmt_access_cidr_blocks"></a> [ssh_mgmt_access_cidr_blocks](#input_ssh_mgmt_access_cidr_blocks)    | (Optional) List of CIDR blocks allowed to SSH into the VeloCloud instance.                                                                                                                                                                                                                                                                                                              | `list(string)` | `[]`                                                                                                                          |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                         | (Optional) Map of tags to assign to the device.                                                                                                                                                                                                                                                                                                                                         | `map(any)`     | <pre>{<br/> "created_by": "terraform",<br/> "environment": "prod",<br/> "role": "sdwan",<br/> "terraform": "true"<br/>}</pre> |    no    |
| <a name="input_user_data"></a> [user_data](#input_user_data)                                                          | (Optional) The user data to provide when launching the instance. By default, the velocloud variables will generate a unique user_data cloud-init configuration for you. This allows specifying custom cloud-init scripting.                                                                                                                                                             | `string`       | `null`                                                                                                                        |    no    |
| <a name="input_velocloud_activation_keys"></a> [velocloud_activation_keys](#input_velocloud_activation_keys)          | (Required) The activation key for the VeloCloud instance(s). The quantity of keys also determines the quantity of instances to launch.                                                                                                                                                                                                                                                  | `list(string)` | n/a                                                                                                                           |   yes    |
| <a name="input_velocloud_ignore_cert_errors"></a> [velocloud_ignore_cert_errors](#input_velocloud_ignore_cert_errors) | (Optional) Whether or not to ignore certificate errors when connecting to the VeloCloud orchestrator. Set to true if using private or self-signed certificates on the orchestrator. Defaults to false.                                                                                                                                                                                  | `bool`         | `false`                                                                                                                       |    no    |
| <a name="input_velocloud_lan_cidr_blocks"></a> [velocloud_lan_cidr_blocks](#input_velocloud_lan_cidr_blocks)          | (Optional) List of CIDR blocks allowed to utilize the VeloCloud instance for SDWAN communication.                                                                                                                                                                                                                                                                                       | `list(string)` | `null`                                                                                                                        |    no    |
| <a name="input_velocloud_orchestrator"></a> [velocloud_orchestrator](#input_velocloud_orchestrator)                   | (Required) The IP address or FQDN of the VeloCloud orchestrator. Example: vco.example.com                                                                                                                                                                                                                                                                                               | `string`       | n/a                                                                                                                           |   yes    |
| <a name="input_velocloud_version"></a> [velocloud_version](#input_velocloud_version)                                  | (Optional) The version ID of the VeloCloud VCE AMI to use. Defaults to the latest version. Use semantic versioning to specify a version. Example: 4.5                                                                                                                                                                                                                                   | `string`       | `"4.5"`                                                                                                                       |    no    |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)                                                                   | (Required, Forces new resource) VPC ID. Defaults to the region's default VPC.                                                                                                                                                                                                                                                                                                           | `string`       | n/a                                                                                                                           |   yes    |
| <a name="input_wan_sg_name"></a> [wan_sg_name](#input_wan_sg_name)                                                    | (Optional, Forces new resource) Name of the security group. If omitted, Terraform will assign a random, unique name.                                                                                                                                                                                                                                                                    | `string`       | `"velocloud_wan_sg"`                                                                                                          |    no    |

## Outputs

| Name                                                                                                                                               | Description                                         |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| <a name="output_ec2_instance_id"></a> [ec2_instance_id](#output_ec2_instance_id)                                                                   | The EC2 instance IDs as a list                      |
| <a name="output_mgmt_network_interface_id"></a> [mgmt_network_interface_id](#output_mgmt_network_interface_id)                                     | The mgmt network interface IDs as a list            |
| <a name="output_mgmt_network_interface_private_ips"></a> [mgmt_network_interface_private_ips](#output_mgmt_network_interface_private_ips)          | The mgmt network interface private IPs as a list    |
| <a name="output_private_network_interface_id"></a> [private_network_interface_id](#output_private_network_interface_id)                            | The private network interface IDs as a list         |
| <a name="output_private_network_interface_private_ips"></a> [private_network_interface_private_ips](#output_private_network_interface_private_ips) | The private network interface private IPs as a list |
| <a name="output_public_eip_id"></a> [public_eip_id](#output_public_eip_id)                                                                         | The EIP IDs as a list                               |
| <a name="output_public_eip_ip"></a> [public_eip_ip](#output_public_eip_ip)                                                                         | The EIP public IPs as a list                        |
| <a name="output_public_network_interface_id"></a> [public_network_interface_id](#output_public_network_interface_id)                               | The public network interface IDs as a list          |
| <a name="output_public_network_interface_private_ips"></a> [public_network_interface_private_ips](#output_public_network_interface_private_ips)    | The public network interface private IPs as a list  |

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
