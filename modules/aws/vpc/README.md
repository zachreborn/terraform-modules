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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">VPC Module</h3>
  <p align="center">
    Module which builds out a VPC with multiple subnets for network segmentation, associated routes, gateways, and flow logs for all instances within the VPC. See the terraform-docs output below for all built resources. 
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
This example sends uses an internet gateway for the public subnets and NAT gateways for the internal subnets. It utilizes the 10.11.0.0/16 subnet space with /24 subnets for each segmented subnet per availability zone.
```
module "vpc" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vpc"

    name                    = "client_prod_vpc"
    vpc_cidr                = "10.11.0.0/16"
    azs                     = ["us-east-1a", "us-east-1b", "us-east-1c"]
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "core_infrastructure"
    }
}
```

### Firewall Example
This example sends all egress traffic out a EC2 instance acting as a firewall. It also changes the default VPC CIDR block and subnets.
```
module "vpc" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vpc"

    name                    = "client_prod_vpc"
    vpc_cidr                = "10.11.0.0/16"
    azs                     = ["us-east-1a", "us-east-1b", "us-east-1c"]
    enable_firewall         = true
    fw_network_interface_id = module.aws_ec2_fortigate_fw.private_network_interface_id
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "core_infrastructure"
    }
}
```

### Setting Subnet Example
This example sends uses an internet gateway for the public subnets and NAT gateways for the internal subnets. It utilizes a unique 10.100.0.0/16 subnet space with /24 subnets for each segmented subnet per availability zone.
```
module "vpc" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vpc"

    name                    = "client_prod_vpc"
    vpc_cidr                = "10.100.0.0/16"
    azs                     = ["us-east-1a", "us-east-1b", "us-east-1c"]
    db_subnets_list         = ["10.100.11.0/24", "10.100.12.0/24", "10.100.13.0/24"]
    dmz_subnets_list        = ["10.100.101.0/24", "10.100.102.0/24", "10.100.103.0/24"]
    mgmt_subnets_list       = ["10.100.61.0/24", "10.100.62.0/24", "10.100.63.0/24"]
    private_subnets_list    = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
    public_subnets_list     = ["10.100.201.0/24", "10.100.202.0/24", "10.100.203.0/24"]
    workspaces_subnets_list = ["10.100.21.0/24", "10.100.22.0/24", "10.100.23.0/24"]
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "core_infrastructure"
    }
}
```

### Disabling Unneeded Subnets
This example disabled unused subnets and associated resources. In the example we leave only the public and private subnets enabled.
```hcl
module "vpc" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vpc"

    name                    = "client_prod_vpc"
    vpc_cidr                = "10.11.0.0/16"
    azs                     = ["us-east-1a", "us-east-1b", "us-east-1c"]
    db_subnets_list         = []
    dmz_subnets_list        = []
    mgmt_subnets_list       = []
    private_subnets_list    = ["10.11.0.0/24", "10.11.1.0/24", "10.11.2.0/24"]
    public_subnets_list     = ["10.11.200.0/24", "10.11.201.0/24", "10.11.202.0/24"]
    workspaces_subnets_list = []
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "core_infrastructure"
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
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc_flow_logs"></a> [vpc\_flow\_logs](#module\_vpc\_flow\_logs) | ../flow_logs | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eip.nateip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.db_default_route_fw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.db_default_route_natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.dmz_default_route_fw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.dmz_default_route_natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.mgmt_default_route_fw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.mgmt_default_route_natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_default_route_fw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_default_route_natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_default_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.workspaces_default_route_fw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.workspaces_default_route_natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.db_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.dmz_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.mgmt_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.workspaces_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.dmz](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.workspaces](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.db_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.dmz_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.mgmt_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.workspaces_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.ec2messages](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ssm-contacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ssm-incidents](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ssmmessages](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_route_table_association.private_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpc_endpoint_route_table_association.public_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azs"></a> [azs](#input\_azs) | A list of Availability zones in the region | `list` | <pre>[<br/>  "us-east-2a",<br/>  "us-east-2b",<br/>  "us-east-2c"<br/>]</pre> | no |
| <a name="input_cloudwatch_name_prefix"></a> [cloudwatch\_name\_prefix](#input\_cloudwatch\_name\_prefix) | (Optional, Forces new resource) Creates a unique name beginning with the specified prefix. | `string` | `"flow_logs_"` | no |
| <a name="input_cloudwatch_retention_in_days"></a> [cloudwatch\_retention\_in\_days](#input\_cloudwatch\_retention\_in\_days) | (Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire. | `number` | `90` | no |
| <a name="input_db_propagating_vgws"></a> [db\_propagating\_vgws](#input\_db\_propagating\_vgws) | A list of VGWs the db route table should propagate. | `list` | `[]` | no |
| <a name="input_db_subnets_list"></a> [db\_subnets\_list](#input\_db\_subnets\_list) | A list of database subnets inside the VPC. | `list` | <pre>[<br/>  "10.11.11.0/24",<br/>  "10.11.12.0/24",<br/>  "10.11.13.0/24"<br/>]</pre> | no |
| <a name="input_dmz_propagating_vgws"></a> [dmz\_propagating\_vgws](#input\_dmz\_propagating\_vgws) | A list of VGWs the DMZ route table should propagate. | `list` | `[]` | no |
| <a name="input_dmz_subnets_list"></a> [dmz\_subnets\_list](#input\_dmz\_subnets\_list) | A list of DMZ subnets inside the VPC. | `list` | <pre>[<br/>  "10.11.101.0/24",<br/>  "10.11.102.0/24",<br/>  "10.11.103.0/24"<br/>]</pre> | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | (Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults false. | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | (Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults true. | `bool` | `true` | no |
| <a name="input_enable_firewall"></a> [enable\_firewall](#input\_enable\_firewall) | (Optional) A boolean flag to enable/disable the use of a firewall instance within the VPC. Defaults False. | `bool` | `false` | no |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | (Optional) A boolean flag to enable/disable the use of flow logs with the resources. Defaults True. | `bool` | `true` | no |
| <a name="input_enable_internet_gateway"></a> [enable\_internet\_gateway](#input\_enable\_internet\_gateway) | (Optional) A boolean flag to enable/disable the use of Internet gateways. Defaults True. | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | (Optional) A boolean flag to enable/disable the use of NAT gateways in the private subnets. Defaults True. | `bool` | `true` | no |
| <a name="input_enable_s3_endpoint"></a> [enable\_s3\_endpoint](#input\_enable\_s3\_endpoint) | (Optional) A boolean flag to enable/disable the use of a S3 endpoint with the VPC. Defaults False | `bool` | `false` | no |
| <a name="input_enable_ssm_vpc_endpoints"></a> [enable\_ssm\_vpc\_endpoints](#input\_enable\_ssm\_vpc\_endpoints) | (Optional) A boolean flag to enable/disable SSM (Systems Manager) VPC endpoints. Defaults true. | `bool` | `false` | no |
| <a name="input_flow_deliver_cross_account_role"></a> [flow\_deliver\_cross\_account\_role](#input\_flow\_deliver\_cross\_account\_role) | (Optional) The ARN of the IAM role that posts logs to CloudWatch Logs in a different account. | `string` | `null` | no |
| <a name="input_flow_log_destination_type"></a> [flow\_log\_destination\_type](#input\_flow\_log\_destination\_type) | (Optional) The type of the logging destination. Valid values: cloud-watch-logs, s3. Default: cloud-watch-logs. | `string` | `"cloud-watch-logs"` | no |
| <a name="input_flow_log_format"></a> [flow\_log\_format](#input\_flow\_log\_format) | (Optional) The fields to include in the flow log record, in the order in which they should appear. For more information, see Flow Log Records. Default: fields are in the order that they are described in the Flow Log Records section. | `string` | `null` | no |
| <a name="input_flow_max_aggregation_interval"></a> [flow\_max\_aggregation\_interval](#input\_flow\_max\_aggregation\_interval) | (Optional) The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: 60 seconds (1 minute) or 600 seconds (10 minutes). Default: 600. | `number` | `60` | no |
| <a name="input_flow_traffic_type"></a> [flow\_traffic\_type](#input\_flow\_traffic\_type) | (Optional) The type of traffic to capture. Valid values: ACCEPT,REJECT, ALL. | `string` | `"ALL"` | no |
| <a name="input_fw_dmz_network_interface_id"></a> [fw\_dmz\_network\_interface\_id](#input\_fw\_dmz\_network\_interface\_id) | Firewall DMZ eni id | `list(any)` | `[]` | no |
| <a name="input_fw_network_interface_id"></a> [fw\_network\_interface\_id](#input\_fw\_network\_interface\_id) | Firewall network interface id | `list` | `[]` | no |
| <a name="input_iam_policy_name_prefix"></a> [iam\_policy\_name\_prefix](#input\_iam\_policy\_name\_prefix) | (Optional, Forces new resource) Creates a unique name beginning with the specified prefix. Conflicts with name. | `string` | `"flow_log_policy_"` | no |
| <a name="input_iam_policy_path"></a> [iam\_policy\_path](#input\_iam\_policy\_path) | (Optional, default '/') Path in which to create the policy. See IAM Identifiers for more information. | `string` | `"/"` | no |
| <a name="input_iam_role_description"></a> [iam\_role\_description](#input\_iam\_role\_description) | (Optional) The description of the role. | `string` | `"Role utilized for VPC flow logs. This role allows creation of log streams and adding logs to the log streams in cloudwatch"` | no |
| <a name="input_iam_role_name_prefix"></a> [iam\_role\_name\_prefix](#input\_iam\_role\_name\_prefix) | (Required, Forces new resource) Creates a unique friendly name beginning with the specified prefix. Conflicts with name. | `string` | `"flow_logs_role_"` | no |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | A tenancy option for instances launched into the VPC | `string` | `"default"` | no |
| <a name="input_key_name_prefix"></a> [key\_name\_prefix](#input\_key\_name\_prefix) | (Optional) Creates an unique alias beginning with the specified prefix. The name must start with the word alias followed by a forward slash (alias/). | `string` | `"alias/flow_logs_key_"` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | (Optional) Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is false. | `bool` | `true` | no |
| <a name="input_mgmt_propagating_vgws"></a> [mgmt\_propagating\_vgws](#input\_mgmt\_propagating\_vgws) | A list of VGWs the mgmt route table should propagate. | `list` | `[]` | no |
| <a name="input_mgmt_subnets_list"></a> [mgmt\_subnets\_list](#input\_mgmt\_subnets\_list) | A list of mgmt subnets inside the VPC. | `list` | <pre>[<br/>  "10.11.61.0/24",<br/>  "10.11.62.0/24",<br/>  "10.11.63.0/24"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Name to be tagged on all of the resources as an identifier | `string` | n/a | yes |
| <a name="input_private_propagating_vgws"></a> [private\_propagating\_vgws](#input\_private\_propagating\_vgws) | A list of VGWs the private route table should propagate. | `list` | `[]` | no |
| <a name="input_private_subnets_list"></a> [private\_subnets\_list](#input\_private\_subnets\_list) | A list of private subnets inside the VPC. | `list` | <pre>[<br/>  "10.11.1.0/24",<br/>  "10.11.2.0/24",<br/>  "10.11.3.0/24"<br/>]</pre> | no |
| <a name="input_public_propagating_vgws"></a> [public\_propagating\_vgws](#input\_public\_propagating\_vgws) | A list of VGWs the public route table should propagate. | `list` | `[]` | no |
| <a name="input_public_subnets_list"></a> [public\_subnets\_list](#input\_public\_subnets\_list) | A list of public subnets inside the VPC. | `list` | <pre>[<br/>  "10.11.201.0/24",<br/>  "10.11.202.0/24",<br/>  "10.11.203.0/24"<br/>]</pre> | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | (Optional) A boolean flag to enable/disable use of only a single shared NAT Gateway across all of your private networks. Defaults False. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the object. | `map` | <pre>{<br/>  "created_by": "<YOUR_NAME>",<br/>  "environment": "prod",<br/>  "priority": "high",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC | `string` | `"10.11.0.0/16"` | no |
| <a name="input_workspaces_propagating_vgws"></a> [workspaces\_propagating\_vgws](#input\_workspaces\_propagating\_vgws) | A list of VGWs the workspaces route table should propagate. | `list` | `[]` | no |
| <a name="input_workspaces_subnets_list"></a> [workspaces\_subnets\_list](#input\_workspaces\_subnets\_list) | A list of workspaces subnets inside the VPC. | `list` | <pre>[<br/>  "10.11.21.0/24",<br/>  "10.11.22.0/24",<br/>  "10.11.23.0/24"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | n/a |
| <a name="output_db_route_table_ids"></a> [db\_route\_table\_ids](#output\_db\_route\_table\_ids) | n/a |
| <a name="output_db_subnet_ids"></a> [db\_subnet\_ids](#output\_db\_subnet\_ids) | n/a |
| <a name="output_default_security_group_id"></a> [default\_security\_group\_id](#output\_default\_security\_group\_id) | n/a |
| <a name="output_dmz_route_table_ids"></a> [dmz\_route\_table\_ids](#output\_dmz\_route\_table\_ids) | n/a |
| <a name="output_dmz_subnet_ids"></a> [dmz\_subnet\_ids](#output\_dmz\_subnet\_ids) | n/a |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | n/a |
| <a name="output_mgmt_route_table_ids"></a> [mgmt\_route\_table\_ids](#output\_mgmt\_route\_table\_ids) | n/a |
| <a name="output_mgmt_subnet_ids"></a> [mgmt\_subnet\_ids](#output\_mgmt\_subnet\_ids) | n/a |
| <a name="output_name"></a> [name](#output\_name) | The name of the VPC |
| <a name="output_nat_eips"></a> [nat\_eips](#output\_nat\_eips) | n/a |
| <a name="output_nat_eips_public_ips"></a> [nat\_eips\_public\_ips](#output\_nat\_eips\_public\_ips) | n/a |
| <a name="output_natgw_ids"></a> [natgw\_ids](#output\_natgw\_ids) | n/a |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | n/a |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | n/a |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | n/a |
| <a name="output_public_route_table_ids"></a> [public\_route\_table\_ids](#output\_public\_route\_table\_ids) | n/a |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | n/a |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | n/a |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
| <a name="output_workspaces_route_table_ids"></a> [workspaces\_route\_table\_ids](#output\_workspaces\_route\_table\_ids) | n/a |
| <a name="output_workspaces_subnet_ids"></a> [workspaces\_subnet\_ids](#output\_workspaces\_subnet\_ids) | n/a |
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

* [Zachary Hill](https://zacharyhill.co)
* [Jake Jones](https://github.com/jakeasarus)

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