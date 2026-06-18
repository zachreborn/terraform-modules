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

<h3 align="center">ECS Task Definition</h3>
  <p align="center">
    Manages an AWS ECS task definition (aws_ecs_task_definition) with least-privilege, separate task and execution roles.
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

This module manages an AWS ECS task definition (`aws_ecs_task_definition`) with
Fargate / `awsvpc` defaults. By default it creates separate, least-privilege
execution and task IAM roles via composition with `modules/aws/iam/role` (and
`modules/aws/iam/policy` for an optional inline task-role policy) rather than
declaring IAM resources inline.

Container definitions are supplied by the caller as a JSON document; the module
does not author or introspect them.

### Prerequisites

- A caller-supplied `container_definitions` JSON document. The
  `jsonencode(...)` function or `templatefile(...)` are helpful here.
- Container images (e.g. an ECR repository created via `modules/aws/ecr`).
- For EFS/FSx volumes, the corresponding file systems must already exist.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "ecs_task_definition" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ecs/task_definition"

  family = "example-app"
  cpu    = "256"
  memory = "512"

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example-app:latest"
      essential = true
      portMappings = [
        {
          name          = "http"
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])

  # Least-privilege, separate roles are created by default.
  create_execution_role = true
  create_task_role      = true

  tags = {
    Team       = "platform"
    CostCenter = "12345"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

## Notes / Design Decisions

- Separate task and execution roles are created by default (CKV_AWS_249),
  composing `modules/aws/iam/role`; no inline `aws_iam_role` is declared.
- An optional least-privilege task-role policy can be supplied as JSON via
  `task_role_policy_json`; it is created with `modules/aws/iam/policy` and
  attached to the task role.
- EFS volumes default to transit encryption `ENABLED` (CKV_AWS_97).
- Single resource per block. Scale to multiple task definitions by calling this
  module with `for_each`, or use the integrated `modules/aws/ecs` root module.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.50.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_execution_role"></a> [execution\_role](#module\_execution\_role) | ../../iam/role | n/a |
| <a name="module_task_role"></a> [task\_role](#module\_task\_role) | ../../iam/role | n/a |
| <a name="module_task_role_policy"></a> [task\_role\_policy](#module\_task\_role\_policy) | ../../iam/policy | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | (Required) A JSON-encoded string of container definitions. This is supplied by the caller; the module does not author container definitions. | `string` | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | (Optional) Number of CPU units used by the task, as a string. Required for Fargate. | `string` | `null` | no |
| <a name="input_create_execution_role"></a> [create\_execution\_role](#input\_create\_execution\_role) | (Optional) Whether to create an ECS task execution role (via modules/aws/iam/role). Defaults to true. | `bool` | `true` | no |
| <a name="input_create_task_role"></a> [create\_task\_role](#input\_create\_task\_role) | (Optional) Whether to create a separate ECS task role (via modules/aws/iam/role). Defaults to true for least-privilege separation from the execution role. | `bool` | `true` | no |
| <a name="input_ephemeral_storage_size_in_gib"></a> [ephemeral\_storage\_size\_in\_gib](#input\_ephemeral\_storage\_size\_in\_gib) | (Optional) The total amount, in GiB, of ephemeral storage to set for the task (21-200). When null, the provider default applies. | `number` | `null` | no |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | (Optional) ARN of an existing task execution role. Used when `create_execution_role = false`. | `string` | `null` | no |
| <a name="input_execution_role_managed_policy_arns"></a> [execution\_role\_managed\_policy\_arns](#input\_execution\_role\_managed\_policy\_arns) | (Optional) Managed policy ARNs to attach to the created execution role. Defaults to the AWS-managed AmazonECSTaskExecutionRolePolicy. | `list(string)` | <pre>[<br/>  "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"<br/>]</pre> | no |
| <a name="input_family"></a> [family](#input\_family) | (Required) A unique name for the task definition family. Also used as the `Name` tag value. | `string` | n/a | yes |
| <a name="input_ipc_mode"></a> [ipc\_mode](#input\_ipc\_mode) | (Optional) IPC resource namespace to be used for the containers in the task. Valid values are `host`, `task`, or `none`. | `string` | `null` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | (Optional) Amount (in MiB) of memory used by the task, as a string. Required for Fargate. | `string` | `null` | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | (Optional) Docker networking mode to use for the containers in the task. Defaults to `awsvpc` (required by Fargate). | `string` | `"awsvpc"` | no |
| <a name="input_pid_mode"></a> [pid\_mode](#input\_pid\_mode) | (Optional) Process namespace to use for the containers in the task. Valid values are `host` or `task`. | `string` | `null` | no |
| <a name="input_placement_constraints"></a> [placement\_constraints](#input\_placement\_constraints) | (Optional) Rules that are taken into consideration during task placement. Maximum of 10. | <pre>list(object({<br/>    type       = string<br/>    expression = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_proxy_configuration"></a> [proxy\_configuration](#input\_proxy\_configuration) | (Optional) Configuration block for the App Mesh proxy. | <pre>object({<br/>    type           = optional(string)<br/>    container_name = string<br/>    properties     = optional(map(string))<br/>  })</pre> | `null` | no |
| <a name="input_requires_compatibilities"></a> [requires\_compatibilities](#input\_requires\_compatibilities) | (Optional) Set of launch types required by the task. Defaults to `["FARGATE"]`. | `list(string)` | <pre>[<br/>  "FARGATE"<br/>]</pre> | no |
| <a name="input_runtime_platform"></a> [runtime\_platform](#input\_runtime\_platform) | (Optional) Configuration block for the runtime platform (`operating_system_family` and `cpu_architecture`). | <pre>object({<br/>    operating_system_family = optional(string)<br/>    cpu_architecture        = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_skip_destroy"></a> [skip\_destroy](#input\_skip\_destroy) | (Optional) Whether to retain the old revision when the resource is destroyed or task definition is updated. Defaults to false. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the task definition and the IAM resources created via composition. A `Name` tag is merged automatically. | `map(string)` | `{}` | no |
| <a name="input_task_role_arn"></a> [task\_role\_arn](#input\_task\_role\_arn) | (Optional) ARN of an existing task role. Used when `create_task_role = false`. | `string` | `null` | no |
| <a name="input_task_role_policy_json"></a> [task\_role\_policy\_json](#input\_task\_role\_policy\_json) | (Optional) JSON policy document for a least-privilege inline policy attached to the created task role (via modules/aws/iam/policy). | `string` | `null` | no |
| <a name="input_track_latest"></a> [track\_latest](#input\_track\_latest) | (Optional) Whether should track latest ACTIVE task definition on AWS or the one created with the resource stored in state. | `bool` | `null` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | (Optional) List of volume definitions for the task. Each entry has a `name` plus optional `host_path`, `configure_at_launch`, `docker_volume_configuration`, `efs_volume_configuration` (transit encryption ENABLED by default), and `fsx_windows_file_server_volume_configuration`. | <pre>list(object({<br/>    name                = string<br/>    host_path           = optional(string)<br/>    configure_at_launch = optional(bool)<br/>    docker_volume_configuration = optional(object({<br/>      scope         = optional(string)<br/>      autoprovision = optional(bool)<br/>      driver        = optional(string)<br/>      driver_opts   = optional(map(string))<br/>      labels        = optional(map(string))<br/>    }))<br/>    efs_volume_configuration = optional(object({<br/>      file_system_id          = string<br/>      root_directory          = optional(string)<br/>      transit_encryption      = optional(string, "ENABLED")<br/>      transit_encryption_port = optional(number)<br/>      authorization_config = optional(object({<br/>        access_point_id = optional(string)<br/>        iam             = optional(string)<br/>      }))<br/>    }))<br/>    fsx_windows_file_server_volume_configuration = optional(object({<br/>      file_system_id = string<br/>      root_directory = string<br/>      authorization_config = object({<br/>        credentials_parameter = string<br/>        domain                = string<br/>      })<br/>    }))<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The full ARN of the task definition (including revision). |
| <a name="output_arn_without_revision"></a> [arn\_without\_revision](#output\_arn\_without\_revision) | The ARN of the task definition without the revision number. |
| <a name="output_execution_role_arn"></a> [execution\_role\_arn](#output\_execution\_role\_arn) | The ARN of the task execution role (created or passed through). |
| <a name="output_family"></a> [family](#output\_family) | The family of the task definition. |
| <a name="output_revision"></a> [revision](#output\_revision) | The revision of the task definition. |
| <a name="output_task_role_arn"></a> [task\_role\_arn](#output\_task\_role\_arn) | The ARN of the task role (created or passed through). |
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
