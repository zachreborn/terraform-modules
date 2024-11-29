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

<h3 align="center">Transit Gateway Attachment Module</h3>
  <p align="center">
    This module attaches one or more VPCs to transit gateway. Transit gateways attach to VPCs using VPC attachments. VPC attachments create ENI's in the VPC's subnets allowing traffic to route between the VPC and the transit gateway. This module also supports enabling flow logs on the VPC attachments by default.
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

This example attaches a single VPC to the transit gateway.

```
module "sdwan_vpc_transit_gateway_attachment" {
    source             = "github.com/zachreborn/terraform-modules//modules/aws/transit_gateway/attachment"

    transit_gateway_id = module.transit_gateway.id
    vpc_ids = {
     "transit_vpc" = {
       subnet_ids             = ["subnet-12345678", "subnet-87654321"]
       vpc_id                 = "vpc-12345678"
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

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 4.0.0 |

## Providers

| Name                                             | Version  |
| ------------------------------------------------ | -------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | >= 4.0.0 |

## Modules

| Name                                                                       | Source          | Version |
| -------------------------------------------------------------------------- | --------------- | ------- |
| <a name="module_vpc_flow_logs"></a> [vpc_flow_logs](#module_vpc_flow_logs) | ../../flow_logs | n/a     |

## Resources

| Name                                                                                                                                                          | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [aws_ec2_transit_gateway_vpc_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |

## Inputs

| Name                                                                                                                                                                           | Description                                                                                                                                                                                                                                                                                 | Type        | Default                                                                                                                        | Required |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------ | :------: |
| <a name="input_appliance_mode_support"></a> [appliance_mode_support](#input_appliance_mode_support)                                                                            | (Optional) Whether Appliance Mode support is enabled. If enabled, a traffic flow between a source and destination uses the same Availability Zone for the VPC attachment for the lifetime of that flow.                                                                                     | `string`    | `"disable"`                                                                                                                    |    no    |
| <a name="input_cloudwatch_name_prefix"></a> [cloudwatch_name_prefix](#input_cloudwatch_name_prefix)                                                                            | (Optional, Forces new resource) Creates a unique name beginning with the specified prefix.                                                                                                                                                                                                  | `string`    | `"flow_logs_"`                                                                                                                 |    no    |
| <a name="input_cloudwatch_retention_in_days"></a> [cloudwatch_retention_in_days](#input_cloudwatch_retention_in_days)                                                          | (Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire. | `number`    | `90`                                                                                                                           |    no    |
| <a name="input_dns_support"></a> [dns_support](#input_dns_support)                                                                                                             | (Optional) Whether DNS support is enabled. Valid values: disable, enable. Default value: enable.                                                                                                                                                                                            | `string`    | `"enable"`                                                                                                                     |    no    |
| <a name="input_enable_flow_logs"></a> [enable_flow_logs](#input_enable_flow_logs)                                                                                              | (Optional) A boolean flag to enable/disable the use of flow logs with the resources. Defaults True.                                                                                                                                                                                         | `bool`      | `true`                                                                                                                         |    no    |
| <a name="input_flow_deliver_cross_account_role"></a> [flow_deliver_cross_account_role](#input_flow_deliver_cross_account_role)                                                 | (Optional) The ARN of the IAM role that posts logs to CloudWatch Logs in a different account.                                                                                                                                                                                               | `string`    | `null`                                                                                                                         |    no    |
| <a name="input_flow_log_destination_type"></a> [flow_log_destination_type](#input_flow_log_destination_type)                                                                   | (Optional) The type of the logging destination. Valid values: cloud-watch-logs, s3. Default: cloud-watch-logs.                                                                                                                                                                              | `string`    | `"cloud-watch-logs"`                                                                                                           |    no    |
| <a name="input_flow_log_format"></a> [flow_log_format](#input_flow_log_format)                                                                                                 | (Optional) The fields to include in the flow log record, in the order in which they should appear. For more information, see Flow Log Records. Default: fields are in the order that they are described in the Flow Log Records section.                                                    | `string`    | `null`                                                                                                                         |    no    |
| <a name="input_flow_max_aggregation_interval"></a> [flow_max_aggregation_interval](#input_flow_max_aggregation_interval)                                                       | (Optional) The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: 60 seconds (1 minute) or 600 seconds (10 minutes). Default: 600.                                                                                    | `number`    | `60`                                                                                                                           |    no    |
| <a name="input_flow_traffic_type"></a> [flow_traffic_type](#input_flow_traffic_type)                                                                                           | (Optional) The type of traffic to capture. Valid values: ACCEPT,REJECT, ALL.                                                                                                                                                                                                                | `string`    | `"ALL"`                                                                                                                        |    no    |
| <a name="input_iam_policy_name_prefix"></a> [iam_policy_name_prefix](#input_iam_policy_name_prefix)                                                                            | (Optional, Forces new resource) Creates a unique name beginning with the specified prefix. Conflicts with name.                                                                                                                                                                             | `string`    | `"flow_log_policy_"`                                                                                                           |    no    |
| <a name="input_iam_policy_path"></a> [iam_policy_path](#input_iam_policy_path)                                                                                                 | (Optional, default '/') Path in which to create the policy. See IAM Identifiers for more information.                                                                                                                                                                                       | `string`    | `"/"`                                                                                                                          |    no    |
| <a name="input_iam_role_description"></a> [iam_role_description](#input_iam_role_description)                                                                                  | (Optional) The description of the role.                                                                                                                                                                                                                                                     | `string`    | `"Role utilized for VPC flow logs. This role allows creation of log streams and adding logs to the log streams in cloudwatch"` |    no    |
| <a name="input_iam_role_name_prefix"></a> [iam_role_name_prefix](#input_iam_role_name_prefix)                                                                                  | (Required, Forces new resource) Creates a unique friendly name beginning with the specified prefix. Conflicts with name.                                                                                                                                                                    | `string`    | `"flow_logs_role_"`                                                                                                            |    no    |
| <a name="input_ipv6_support"></a> [ipv6_support](#input_ipv6_support)                                                                                                          | (Optional) Whether IPv6 support is enabled. Valid values: disable, enable. Default value: disable.                                                                                                                                                                                          | `string`    | `"disable"`                                                                                                                    |    no    |
| <a name="input_key_name_prefix"></a> [key_name_prefix](#input_key_name_prefix)                                                                                                 | (Optional) Creates an unique alias beginning with the specified prefix. The name must start with the word alias followed by a forward slash (alias/).                                                                                                                                       | `string`    | `"alias/flow_logs_key_"`                                                                                                       |    no    |
| <a name="input_name"></a> [name](#input_name)                                                                                                                                  | (Required) The name of the transit gateway attachment                                                                                                                                                                                                                                       | `string`    | n/a                                                                                                                            |   yes    |
| <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)                                                                                                                | (Required) Identifiers of EC2 Subnets.                                                                                                                                                                                                                                                      | `list(any)` | n/a                                                                                                                            |   yes    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                                                                                  | (Optional) Map of tags for the EC2 Transit Gateway.                                                                                                                                                                                                                                         | `map(any)`  | <pre>{<br/> "environment": "prod",<br/> "project": "core_infrastructure",<br/> "terraform": "true"<br/>}</pre>                 |    no    |
| <a name="input_transit_gateway_default_route_table_association"></a> [transit_gateway_default_route_table_association](#input_transit_gateway_default_route_table_association) | (Optional) Boolean whether the VPC Attachment should be associated with the EC2 Transit Gateway association default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways. Default value: true.                        | `bool`      | `true`                                                                                                                         |    no    |
| <a name="input_transit_gateway_default_route_table_propagation"></a> [transit_gateway_default_route_table_propagation](#input_transit_gateway_default_route_table_propagation) | (Optional) Boolean whether the VPC Attachment should propagate routes with the EC2 Transit Gateway propagation default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways. Default value: true.                     | `bool`      | `true`                                                                                                                         |    no    |
| <a name="input_transit_gateway_id"></a> [transit_gateway_id](#input_transit_gateway_id)                                                                                        | (Required) Identifier of EC2 Transit Gateway.                                                                                                                                                                                                                                               | `string`    | n/a                                                                                                                            |   yes    |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)                                                                                                                            | (Required) Identifier of the VPC.                                                                                                                                                                                                                                                           | `string`    | n/a                                                                                                                            |   yes    |

## Outputs

| Name                                                                    | Description |
| ----------------------------------------------------------------------- | ----------- |
| <a name="output_id"></a> [id](#output_id)                               | n/a         |
| <a name="output_vpc_owner_id"></a> [vpc_owner_id](#output_vpc_owner_id) | n/a         |

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
