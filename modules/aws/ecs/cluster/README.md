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

<h3 align="center">ECS Cluster</h3>
  <p align="center">
    Manages an AWS ECS cluster (aws_ecs_cluster) and its capacity provider associations with secure, Well-Architected defaults.
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

<!-- ABOUT THE MODULE -->

## About The Module

This module manages an AWS ECS cluster (`aws_ecs_cluster`) plus its capacity
provider associations (`aws_ecs_cluster_capacity_providers`, the standalone
resource rather than the deprecated in-line cluster arguments). Container
Insights is enabled by default and ECS Exec (execute-command) logging is
configured with KMS-encrypted CloudWatch logs out of the box.

Cross-cutting concerns are satisfied by composition rather than inline
resources: the KMS key is created via `modules/aws/kms` and the exec-command log
group via `modules/aws/cloudwatch/log_group`.

### Prerequisites

- For Service Connect defaults, a Cloud Map namespace ARN (create one with
  `modules/aws/ecs/namespace`) passed via `service_connect_namespace_arn`.
- For EC2 capacity, EC2-backed capacity providers (create them with
  `modules/aws/ecs/capacity_provider`) whose names are passed via
  `capacity_providers`.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "ecs_namespace" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ecs/namespace"

  name = "example-app"
}

module "ecs_cluster" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ecs/cluster"

  name                          = "example-app"
  service_connect_namespace_arn = module.ecs_namespace.arn

  # Secure defaults below are shown for clarity; they apply automatically.
  container_insights             = "enabled"
  enable_execute_command_logging = true
  create_kms_key                 = true
  create_cloud_watch_log_group   = true

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  tags = {
    Team       = "platform"
    CostCenter = "12345"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

## Notes / Design Decisions

- Container Insights is enabled by default (CKV_AWS_65) for observability.
- ECS Exec logging is encrypted by default: a CMK is created via the KMS module
  and the exec-command log group via the CloudWatch log group module, satisfying
  CKV_AWS_158. The created CMK's key policy allows the regional CloudWatch Logs
  service principal so the encrypted log group works without further tuning.
- Capacity providers are managed through the standalone
  `aws_ecs_cluster_capacity_providers` resource, not the deprecated in-line
  cluster arguments.
- Fargate / Fargate Spot are referenced by name; EC2 capacity providers must be
  created separately (see `modules/aws/ecs/capacity_provider`) and their names
  added to `capacity_providers`.
- Single cluster per block. Run several clusters via separate blocks or
  `for_each` on the module.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.54.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_kms"></a> [kms](#module\_kms) | ../../kms | n/a |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../cloudwatch/log_group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_settings"></a> [additional\_settings](#input\_additional\_settings) | (Optional) Additional `setting` blocks to apply to the cluster, beyond `containerInsights`. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_capacity_providers"></a> [capacity\_providers](#input\_capacity\_providers) | (Optional) List of capacity provider names to associate with the cluster via aws\_ecs\_cluster\_capacity\_providers. | `list(string)` | <pre>[<br/>  "FARGATE",<br/>  "FARGATE_SPOT"<br/>]</pre> | no |
| <a name="input_cloud_watch_encryption_enabled"></a> [cloud\_watch\_encryption\_enabled](#input\_cloud\_watch\_encryption\_enabled) | (Optional) Whether to enable encryption on the CloudWatch logs for exec-command. Defaults to true. | `bool` | `true` | no |
| <a name="input_cloud_watch_log_group_name"></a> [cloud\_watch\_log\_group\_name](#input\_cloud\_watch\_log\_group\_name) | (Optional) Name of an existing CloudWatch log group to send exec-command logs to. Used when `create_cloud_watch_log_group = false`. | `string` | `null` | no |
| <a name="input_container_insights"></a> [container\_insights](#input\_container\_insights) | (Optional) Value for the `containerInsights` cluster setting. Valid values are `enabled`, `enhanced`, and `disabled`. Defaults to `enabled` for secure, observable defaults. | `string` | `"enabled"` | no |
| <a name="input_create_cloud_watch_log_group"></a> [create\_cloud\_watch\_log\_group](#input\_create\_cloud\_watch\_log\_group) | (Optional) Whether to create the exec-command CloudWatch log group (via modules/aws/cloudwatch/log\_group). Defaults to true. | `bool` | `true` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | (Optional) Whether to create a customer-managed KMS key (via modules/aws/kms) for exec-command logging and managed storage encryption. Defaults to true. | `bool` | `true` | no |
| <a name="input_default_capacity_provider_strategy"></a> [default\_capacity\_provider\_strategy](#input\_default\_capacity\_provider\_strategy) | (Optional) The default capacity provider strategy for the cluster. Defaults to a Fargate-weighted strategy. | <pre>list(object({<br/>    capacity_provider = string<br/>    base              = optional(number)<br/>    weight            = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "base": 1,<br/>    "capacity_provider": "FARGATE",<br/>    "weight": 100<br/>  }<br/>]</pre> | no |
| <a name="input_enable_execute_command_logging"></a> [enable\_execute\_command\_logging](#input\_enable\_execute\_command\_logging) | (Optional) Whether to configure encrypted ECS Exec (execute-command) logging on the cluster. Defaults to true. | `bool` | `true` | no |
| <a name="input_execute_command_logging"></a> [execute\_command\_logging](#input\_execute\_command\_logging) | (Optional) The log setting to use for redirecting logs for ECS Exec results. Valid values are `NONE`, `DEFAULT`, and `OVERRIDE`. Defaults to `OVERRIDE`. | `string` | `"OVERRIDE"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | (Optional) Bring-your-own CMK ARN for exec-command logging. Used when `create_kms_key = false`. | `string` | `null` | no |
| <a name="input_log_group_retention_in_days"></a> [log\_group\_retention\_in\_days](#input\_log\_group\_retention\_in\_days) | (Optional) Retention period, in days, for the created exec-command CloudWatch log group. Defaults to 365. | `number` | `365` | no |
| <a name="input_managed_storage_kms_key_arn"></a> [managed\_storage\_kms\_key\_arn](#input\_managed\_storage\_kms\_key\_arn) | (Optional) KMS key ARN used to encrypt Fargate ephemeral (managed) storage. Defaults to the created CMK when `create_kms_key = true`. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the ECS cluster and the value of its `Name` tag. | `string` | n/a | yes |
| <a name="input_s3_bucket_encryption_enabled"></a> [s3\_bucket\_encryption\_enabled](#input\_s3\_bucket\_encryption\_enabled) | (Optional) Whether to enable encryption on the S3 logs for exec-command. Defaults to true. | `bool` | `true` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | (Optional) Name of the S3 bucket to send exec-command logs to. | `string` | `null` | no |
| <a name="input_s3_key_prefix"></a> [s3\_key\_prefix](#input\_s3\_key\_prefix) | (Optional) Optional folder/prefix in the S3 bucket to place exec-command logs. | `string` | `null` | no |
| <a name="input_service_connect_namespace_arn"></a> [service\_connect\_namespace\_arn](#input\_service\_connect\_namespace\_arn) | (Optional) The Cloud Map namespace ARN used for the cluster's `service_connect_defaults`. When null, no default Service Connect namespace is configured. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the cluster and the resources created via composition. A `Name` tag is merged automatically. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN that identifies the ECS cluster. |
| <a name="output_cloud_watch_log_group_arn"></a> [cloud\_watch\_log\_group\_arn](#output\_cloud\_watch\_log\_group\_arn) | The ARN of the exec-command CloudWatch log group, when created. |
| <a name="output_cloud_watch_log_group_name"></a> [cloud\_watch\_log\_group\_name](#output\_cloud\_watch\_log\_group\_name) | The name of the exec-command CloudWatch log group, when created. |
| <a name="output_id"></a> [id](#output\_id) | The ID (ARN) of the ECS cluster. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the CMK created for exec-command logging and managed storage encryption, when created. |
| <a name="output_name"></a> [name](#output\_name) | The name of the ECS cluster. |
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
