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
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Prerequisites

This module has no hard prerequisite resources for its default (IPv4-only, no firewall) configuration -- it creates its own VPC, subnets, gateways, and (via the nested [`flow_logs`](../flow_logs) module) the IAM role/policy and KMS key backing its flow logs. Depending on which optional features you enable, you'll need to provision the following yourself first:

- **`enable_firewall = true`**: an existing network interface (e.g. from a firewall EC2 instance or appliance module) to pass in via `fw_network_interface_id`/`fw_dmz_network_interface_id`.
- **`ipv4_ipam_pool_id`** / **`ipv6_ipam_pool_id`**: an existing IPv4/IPv6 IPAM pool (see `aws_vpc_ipam_pool`) in the target region.
- **`internet_monitor_s3_bucket_name`**: an existing S3 bucket for CloudWatch Internet Monitor measurement delivery -- this module does not create the bucket.
- **`vpc_endpoints`** entries with a **`policy`**: the IAM policy JSON is the caller's responsibility; this module only attaches whatever you provide.
- **`additional_routes`** entries targeting a VPC peering connection, Transit Gateway, prefix list, or carrier gateway: those resources (e.g. `aws_vpc_peering_connection`, the `transit_gateway` family of modules in this repository, `aws_ec2_managed_prefix_list`) must already exist.

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

### Disabling the Internet Gateway

This example disables the internet gateway, making this VPC a private VPC. This is useful for VPCs which do not need to communicate with the internet, or do so via an egress inspection VPC, SDWAN, or other solution.

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
    public_subnets_list     = []
    workspaces_subnets_list = []
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "core_infrastructure"
    }
}
```

Alternatively, you can disable the internet gateway by setting the `enable_internet_gateway` variable to `false`. This is useful if you still want to have public subnets.

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
    enable_internet_gateway = false
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "core_infrastructure"
    }
}
```

### CloudWatch Internet Monitor Example

This example enables an Amazon CloudWatch Internet Monitor for the VPC to surface internet performance (RTT) and availability health events for the city-networks (client location + ASN) that reach your resources. The feature is fully opt-in via `enable_internet_monitor` (default `false`) and monitors the module's own VPC ARN. Optionally, internet measurements beyond the top-500 city-networks can be delivered to an existing S3 bucket supplied by the caller (this module does not create the bucket).

```hcl
module "vpc" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vpc"

    name     = "client_prod_vpc"
    vpc_cidr = "10.11.0.0/16"
    azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

    # CloudWatch Internet Monitor
    enable_internet_monitor                        = true
    internet_monitor_monitor_name                  = "client_prod_vpc_monitor"
    internet_monitor_traffic_percentage_to_monitor = 100
    internet_monitor_max_city_networks_to_monitor  = 100

    # Optional: deliver internet measurements to an existing S3 bucket
    internet_monitor_s3_bucket_name   = "my-existing-internet-monitor-bucket"
    internet_monitor_s3_bucket_prefix = "internet-monitor"
    internet_monitor_s3_bucket_status = "ENABLED"

    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "core_infrastructure"
    }
}
```

### IPv6 (Dual-Stack) Example

This example opts into dual-stack IPv6 support. An Amazon-provided /56 IPv6 CIDR is auto-assigned to the VPC, every subnet this module manages gets a /64 carved out of it, an egress-only internet gateway is created for outbound-only IPv6 from the non-public tiers (NAT gateways don't support IPv6), and IPv6 default routes are added alongside the existing IPv4 defaults.

```hcl
module "vpc" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vpc"

    name        = "client_prod_vpc"
    vpc_cidr    = "*********/16"
    azs         = ["us-east-1a", "us-east-1b", "us-east-1c"]
    enable_ipv6 = true
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "core_infrastructure"
    }
}
```

To source the IPv6 CIDR from an existing IPAM pool instead of an Amazon-provided block, also set `ipv6_ipam_pool_id` (and, optionally, `ipv6_netmask_length`).

### Custom VPC Endpoints Example

The `enable_ssm_vpc_endpoints`/`enable_ecr_vpc_endpoints`/`enable_s3_endpoint` booleans cover a fixed, curated set of endpoints. To attach any other interface, gateway, gateway load balancer, resource, or service-network endpoint (e.g. Secrets Manager, STS, SNS/SQS) without editing this module, use `vpc_endpoints`. Gateway-type endpoints default to every public and private route table this module manages unless you supply `route_table_ids` explicitly.

```hcl
module "vpc" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vpc"

    name     = "client_prod_vpc"
    vpc_cidr = "*********/16"
    azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

    vpc_endpoints = {
        secretsmanager = {
            service_name        = "com.amazonaws.us-east-1.secretsmanager"
            vpc_endpoint_type   = "Interface"
            private_dns_enabled = true
            security_group_ids  = [module.secretsmanager_sg.id]
        }
        dynamodb = {
            service_name      = "com.amazonaws.us-east-1.dynamodb"
            vpc_endpoint_type = "Gateway"
        }
    }

    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "core_infrastructure"
    }
}
```

### Additional Routes Example

Use `additional_routes` to attach routes this module doesn't build by default (VPC peering, Transit Gateway, prefix lists, carrier gateway) to any of its managed route tables, without editing the module. Each route is replicated across every route table in every tier listed in `route_table_types`.

```hcl
module "vpc" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/vpc"

    name     = "client_prod_vpc"
    vpc_cidr = "*********/16"
    azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

    additional_routes = {
        shared_services_peering = {
            route_table_types         = ["private", "dmz"]
            destination_cidr_block    = "**********/16"
            vpc_peering_connection_id = aws_vpc_peering_connection.shared_services.id
        }
    }

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
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.54.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_ssm_vpc_endpoint_sg"></a> [ssm\_vpc\_endpoint\_sg](#module\_ssm\_vpc\_endpoint\_sg) | ../security_group | n/a |
| <a name="module_vpc_flow_logs"></a> [vpc\_flow\_logs](#module\_vpc\_flow\_logs) | ../flow_logs | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_egress_only_internet_gateway.eigw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/egress_only_internet_gateway) | resource |
| [aws_eip.nateip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_internetmonitor_monitor.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internetmonitor_monitor) | resource |
| [aws_nat_gateway.natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.db_default_route_fw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.db_default_route_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.db_default_route_natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.dmz_default_route_fw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.dmz_default_route_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.dmz_default_route_natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.mgmt_default_route_fw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.mgmt_default_route_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.mgmt_default_route_natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_default_route_fw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_default_route_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_default_route_natgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_default_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_default_route_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.workspaces_default_route_fw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.workspaces_default_route_ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
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
| [aws_subnet.db_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.dmz_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.mgmt_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.workspaces_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ec2messages](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ecr_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ecr_dkr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ssm-contacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ssm-incidents](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ssmmessages](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_route_table_association.private_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpc_endpoint_route_table_association.public_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpc_security_group_egress_rule.vpc_endpoint_all_traffic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.vpc_endpoint_https_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.vpc_endpoint_https_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_routes"></a> [additional\_routes](#input\_additional\_routes) | (Optional) Map of additional routes to add to this module's managed route tables, for destinations not covered by the built-in IGW/NAT/firewall/IPv6 defaults (e.g. VPC peering, Transit Gateway, prefix lists, carrier gateway, Outposts local gateway, ODB network, VPC Lattice). Each key is an arbitrary, unique route name. route\_table\_types selects which of this module's route table tiers (private, public, db, dmz, mgmt, workspaces) the route is added to; the same route is replicated across every route table this module manages in each selected tier. route\_table\_types must be a non-empty list of unique, supported tier names. | <pre>map(object({<br/>    route_table_types           = list(string)<br/>    destination_cidr_block      = optional(string)<br/>    destination_ipv6_cidr_block = optional(string)<br/>    destination_prefix_list_id  = optional(string)<br/>    vpc_peering_connection_id   = optional(string)<br/>    transit_gateway_id          = optional(string)<br/>    carrier_gateway_id          = optional(string)<br/>    core_network_arn            = optional(string)<br/>    vpc_endpoint_id             = optional(string)<br/>    network_interface_id        = optional(string)<br/>    egress_only_gateway_id      = optional(string)<br/>    nat_gateway_id              = optional(string)<br/>    gateway_id                  = optional(string)<br/>    local_gateway_id            = optional(string)<br/>    odb_network_arn             = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | A list of Availability zones in the region | `list(string)` | <pre>[<br/>  "us-east-2a",<br/>  "us-east-2b",<br/>  "us-east-2c"<br/>]</pre> | no |
| <a name="input_cloudwatch_deletion_protection_enabled"></a> [cloudwatch\_deletion\_protection\_enabled](#input\_cloudwatch\_deletion\_protection\_enabled) | (Optional) If true, prevents the flow logs' CloudWatch log group from being deleted. Defaults false. Requires AWS provider >= 6.25.0. Passed through to modules/aws/flow\_logs. | `bool` | `false` | no |
| <a name="input_cloudwatch_name_prefix"></a> [cloudwatch\_name\_prefix](#input\_cloudwatch\_name\_prefix) | (Optional, Forces new resource) Creates a unique name beginning with the specified prefix. | `string` | `"flow_logs_"` | no |
| <a name="input_cloudwatch_retention_in_days"></a> [cloudwatch\_retention\_in\_days](#input\_cloudwatch\_retention\_in\_days) | (Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire. | `number` | `90` | no |
| <a name="input_db_propagating_vgws"></a> [db\_propagating\_vgws](#input\_db\_propagating\_vgws) | A list of VGWs the db route table should propagate. | `list(string)` | `null` | no |
| <a name="input_db_subnets_list"></a> [db\_subnets\_list](#input\_db\_subnets\_list) | A list of database subnets inside the VPC. | `list(string)` | <pre>[<br/>  "10.11.11.0/24",<br/>  "10.11.12.0/24",<br/>  "10.11.13.0/24"<br/>]</pre> | no |
| <a name="input_dmz_propagating_vgws"></a> [dmz\_propagating\_vgws](#input\_dmz\_propagating\_vgws) | A list of VGWs the DMZ route table should propagate. | `list(string)` | `null` | no |
| <a name="input_dmz_subnets_list"></a> [dmz\_subnets\_list](#input\_dmz\_subnets\_list) | A list of DMZ subnets inside the VPC. | `list(string)` | <pre>[<br/>  "10.11.101.0/24",<br/>  "10.11.102.0/24",<br/>  "10.11.103.0/24"<br/>]</pre> | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | (Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults true. | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | (Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults true. | `bool` | `true` | no |
| <a name="input_enable_ecr_vpc_endpoints"></a> [enable\_ecr\_vpc\_endpoints](#input\_enable\_ecr\_vpc\_endpoints) | (Optional) A boolean flag to enable/disable ECR (Elastic Container Registry) VPC endpoints. This enables ECR API, ECR DKR, Cloudwatch Logs, and S3 endpoints. | `bool` | `false` | no |
| <a name="input_enable_firewall"></a> [enable\_firewall](#input\_enable\_firewall) | (Optional) A boolean flag to enable/disable the use of a firewall instance within the VPC. Defaults False. | `bool` | `false` | no |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | (Optional) A boolean flag to enable/disable the use of flow logs with the resources. Defaults True. | `bool` | `true` | no |
| <a name="input_enable_internet_gateway"></a> [enable\_internet\_gateway](#input\_enable\_internet\_gateway) | (Optional) A boolean flag to enable/disable the use of Internet gateways. Defaults True. | `bool` | `true` | no |
| <a name="input_enable_internet_monitor"></a> [enable\_internet\_monitor](#input\_enable\_internet\_monitor) | (Optional) A boolean flag to enable/disable the creation of a CloudWatch Internet Monitor for this VPC. Defaults false. | `bool` | `false` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | (Optional) A boolean flag to enable/disable dual-stack IPv6 support. When true and ipv6\_ipam\_pool\_id is not set, an Amazon-provided /56 IPv6 CIDR is auto-assigned to the VPC (assign\_generated\_ipv6\_cidr\_block). Every subnet this module manages then receives a /64 carved out of that block, an egress-only internet gateway is created, and IPv6 default routes (::/0) are added alongside the existing IPv4 defaults. Defaults false (IPv4-only). | `bool` | `false` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | (Optional) A boolean flag to enable/disable the use of NAT gateways in the private subnets. Defaults True. | `bool` | `true` | no |
| <a name="input_enable_network_address_usage_metrics"></a> [enable\_network\_address\_usage\_metrics](#input\_enable\_network\_address\_usage\_metrics) | (Optional) Indicates whether Network Address Usage metrics are enabled for the VPC. Defaults false. | `bool` | `false` | no |
| <a name="input_enable_s3_endpoint"></a> [enable\_s3\_endpoint](#input\_enable\_s3\_endpoint) | (Optional) A boolean flag to enable/disable the use of a S3 endpoint with the VPC. | `bool` | `false` | no |
| <a name="input_enable_ssm_vpc_endpoints"></a> [enable\_ssm\_vpc\_endpoints](#input\_enable\_ssm\_vpc\_endpoints) | (Optional) A boolean flag to enable/disable SSM (Systems Manager) VPC endpoints. | `bool` | `false` | no |
| <a name="input_flow_deliver_cross_account_role"></a> [flow\_deliver\_cross\_account\_role](#input\_flow\_deliver\_cross\_account\_role) | (Optional) The ARN of the IAM role that posts logs to CloudWatch Logs in a different account. | `string` | `null` | no |
| <a name="input_flow_eni_ids"></a> [flow\_eni\_ids](#input\_flow\_eni\_ids) | (Optional) List of Elastic Network Interface IDs to attach the flow logs to, instead of this module's own VPC. The underlying flow\_logs module only supports one flow-log target at a time, so setting this makes the flow log target these ENIs and suppresses the default VPC target. Passed through to modules/aws/flow\_logs. | `list(string)` | `null` | no |
| <a name="input_flow_log_destination_type"></a> [flow\_log\_destination\_type](#input\_flow\_log\_destination\_type) | (Optional) The type of the logging destination. Valid values: cloud-watch-logs, s3. Default: cloud-watch-logs. | `string` | `"cloud-watch-logs"` | no |
| <a name="input_flow_log_format"></a> [flow\_log\_format](#input\_flow\_log\_format) | (Optional) The fields to include in the flow log record, in the order in which they should appear. For more information, see Flow Log Records. Default: fields are in the order that they are described in the Flow Log Records section. | `string` | `null` | no |
| <a name="input_flow_max_aggregation_interval"></a> [flow\_max\_aggregation\_interval](#input\_flow\_max\_aggregation\_interval) | (Optional) The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: 60 seconds (1 minute) or 600 seconds (10 minutes). Default: 600. | `number` | `60` | no |
| <a name="input_flow_subnet_ids"></a> [flow\_subnet\_ids](#input\_flow\_subnet\_ids) | (Optional) List of Subnet IDs to attach the flow logs to, instead of this module's own VPC. The underlying flow\_logs module only supports one flow-log target at a time, so setting this makes the flow log target these subnets and suppresses the default VPC target. Passed through to modules/aws/flow\_logs. | `list(string)` | `null` | no |
| <a name="input_flow_traffic_type"></a> [flow\_traffic\_type](#input\_flow\_traffic\_type) | (Optional) The type of traffic to capture. Valid values: ACCEPT,REJECT, ALL. | `string` | `"ALL"` | no |
| <a name="input_flow_transit_gateway_attachment_ids"></a> [flow\_transit\_gateway\_attachment\_ids](#input\_flow\_transit\_gateway\_attachment\_ids) | (Optional) List of IDs of the transit gateway attachments to attach the flow logs to, instead of this module's own VPC. The underlying flow\_logs module only supports one flow-log target at a time, so setting this makes the flow log target these attachments and suppresses the default VPC target. Passed through to modules/aws/flow\_logs. | `list(string)` | `null` | no |
| <a name="input_flow_transit_gateway_ids"></a> [flow\_transit\_gateway\_ids](#input\_flow\_transit\_gateway\_ids) | (Optional) List of IDs of the transit gateways to attach the flow logs to, instead of this module's own VPC. The underlying flow\_logs module only supports one flow-log target at a time, so setting this makes the flow log target these transit gateways and suppresses the default VPC target. Passed through to modules/aws/flow\_logs. | `list(string)` | `null` | no |
| <a name="input_fw_dmz_network_interface_id"></a> [fw\_dmz\_network\_interface\_id](#input\_fw\_dmz\_network\_interface\_id) | Firewall DMZ eni id | `list(string)` | `null` | no |
| <a name="input_fw_network_interface_id"></a> [fw\_network\_interface\_id](#input\_fw\_network\_interface\_id) | Firewall network interface id | `list(string)` | `null` | no |
| <a name="input_iam_policy_description"></a> [iam\_policy\_description](#input\_iam\_policy\_description) | (Optional, Forces new resource) Description of the flow logs IAM policy. Passed through to modules/aws/flow\_logs. | `string` | `"Used with flow logs to send packet capture logs to a CloudWatch log group."` | no |
| <a name="input_iam_policy_name_prefix"></a> [iam\_policy\_name\_prefix](#input\_iam\_policy\_name\_prefix) | (Optional, Forces new resource) Creates a unique name beginning with the specified prefix. Conflicts with name. | `string` | `"flow_log_policy_"` | no |
| <a name="input_iam_policy_path"></a> [iam\_policy\_path](#input\_iam\_policy\_path) | (Optional, default '/') Path in which to create the policy. See IAM Identifiers for more information. | `string` | `"/"` | no |
| <a name="input_iam_role_assume_role_policy"></a> [iam\_role\_assume\_role\_policy](#input\_iam\_role\_assume\_role\_policy) | (Optional) The policy that grants the flow logs service permission to assume the IAM role. Passed through to modules/aws/flow\_logs. | `string` | `"{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Principal\": {\n        \"Service\": \"vpc-flow-logs.amazonaws.com\"\n      },\n      \"Action\": \"sts:AssumeRole\"\n    }\n  ]\n}\n"` | no |
| <a name="input_iam_role_description"></a> [iam\_role\_description](#input\_iam\_role\_description) | (Optional) The description of the role. | `string` | `"Role utilized for VPC flow logs. This role allows creation of log streams and adding logs to the log streams in cloudwatch"` | no |
| <a name="input_iam_role_force_detach_policies"></a> [iam\_role\_force\_detach\_policies](#input\_iam\_role\_force\_detach\_policies) | (Optional) Specifies to force detaching any policies the flow logs role has before destroying it. Defaults false. Passed through to modules/aws/flow\_logs. | `bool` | `false` | no |
| <a name="input_iam_role_max_session_duration"></a> [iam\_role\_max\_session\_duration](#input\_iam\_role\_max\_session\_duration) | (Optional) The maximum session duration (in seconds, 3600-43200) for the flow logs IAM role. Passed through to modules/aws/flow\_logs. | `number` | `3600` | no |
| <a name="input_iam_role_name_prefix"></a> [iam\_role\_name\_prefix](#input\_iam\_role\_name\_prefix) | (Required, Forces new resource) Creates a unique friendly name beginning with the specified prefix. Conflicts with name. | `string` | `"flow_logs_role_"` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | (Optional) The ARN of the policy used to set the permissions boundary for the flow logs IAM role. Passed through to modules/aws/flow\_logs. | `string` | `null` | no |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | A tenancy option for instances launched into the VPC | `string` | `"default"` | no |
| <a name="input_internet_monitor_availability_score_threshold"></a> [internet\_monitor\_availability\_score\_threshold](#input\_internet\_monitor\_availability\_score\_threshold) | (Optional) The health-event trigger threshold percentage for the availability score. Valid values are 1-100. Defaults 95. | `number` | `95` | no |
| <a name="input_internet_monitor_max_city_networks_to_monitor"></a> [internet\_monitor\_max\_city\_networks\_to\_monitor](#input\_internet\_monitor\_max\_city\_networks\_to\_monitor) | (Optional) The maximum number of city-networks (location + ASN pairs) to monitor. This is a hard billing cap. Valid values are 1-500000. Defaults 100. | `number` | `100` | no |
| <a name="input_internet_monitor_monitor_name"></a> [internet\_monitor\_monitor\_name](#input\_internet\_monitor\_monitor\_name) | (Optional) The name of the Internet Monitor. Required when enable\_internet\_monitor is true. Maps to the monitor\_name argument. | `string` | `null` | no |
| <a name="input_internet_monitor_performance_score_threshold"></a> [internet\_monitor\_performance\_score\_threshold](#input\_internet\_monitor\_performance\_score\_threshold) | (Optional) The health-event trigger threshold percentage for the performance score. Valid values are 1-100. Defaults 95. | `number` | `95` | no |
| <a name="input_internet_monitor_s3_bucket_name"></a> [internet\_monitor\_s3\_bucket\_name](#input\_internet\_monitor\_s3\_bucket\_name) | (Optional) The name of an existing S3 bucket for publishing internet measurements beyond the top-500 city-networks. When null, S3 measurement delivery is not configured. The bucket must be supplied by the caller. | `string` | `null` | no |
| <a name="input_internet_monitor_s3_bucket_prefix"></a> [internet\_monitor\_s3\_bucket\_prefix](#input\_internet\_monitor\_s3\_bucket\_prefix) | (Optional) The S3 key prefix for internet-measurements delivery. | `string` | `null` | no |
| <a name="input_internet_monitor_s3_bucket_status"></a> [internet\_monitor\_s3\_bucket\_status](#input\_internet\_monitor\_s3\_bucket\_status) | (Optional) Enables (ENABLED) or disables (DISABLED) S3 internet-measurement delivery. Valid values: ENABLED, DISABLED. Defaults DISABLED. | `string` | `"DISABLED"` | no |
| <a name="input_internet_monitor_status"></a> [internet\_monitor\_status](#input\_internet\_monitor\_status) | (Optional) The status for the monitor. Valid values: ACTIVE, INACTIVE. Defaults ACTIVE. | `string` | `"ACTIVE"` | no |
| <a name="input_internet_monitor_traffic_percentage_to_monitor"></a> [internet\_monitor\_traffic\_percentage\_to\_monitor](#input\_internet\_monitor\_traffic\_percentage\_to\_monitor) | (Optional) The percentage of internet-facing traffic to monitor with this monitor. Valid values are 1-100. Controls cost. Defaults 100. | `number` | `100` | no |
| <a name="input_ipv4_ipam_pool_id"></a> [ipv4\_ipam\_pool\_id](#input\_ipv4\_ipam\_pool\_id) | (Optional) The ID of an IPv4 IPAM pool to source the VPC CIDR from. When set, vpc\_cidr is ignored and the CIDR is allocated from the pool using ipv4\_netmask\_length. | `string` | `null` | no |
| <a name="input_ipv4_netmask_length"></a> [ipv4\_netmask\_length](#input\_ipv4\_netmask\_length) | (Optional) The netmask length of the IPv4 CIDR to allocate from the IPAM pool referenced by ipv4\_ipam\_pool\_id. Required when ipv4\_ipam\_pool\_id is set. | `number` | `null` | no |
| <a name="input_ipv6_cidr_block"></a> [ipv6\_cidr\_block](#input\_ipv6\_cidr\_block) | (Optional) A specific IPv6 CIDR to request from the IPAM pool referenced by ipv6\_ipam\_pool\_id. Leave null to let IPAM choose a CIDR automatically using ipv6\_netmask\_length. | `string` | `null` | no |
| <a name="input_ipv6_cidr_block_network_border_group"></a> [ipv6\_cidr\_block\_network\_border\_group](#input\_ipv6\_cidr\_block\_network\_border\_group) | (Optional) The Network Border Group (e.g. a Local Zone) to restrict IPv6 address advertisement to. Defaults to the VPC's region when null. | `string` | `null` | no |
| <a name="input_ipv6_ipam_pool_id"></a> [ipv6\_ipam\_pool\_id](#input\_ipv6\_ipam\_pool\_id) | (Optional) The ID of an IPv6 IPAM pool to source the VPC's IPv6 CIDR from. When set, the VPC requests its IPv6 CIDR from this pool (via ipv6\_cidr\_block/ipv6\_netmask\_length) instead of an Amazon-provided block. Only used when enable\_ipv6 is true. | `string` | `null` | no |
| <a name="input_ipv6_netmask_length"></a> [ipv6\_netmask\_length](#input\_ipv6\_netmask\_length) | (Optional) The netmask length of the IPv6 CIDR to allocate from ipv6\_ipam\_pool\_id. Valid values are 44-60 in increments of 4. Also used (regardless of ipv6\_ipam\_pool\_id) to compute the /64 subnet carve-out math; defaults to 56, matching the fixed prefix length AWS assigns for Amazon-provided IPv6 CIDRs. | `number` | `56` | no |
| <a name="input_key_customer_master_key_spec"></a> [key\_customer\_master\_key\_spec](#input\_key\_customer\_master\_key\_spec) | (Optional) Specifies whether the flow logs KMS key contains a symmetric key or an asymmetric key pair. Defaults SYMMETRIC\_DEFAULT. Passed through to modules/aws/flow\_logs. | `string` | `"SYMMETRIC_DEFAULT"` | no |
| <a name="input_key_deletion_window_in_days"></a> [key\_deletion\_window\_in\_days](#input\_key\_deletion\_window\_in\_days) | (Optional) Duration in days (7-30) after which the flow logs KMS key is deleted after destruction of the resource. Defaults 30. Passed through to modules/aws/flow\_logs. | `number` | `30` | no |
| <a name="input_key_description"></a> [key\_description](#input\_key\_description) | (Optional) The description of the flow logs KMS key as viewed in the AWS console. Passed through to modules/aws/flow\_logs. | `string` | `"CloudWatch kms key used to encrypt flow logs"` | no |
| <a name="input_key_enable_key_rotation"></a> [key\_enable\_key\_rotation](#input\_key\_enable\_key\_rotation) | (Optional) Specifies whether automatic rotation is enabled for the flow logs KMS key. Defaults true. Passed through to modules/aws/flow\_logs. | `bool` | `true` | no |
| <a name="input_key_is_enabled"></a> [key\_is\_enabled](#input\_key\_is\_enabled) | (Optional) Specifies whether the flow logs KMS key is enabled. Defaults true. Passed through to modules/aws/flow\_logs. | `bool` | `true` | no |
| <a name="input_key_name_prefix"></a> [key\_name\_prefix](#input\_key\_name\_prefix) | (Optional) Creates an unique alias beginning with the specified prefix. The name must start with the word alias followed by a forward slash (alias/). | `string` | `"alias/flow_logs_key_"` | no |
| <a name="input_key_usage"></a> [key\_usage](#input\_key\_usage) | (Optional) Specifies the intended use of the flow logs KMS key. Defaults ENCRYPT\_DECRYPT. Passed through to modules/aws/flow\_logs. | `string` | `"ENCRYPT_DECRYPT"` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | (Optional) Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is true. | `bool` | `true` | no |
| <a name="input_mgmt_propagating_vgws"></a> [mgmt\_propagating\_vgws](#input\_mgmt\_propagating\_vgws) | A list of VGWs the mgmt route table should propagate. | `list(any)` | `null` | no |
| <a name="input_mgmt_subnets_list"></a> [mgmt\_subnets\_list](#input\_mgmt\_subnets\_list) | A list of mgmt subnets inside the VPC. | `list(string)` | <pre>[<br/>  "10.11.61.0/24",<br/>  "10.11.62.0/24",<br/>  "10.11.63.0/24"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Name to be tagged on all of the resources as an identifier | `string` | n/a | yes |
| <a name="input_private_propagating_vgws"></a> [private\_propagating\_vgws](#input\_private\_propagating\_vgws) | A list of VGWs the private route table should propagate. | `list(any)` | `null` | no |
| <a name="input_private_subnets_list"></a> [private\_subnets\_list](#input\_private\_subnets\_list) | A list of private subnets inside the VPC. | `list(string)` | <pre>[<br/>  "10.11.1.0/24",<br/>  "10.11.2.0/24",<br/>  "10.11.3.0/24"<br/>]</pre> | no |
| <a name="input_public_propagating_vgws"></a> [public\_propagating\_vgws](#input\_public\_propagating\_vgws) | A list of VGWs the public route table should propagate. | `list(any)` | `null` | no |
| <a name="input_public_subnets_list"></a> [public\_subnets\_list](#input\_public\_subnets\_list) | A list of public subnets inside the VPC. | `list(string)` | <pre>[<br/>  "10.11.201.0/24",<br/>  "10.11.202.0/24",<br/>  "10.11.203.0/24"<br/>]</pre> | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | (Optional) A boolean flag to enable/disable use of only a single shared NAT Gateway across all of your private networks. Defaults False. | `bool` | `false` | no |
| <a name="input_subnet_indices"></a> [subnet\_indices](#input\_subnet\_indices) | (Optional) List of indices into private\_subnets\_list identifying which private subnets the SSM VPC endpoints (enable\_ssm\_vpc\_endpoints) should be placed in. Defaults to just the first private subnet to minimize per-AZ interface endpoint charges; add more indices to spread SSM endpoints across additional AZs. Unlike the SSM endpoints, the ECR/CloudWatch Logs endpoints (enable\_ecr\_vpc\_endpoints) are always placed in every private subnet, since container image pulls must succeed from workloads in any AZ. | `list(number)` | <pre>[<br/>  0<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the object. | `map(string)` | <pre>{<br/>  "created_by": "<YOUR_NAME>",<br/>  "environment": "prod",<br/>  "priority": "high",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC. Ignored when ipv4\_ipam\_pool\_id is set, in which case the CIDR is sourced from the IPAM pool. | `string` | `"10.11.0.0/16"` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | (Optional) Map of additional VPC endpoints to create, keyed by an arbitrary, unique endpoint name. Use this to attach any Interface, Gateway, GatewayLoadBalancer, Resource, or ServiceNetwork endpoint not covered by enable\_ssm\_vpc\_endpoints/enable\_ecr\_vpc\_endpoints/enable\_s3\_endpoint, without editing this module (e.g. Secrets Manager, STS, EC2, SNS/SQS). Gateway-type endpoints default to being associated with every public and private route table this module manages unless route\_table\_ids is set explicitly. Each entry must set exactly one of service\_name, resource\_configuration\_arn, or service\_network\_arn. | <pre>map(object({<br/>    service_name               = optional(string)<br/>    resource_configuration_arn = optional(string)<br/>    service_network_arn        = optional(string)<br/>    service_region             = optional(string)<br/>    vpc_endpoint_type          = optional(string, "Interface")<br/>    auto_accept                = optional(bool)<br/>    policy                     = optional(string)<br/>    private_dns_enabled        = optional(bool, false)<br/>    ip_address_type            = optional(string)<br/>    security_group_ids         = optional(list(string), [])<br/>    subnet_ids                 = optional(list(string))<br/>    route_table_ids            = optional(list(string))<br/>    tags                       = optional(map(string), {})<br/>    dns_options = optional(object({<br/>      dns_record_ip_type                             = optional(string)<br/>      private_dns_only_for_inbound_resolver_endpoint = optional(bool)<br/>      private_dns_preference                         = optional(string)<br/>      private_dns_specified_domains                  = optional(list(string))<br/>    }))<br/>    subnet_configuration = optional(list(object({<br/>      ipv4      = optional(string)<br/>      ipv6      = optional(string)<br/>      subnet_id = optional(string)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_workspaces_propagating_vgws"></a> [workspaces\_propagating\_vgws](#input\_workspaces\_propagating\_vgws) | A list of VGWs the workspaces route table should propagate. | `list(any)` | `null` | no |
| <a name="input_workspaces_subnets_list"></a> [workspaces\_subnets\_list](#input\_workspaces\_subnets\_list) | A list of workspaces subnets inside the VPC. | `list(string)` | <pre>[<br/>  "10.11.21.0/24",<br/>  "10.11.22.0/24",<br/>  "10.11.23.0/24"<br/>]</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | n/a |
| <a name="output_custom_vpc_endpoint_ids"></a> [custom\_vpc\_endpoint\_ids](#output\_custom\_vpc\_endpoint\_ids) | Map of caller-defined VPC endpoint (var.vpc\_endpoints) names to their resource ids. |
| <a name="output_db_route_table_ids"></a> [db\_route\_table\_ids](#output\_db\_route\_table\_ids) | n/a |
| <a name="output_db_subnet_ids"></a> [db\_subnet\_ids](#output\_db\_subnet\_ids) | n/a |
| <a name="output_default_network_acl_id"></a> [default\_network\_acl\_id](#output\_default\_network\_acl\_id) | The ID of the network ACL created by default on VPC creation. |
| <a name="output_default_route_table_id"></a> [default\_route\_table\_id](#output\_default\_route\_table\_id) | The ID of the route table created by default on VPC creation. |
| <a name="output_default_security_group_id"></a> [default\_security\_group\_id](#output\_default\_security\_group\_id) | n/a |
| <a name="output_dhcp_options_id"></a> [dhcp\_options\_id](#output\_dhcp\_options\_id) | The ID of the DHCP options set associated with the VPC. |
| <a name="output_dmz_route_table_ids"></a> [dmz\_route\_table\_ids](#output\_dmz\_route\_table\_ids) | n/a |
| <a name="output_dmz_subnet_ids"></a> [dmz\_subnet\_ids](#output\_dmz\_subnet\_ids) | n/a |
| <a name="output_egress_only_internet_gateway_id"></a> [egress\_only\_internet\_gateway\_id](#output\_egress\_only\_internet\_gateway\_id) | The ID of the egress-only internet gateway used for outbound-only IPv6. Null when enable\_ipv6 is false. |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | n/a |
| <a name="output_internet_monitor_arn"></a> [internet\_monitor\_arn](#output\_internet\_monitor\_arn) | The ARN of the CloudWatch Internet Monitor. Null when enable\_internet\_monitor is false. |
| <a name="output_internet_monitor_id"></a> [internet\_monitor\_id](#output\_internet\_monitor\_id) | The ID (name) of the CloudWatch Internet Monitor. Null when enable\_internet\_monitor is false. |
| <a name="output_main_route_table_id"></a> [main\_route\_table\_id](#output\_main\_route\_table\_id) | The ID of the main route table associated with the VPC. |
| <a name="output_mgmt_route_table_ids"></a> [mgmt\_route\_table\_ids](#output\_mgmt\_route\_table\_ids) | n/a |
| <a name="output_mgmt_subnet_ids"></a> [mgmt\_subnet\_ids](#output\_mgmt\_subnet\_ids) | n/a |
| <a name="output_name"></a> [name](#output\_name) | The name of the VPC |
| <a name="output_nat_eips"></a> [nat\_eips](#output\_nat\_eips) | n/a |
| <a name="output_nat_eips_public_ips"></a> [nat\_eips\_public\_ips](#output\_nat\_eips\_public\_ips) | n/a |
| <a name="output_natgw_ids"></a> [natgw\_ids](#output\_natgw\_ids) | n/a |
| <a name="output_owner_id"></a> [owner\_id](#output\_owner\_id) | The ID of the AWS account that owns the VPC. |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | n/a |
| <a name="output_private_subnet_arns"></a> [private\_subnet\_arns](#output\_private\_subnet\_arns) | List of ARNs of private subnets |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | n/a |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | n/a |
| <a name="output_public_route_table_ids"></a> [public\_route\_table\_ids](#output\_public\_route\_table\_ids) | n/a |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | n/a |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | n/a |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | A map of tags assigned to the VPC, including those inherited from the provider default\_tags configuration block. |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | The ARN of the VPC |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | n/a |
| <a name="output_vpc_endpoint_security_group_id"></a> [vpc\_endpoint\_security\_group\_id](#output\_vpc\_endpoint\_security\_group\_id) | The ID of the security group attached to the SSM/ECR/CloudWatch Logs VPC endpoints. |
| <a name="output_vpc_endpoint_security_group_name"></a> [vpc\_endpoint\_security\_group\_name](#output\_vpc\_endpoint\_security\_group\_name) | The name of the security group attached to the SSM/ECR/CloudWatch Logs VPC endpoints. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
| <a name="output_vpc_ipv6_association_id"></a> [vpc\_ipv6\_association\_id](#output\_vpc\_ipv6\_association\_id) | The association ID for the VPC's IPv6 CIDR block. Null when enable\_ipv6 is false. |
| <a name="output_vpc_ipv6_cidr_block"></a> [vpc\_ipv6\_cidr\_block](#output\_vpc\_ipv6\_cidr\_block) | The IPv6 CIDR block assigned to the VPC. Null when enable\_ipv6 is false. |
| <a name="output_workspaces_route_table_ids"></a> [workspaces\_route\_table\_ids](#output\_workspaces\_route\_table\_ids) | n/a |
| <a name="output_workspaces_subnet_ids"></a> [workspaces\_subnet\_ids](#output\_workspaces\_subnet\_ids) | n/a |
<!-- END_TF_DOCS -->

<!-- NOTES -->

## Notes / Design Decisions

- **IPv4-only by default.** IPv6 is fully opt-in via `enable_ipv6`; existing deployments are unaffected. See the IPv6 usage example above.
- **SSM endpoint subnet placement is cost-optimized; ECR endpoint placement is availability-optimized.** `enable_ssm_vpc_endpoints` places its six interface endpoints in only the private subnets listed in `subnet_indices` (default: just the first one) to minimize per-AZ hourly interface-endpoint charges, since SSM/EC2Messages/KMS traffic is mostly management-plane. `enable_ecr_vpc_endpoints` places its endpoints in *every* private subnet instead, since container image pulls need to succeed from workloads in any AZ. Add more indices to `subnet_indices` if you need SSM endpoints reachable from additional AZs.
- **The composed VPC-endpoint security group has no configurable ingress/egress beyond HTTPS from the VPC's own CIDR.** It's shared by the SSM and ECR/CloudWatch-Logs endpoint families; if you need different rules, attach your own security group to a `vpc_endpoints` entry instead.
- **`vpc_endpoints` is additive to, not a replacement for, the `enable_*` shortcuts.** Both mechanisms can be used together; `vpc_endpoints` exists for services the shortcuts don't cover.
- **`additional_routes` fans a single route definition out across every route table in the tier(s) you select** (mirroring how the built-in NAT/firewall default routes are replicated per AZ), rather than targeting one specific route table -- there's currently no way to add a route to only one AZ's route table within a tier.
- **The nested `flow_logs` module's full variable surface is now forwarded**, but its internal resources (KMS key, IAM role/policy) are still entirely owned and created by that module -- see [`../flow_logs`](../flow_logs) if you need finer control (e.g. reusing an existing KMS key) than this module's pass-through variables expose.

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
