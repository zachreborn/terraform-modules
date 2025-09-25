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

<h3 align="center">Flow Logs Module</h3>
  <p align="center">
    This module sets up each componenet required to capture Flow Logs with the parameters specified. By default this module will be set up to work without any changes to variables other than the flow log capture source. The result of this module creates a unique cloudwatch log group with a prefix of 'flow_logs', an IAM policy and IAM role which can be used with ENI flow logs to deliver logs to that cloudwatch log group. One of flow_eni_ids, flow_subnet_ids, flow_transit_gateway_ids, flow_transit_gateway_attachment_ids, or flow_vpc_ids must be provided.
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

This simple example creates a flow log for a VPC. The flow logs are delivered to a CloudWatch Logs log group.

```
module "flow_logs" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/flow_logs"

    flow_vpc_ids = module.vpc.id
}
```

### VPC Example

This example configures Flow Logs to capture all traffic in a VPC. The flow logs are delivered to a CloudWatch Logs log group.

```
module "vpc_flow_logs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/flow_logs"

  cloudwatch_name_prefix          = var.cloudwatch_name_prefix
  cloudwatch_retention_in_days    = var.cloudwatch_retention_in_days
  iam_policy_name_prefix          = var.iam_policy_name_prefix
  iam_policy_path                 = var.iam_policy_path
  iam_role_description            = var.iam_role_description
  iam_role_name_prefix            = var.iam_role_name_prefix
  key_name_prefix                 = var.key_name_prefix
  flow_deliver_cross_account_role = var.flow_deliver_cross_account_role
  flow_log_destination_type       = var.flow_log_destination_type
  flow_log_format                 = var.flow_log_format
  flow_max_aggregation_interval   = var.flow_max_aggregation_interval
  flow_traffic_type               = var.flow_traffic_type
  flow_vpc_ids                     = aws_vpc.vpc.id
  tags                            = var.tags
}
```

### Transit Gateway Example

This example configures Flow Logs to capture all traffic in a Transit Gateway. The flow logs are delivered to a CloudWatch Logs log group.

```
module "vpc_flow_logs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/flow_logs"

  cloudwatch_name_prefix          = var.cloudwatch_name_prefix
  cloudwatch_retention_in_days    = var.cloudwatch_retention_in_days
  iam_policy_name_prefix          = var.iam_policy_name_prefix
  iam_policy_path                 = var.iam_policy_path
  iam_role_description            = var.iam_role_description
  iam_role_name_prefix            = var.iam_role_name_prefix
  key_name_prefix                 = var.key_name_prefix
  flow_deliver_cross_account_role = var.flow_deliver_cross_account_role
  flow_log_destination_type       = var.flow_log_destination_type
  flow_log_format                 = var.flow_log_format
  flow_max_aggregation_interval   = var.flow_max_aggregation_interval
  flow_traffic_type               = var.flow_traffic_type
  flow_transit_gateway_ids         = aws_ec2_transit_gateway.transit_gateway.id
  tags                            = var.tags
}

```

### Transit Gateway Attachment Example

This example configures Flow Logs to capture all traffic in a Transit Gateway Attachment. The flow logs are delivered to a CloudWatch Logs log group.

```
module "vpc_flow_logs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/flow_logs"

  cloudwatch_name_prefix             = var.cloudwatch_name_prefix
  cloudwatch_retention_in_days       = var.cloudwatch_retention_in_days
  iam_policy_name_prefix             = var.iam_policy_name_prefix
  iam_policy_path                    = var.iam_policy_path
  iam_role_description               = var.iam_role_description
  iam_role_name_prefix               = var.iam_role_name_prefix
  key_name_prefix                    = var.key_name_prefix
  flow_deliver_cross_account_role    = var.flow_deliver_cross_account_role
  flow_log_destination_type          = var.flow_log_destination_type
  flow_log_format                    = var.flow_log_format
  flow_max_aggregation_interval      = var.flow_max_aggregation_interval
  flow_traffic_type                  = var.flow_traffic_type
  flow_transit_gateway_attachment_ids = aws_ec2_transit_gateway_vpc_attachment.this.id
  tags                               = var.tags
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

| Name                                                                                                                                                 | Type        |
| ---------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_cloudwatch_log_group.log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)               | resource    |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log)                                            | resource    |
| [aws_iam_policy.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                      | resource    |
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                            | resource    |
| [aws_iam_role_policy_attachment.role_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource    |
| [aws_kms_alias.alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias)                                         | resource    |
| [aws_kms_key.key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key)                                               | resource    |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                        | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                          | data source |

## Inputs

| Name                                                                                                                                       | Description                                                                                                                                                                                                                                                                                                                                                                                           | Type           | Default                                                                                                                                                                                                                                       | Required |
| ------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_cloudwatch_name_prefix"></a> [cloudwatch_name_prefix](#input_cloudwatch_name_prefix)                                        | (Optional, Forces new resource) Creates a unique name beginning with the specified prefix.                                                                                                                                                                                                                                                                                                            | `string`       | `"flow_logs_"`                                                                                                                                                                                                                                |    no    |
| <a name="input_cloudwatch_retention_in_days"></a> [cloudwatch_retention_in_days](#input_cloudwatch_retention_in_days)                      | (Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire.                                                                                                           | `number`       | `90`                                                                                                                                                                                                                                          |    no    |
| <a name="input_flow_deliver_cross_account_role"></a> [flow_deliver_cross_account_role](#input_flow_deliver_cross_account_role)             | (Optional) The ARN of the IAM role that posts logs to CloudWatch Logs in a different account.                                                                                                                                                                                                                                                                                                         | `string`       | `null`                                                                                                                                                                                                                                        |    no    |
| <a name="input_flow_eni_ids"></a> [flow_eni_ids](#input_flow_eni_ids)                                                                      | (Optional) List of Elastic Network Interface IDs to attach the flow logs to.                                                                                                                                                                                                                                                                                                                          | `list(string)` | `null`                                                                                                                                                                                                                                        |    no    |
| <a name="input_flow_log_destination_type"></a> [flow_log_destination_type](#input_flow_log_destination_type)                               | (Optional) The type of the logging destination. Valid values: cloud-watch-logs, s3. Default: cloud-watch-logs.                                                                                                                                                                                                                                                                                        | `string`       | `"cloud-watch-logs"`                                                                                                                                                                                                                          |    no    |
| <a name="input_flow_log_format"></a> [flow_log_format](#input_flow_log_format)                                                             | (Optional) The fields to include in the flow log record, in the order in which they should appear. For more information, see Flow Log Records. Default: fields are in the order that they are described in the Flow Log Records section.                                                                                                                                                              | `string`       | `null`                                                                                                                                                                                                                                        |    no    |
| <a name="input_flow_max_aggregation_interval"></a> [flow_max_aggregation_interval](#input_flow_max_aggregation_interval)                   | (Optional) The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: 60 seconds (1 minute) or 600 seconds (10 minutes). Default: 600.                                                                                                                                                                                              | `number`       | `60`                                                                                                                                                                                                                                          |    no    |
| <a name="input_flow_subnet_ids"></a> [flow_subnet_ids](#input_flow_subnet_ids)                                                             | (Optional) List of Subnet IDs to attach the flow logs to.                                                                                                                                                                                                                                                                                                                                             | `list(string)` | `null`                                                                                                                                                                                                                                        |    no    |
| <a name="input_flow_traffic_type"></a> [flow_traffic_type](#input_flow_traffic_type)                                                       | (Optional) The type of traffic to capture. Valid values: ACCEPT,REJECT, ALL.                                                                                                                                                                                                                                                                                                                          | `string`       | `"ALL"`                                                                                                                                                                                                                                       |    no    |
| <a name="input_flow_transit_gateway_attachment_ids"></a> [flow_transit_gateway_attachment_ids](#input_flow_transit_gateway_attachment_ids) | (Optional) List of IDs of the transit gateway attachments to attach the flow logs to.                                                                                                                                                                                                                                                                                                                 | `list(string)` | `null`                                                                                                                                                                                                                                        |    no    |
| <a name="input_flow_transit_gateway_ids"></a> [flow_transit_gateway_ids](#input_flow_transit_gateway_ids)                                  | (Optional) List of IDs of the transit gateways to attach the flow logs to.                                                                                                                                                                                                                                                                                                                            | `list(string)` | `null`                                                                                                                                                                                                                                        |    no    |
| <a name="input_flow_vpc_ids"></a> [flow_vpc_ids](#input_flow_vpc_ids)                                                                      | (Optional) List of VPC IDs to attach the flow logs to.                                                                                                                                                                                                                                                                                                                                                | `list(string)` | `null`                                                                                                                                                                                                                                        |    no    |
| <a name="input_iam_policy_description"></a> [iam_policy_description](#input_iam_policy_description)                                        | (Optional, Forces new resource) Description of the IAM policy.                                                                                                                                                                                                                                                                                                                                        | `string`       | `"Used with flow logs to send packet capture logs to a CloudWatch log group."`                                                                                                                                                                |    no    |
| <a name="input_iam_policy_name_prefix"></a> [iam_policy_name_prefix](#input_iam_policy_name_prefix)                                        | (Optional, Forces new resource) Creates a unique name beginning with the specified prefix. Conflicts with name.                                                                                                                                                                                                                                                                                       | `string`       | `"flow_log_policy_"`                                                                                                                                                                                                                          |    no    |
| <a name="input_iam_policy_path"></a> [iam_policy_path](#input_iam_policy_path)                                                             | (Optional, default '/') Path in which to create the policy. See IAM Identifiers for more information.                                                                                                                                                                                                                                                                                                 | `string`       | `"/"`                                                                                                                                                                                                                                         |    no    |
| <a name="input_iam_role_assume_role_policy"></a> [iam_role_assume_role_policy](#input_iam_role_assume_role_policy)                         | (Required) The policy that grants an entity permission to assume the role.                                                                                                                                                                                                                                                                                                                            | `string`       | `"{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Principal\": {\n        \"Service\": \"vpc-flow-logs.amazonaws.com\"\n      },\n      \"Action\": \"sts:AssumeRole\"\n    }\n  ]\n}\n"` |    no    |
| <a name="input_iam_role_description"></a> [iam_role_description](#input_iam_role_description)                                              | (Optional) The description of the role.                                                                                                                                                                                                                                                                                                                                                               | `string`       | `"Role utilized for EC2 instances ENI flow logs. This role allows creation of log streams and adding logs to the log streams in cloudwatch"`                                                                                                  |    no    |
| <a name="input_iam_role_force_detach_policies"></a> [iam_role_force_detach_policies](#input_iam_role_force_detach_policies)                | (Optional) Specifies to force detaching any policies the role has before destroying it. Defaults to false.                                                                                                                                                                                                                                                                                            | `bool`         | `false`                                                                                                                                                                                                                                       |    no    |
| <a name="input_iam_role_max_session_duration"></a> [iam_role_max_session_duration](#input_iam_role_max_session_duration)                   | (Optional) The maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours.                                                                                                                                                  | `number`       | `3600`                                                                                                                                                                                                                                        |    no    |
| <a name="input_iam_role_name_prefix"></a> [iam_role_name_prefix](#input_iam_role_name_prefix)                                              | (Required, Forces new resource) Creates a unique friendly name beginning with the specified prefix. Conflicts with name.                                                                                                                                                                                                                                                                              | `string`       | `"flow_logs_role_"`                                                                                                                                                                                                                           |    no    |
| <a name="input_iam_role_permissions_boundary"></a> [iam_role_permissions_boundary](#input_iam_role_permissions_boundary)                   | (Optional) The ARN of the policy that is used to set the permissions boundary for the role.                                                                                                                                                                                                                                                                                                           | `string`       | `""`                                                                                                                                                                                                                                          |    no    |
| <a name="input_key_customer_master_key_spec"></a> [key_customer_master_key_spec](#input_key_customer_master_key_spec)                      | (Optional) Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values: SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1. Defaults to SYMMETRIC_DEFAULT. For help with choosing a key spec, see the AWS KMS Developer Guide. | `string`       | `"SYMMETRIC_DEFAULT"`                                                                                                                                                                                                                         |    no    |
| <a name="input_key_deletion_window_in_days"></a> [key_deletion_window_in_days](#input_key_deletion_window_in_days)                         | (Optional) Duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days. Defaults to 30 days.                                                                                                                                                                                                                                                     | `number`       | `30`                                                                                                                                                                                                                                          |    no    |
| <a name="input_key_description"></a> [key_description](#input_key_description)                                                             | (Optional) The description of the key as viewed in AWS console.                                                                                                                                                                                                                                                                                                                                       | `string`       | `"CloudWatch kms key used to encrypt flow logs"`                                                                                                                                                                                              |    no    |
| <a name="input_key_enable_key_rotation"></a> [key_enable_key_rotation](#input_key_enable_key_rotation)                                     | (Optional) Specifies whether key rotation is enabled. Defaults to true.                                                                                                                                                                                                                                                                                                                               | `bool`         | `true`                                                                                                                                                                                                                                        |    no    |
| <a name="input_key_is_enabled"></a> [key_is_enabled](#input_key_is_enabled)                                                                | (Optional) Specifies whether the key is enabled. Defaults to true.                                                                                                                                                                                                                                                                                                                                    | `string`       | `true`                                                                                                                                                                                                                                        |    no    |
| <a name="input_key_name_prefix"></a> [key_name_prefix](#input_key_name_prefix)                                                             | (Optional) Creates an unique alias beginning with the specified prefix. The name must start with the word alias followed by a forward slash (alias/).                                                                                                                                                                                                                                                 | `string`       | `"alias/flow_logs_key_"`                                                                                                                                                                                                                      |    no    |
| <a name="input_key_usage"></a> [key_usage](#input_key_usage)                                                                               | (Optional) Specifies the intended use of the key. Defaults to ENCRYPT_DECRYPT, and only symmetric encryption and decryption are supported.                                                                                                                                                                                                                                                            | `string`       | `"ENCRYPT_DECRYPT"`                                                                                                                                                                                                                           |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                                              | (Optional) A mapping of tags to assign to the object.                                                                                                                                                                                                                                                                                                                                                 | `map(any)`     | <pre>{<br/> "created_by": "<YOUR_NAME>",<br/> "environment": "prod",<br/> "priority": "high",<br/> "terraform": "true"<br/>}</pre>                                                                                                            |    no    |

## Outputs

| Name                                         | Description                                        |
| -------------------------------------------- | -------------------------------------------------- |
| <a name="output_arn"></a> [arn](#output_arn) | ARN of the cloudwatch log group used for flow logs |

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
