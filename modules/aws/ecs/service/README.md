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

<h3 align="center">ECS Service</h3>
  <p align="center">
    Manages an AWS ECS service (aws_ecs_service) with deployment circuit breaker, rollback, and a secure network posture by default.
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

This module manages an AWS ECS service (`aws_ecs_service`). The deployment
circuit breaker and automatic rollback are enabled by default, `assign_public_ip`
defaults to `false`, and an optional service security group can be created via
composition with `modules/aws/security_group`.

Load balancer target groups are supplied by the caller from the existing
`modules/aws/alb` / `modules/aws/lb` modules; this module does not manage load
balancers or target groups.

### Prerequisites

- An ECS cluster ARN (see `modules/aws/ecs/cluster`).
- A task definition ARN (see `modules/aws/ecs/task_definition`).
- Subnets for `awsvpc` networking, and either existing security group IDs or a
  `vpc_id` when `create_security_group = true`.
- For Service Connect, a Cloud Map namespace ARN (see
  `modules/aws/ecs/namespace`).
- For load balancing, target group ARNs from `modules/aws/alb` /
  `modules/aws/lb`.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "ecs_service" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ecs/service"

  name                = "example-app"
  cluster_arn         = module.ecs_cluster.arn
  task_definition_arn = module.ecs_task_definition.arn
  desired_count       = 2

  subnet_ids         = ["subnet-aaaa1111", "subnet-bbbb2222"]
  security_group_ids = ["sg-0123456789abcdef0"]
  assign_public_ip   = false

  capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      base              = 1
      weight            = 100
    }
  ]

  service_connect_configuration = {
    enabled   = true
    namespace = module.ecs_namespace.arn
  }

  tags = {
    Team       = "platform"
    CostCenter = "12345"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

## Notes / Design Decisions

- Deployment circuit breaker and rollback are enabled by default for safer
  deployments.
- `assign_public_ip` defaults to `false` for a secure network posture.
- Security group creation is opt-in (`create_security_group = false` by
  default); when enabled, the group is created via
  `modules/aws/security_group`. That module manages only the group itself, so
  `security_group_rules` is reserved — manage rules on the caller side.
- `ignore_desired_count` toggles a `lifecycle { ignore_changes = [desired_count] }`
  via a second, otherwise-identical resource so external autoscaling
  (Application Auto Scaling) does not conflict with Terraform.
- Single resource per block. Scale to multiple services by calling this module
  with `for_each`, or use the integrated `modules/aws/ecs` root module.

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
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | ../../security_group | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_service.ignore_desired_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | (Optional) Whether the task's elastic network interface receives a public IP address. Defaults to false for a secure posture. | `bool` | `false` | no |
| <a name="input_availability_zone_rebalancing"></a> [availability\_zone\_rebalancing](#input\_availability\_zone\_rebalancing) | (Optional) Whether to use Availability Zone rebalancing. Valid values are `ENABLED` and `DISABLED`. | `string` | `null` | no |
| <a name="input_capacity_provider_strategy"></a> [capacity\_provider\_strategy](#input\_capacity\_provider\_strategy) | (Optional) Capacity provider strategy to use for the service. Mutually exclusive with `launch_type`. | <pre>list(object({<br/>    capacity_provider = string<br/>    base              = optional(number)<br/>    weight            = optional(number)<br/>  }))</pre> | `[]` | no |
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | (Required) ARN of the ECS cluster on which to run the service. | `string` | n/a | yes |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | (Optional) Whether to create a service security group via modules/aws/security\_group. Defaults to false (callers pass `security_group_ids`). | `bool` | `false` | no |
| <a name="input_deployment_alarms"></a> [deployment\_alarms](#input\_deployment\_alarms) | (Optional) CloudWatch alarms used to determine deployment failure and trigger rollback. | <pre>object({<br/>    alarm_names = list(string)<br/>    enable      = bool<br/>    rollback    = bool<br/>  })</pre> | `null` | no |
| <a name="input_deployment_circuit_breaker_rollback"></a> [deployment\_circuit\_breaker\_rollback](#input\_deployment\_circuit\_breaker\_rollback) | (Optional) Whether to enable automatic rollback on deployment failure when the circuit breaker is enabled. Defaults to true. | `bool` | `true` | no |
| <a name="input_deployment_controller_type"></a> [deployment\_controller\_type](#input\_deployment\_controller\_type) | (Optional) Type of deployment controller. Valid values are `ECS`, `CODE_DEPLOY`, and `EXTERNAL`. Defaults to `ECS`. | `string` | `"ECS"` | no |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | (Optional) Upper limit (as a percentage of desired\_count) of running tasks during a deployment. Defaults to 200. | `number` | `200` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | (Optional) Lower limit (as a percentage of desired\_count) of running tasks that must remain healthy during a deployment. Defaults to 100. | `number` | `100` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | (Optional) Number of instances of the task definition to place and keep running. Defaults to 2 for availability. | `number` | `2` | no |
| <a name="input_enable_deployment_circuit_breaker"></a> [enable\_deployment\_circuit\_breaker](#input\_enable\_deployment\_circuit\_breaker) | (Optional) Whether to enable the ECS deployment circuit breaker. Defaults to true. | `bool` | `true` | no |
| <a name="input_enable_ecs_managed_tags"></a> [enable\_ecs\_managed\_tags](#input\_enable\_ecs\_managed\_tags) | (Optional) Whether to enable Amazon ECS managed tags for the tasks within the service. Defaults to true. | `bool` | `true` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | (Optional) Whether to enable the ECS Exec (execute command) functionality for the service. Defaults to false. | `bool` | `false` | no |
| <a name="input_force_delete"></a> [force\_delete](#input\_force\_delete) | (Optional) Whether to allow Terraform to delete the service even if it was not scaled down to zero tasks. | `bool` | `null` | no |
| <a name="input_force_new_deployment"></a> [force\_new\_deployment](#input\_force\_new\_deployment) | (Optional) Whether to force a new task deployment of the service. Defaults to false. | `bool` | `false` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | (Optional) Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown. | `number` | `null` | no |
| <a name="input_ignore_desired_count"></a> [ignore\_desired\_count](#input\_ignore\_desired\_count) | (Optional) When true, a lifecycle ignore\_changes on `desired_count` is applied so external autoscaling does not fight Terraform. Defaults to false. | `bool` | `false` | no |
| <a name="input_launch_type"></a> [launch\_type](#input\_launch\_type) | (Optional) Launch type on which to run the service. Mutually exclusive with `capacity_provider_strategy`. | `string` | `null` | no |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | (Optional) Load balancer configuration blocks. Supply target group ARNs from the existing modules/aws/alb or modules/aws/lb modules. | <pre>list(object({<br/>    target_group_arn = optional(string)<br/>    elb_name         = optional(string)<br/>    container_name   = string<br/>    container_port   = number<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the ECS service and the value of its `Name` tag. | `string` | n/a | yes |
| <a name="input_ordered_placement_strategy"></a> [ordered\_placement\_strategy](#input\_ordered\_placement\_strategy) | (Optional) Service-level strategy rules taken into consideration during task placement. Maximum of 5. | <pre>list(object({<br/>    type  = string<br/>    field = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_placement_constraints"></a> [placement\_constraints](#input\_placement\_constraints) | (Optional) Rules taken into consideration during task placement. Maximum of 10. | <pre>list(object({<br/>    type       = string<br/>    expression = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_platform_version"></a> [platform\_version](#input\_platform\_version) | (Optional) Platform version on which to run the service. Only applicable to Fargate. | `string` | `null` | no |
| <a name="input_propagate_tags"></a> [propagate\_tags](#input\_propagate\_tags) | (Optional) Whether to propagate the tags from the task definition or the service to the tasks. Valid values are `SERVICE`, `TASK_DEFINITION`, and `NONE`. Defaults to `SERVICE`. | `string` | `"SERVICE"` | no |
| <a name="input_scheduling_strategy"></a> [scheduling\_strategy](#input\_scheduling\_strategy) | (Optional) Scheduling strategy to use for the service. Valid values are `REPLICA` and `DAEMON`. Defaults to `REPLICA`. | `string` | `"REPLICA"` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | (Optional) Security groups associated with the task or service. If `create_security_group` is true, the created group's ID is appended to this list. | `list(string)` | `[]` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | (Optional) Reserved for future rule management. The composed modules/aws/security\_group module currently manages only the security group itself; manage rules on the caller side or via dedicated security group rule resources. | `any` | `{}` | no |
| <a name="input_service_connect_configuration"></a> [service\_connect\_configuration](#input\_service\_connect\_configuration) | (Optional) ECS Service Connect configuration. `namespace` is the Cloud Map namespace ARN (see modules/aws/ecs/namespace). | <pre>object({<br/>    enabled   = optional(bool, true)<br/>    namespace = optional(string)<br/>    log_configuration = optional(object({<br/>      log_driver = string<br/>      options    = optional(map(string))<br/>      secret_option = optional(list(object({<br/>        name       = string<br/>        value_from = string<br/>      })), [])<br/>    }))<br/>    service = optional(list(object({<br/>      port_name             = string<br/>      discovery_name        = optional(string)<br/>      ingress_port_override = optional(number)<br/>      client_alias = optional(object({<br/>        port     = number<br/>        dns_name = optional(string)<br/>      }))<br/>      timeout = optional(object({<br/>        idle_timeout_seconds        = optional(number)<br/>        per_request_timeout_seconds = optional(number)<br/>      }))<br/>      tls = optional(object({<br/>        kms_key  = optional(string)<br/>        role_arn = optional(string)<br/>        issuer_cert_authority = object({<br/>          aws_pca_authority_arn = string<br/>        })<br/>      }))<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_service_registries"></a> [service\_registries](#input\_service\_registries) | (Optional) Service discovery registries for the service (service\_registries block). | <pre>object({<br/>    registry_arn   = string<br/>    port           = optional(number)<br/>    container_name = optional(string)<br/>    container_port = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | (Required) Subnets associated with the task or service (network\_configuration.subnets). | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the service and the security group created via composition. A `Name` tag is merged automatically. | `map(string)` | `{}` | no |
| <a name="input_task_definition_arn"></a> [task\_definition\_arn](#input\_task\_definition\_arn) | (Required) The family and revision (family:revision) or full ARN of the task definition to run. | `string` | n/a | yes |
| <a name="input_triggers"></a> [triggers](#input\_triggers) | (Optional) Map of arbitrary keys and values that, when changed, will trigger an in-place update (forced new deployment). | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | (Optional) VPC ID used when `create_security_group = true`. | `string` | `null` | no |
| <a name="input_wait_for_steady_state"></a> [wait\_for\_steady\_state](#input\_wait\_for\_steady\_state) | (Optional) Whether Terraform should wait for the service to reach a steady state before continuing. Defaults to false. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster"></a> [cluster](#output\_cluster) | The ARN of the cluster the service runs on. |
| <a name="output_desired_count"></a> [desired\_count](#output\_desired\_count) | The number of instances of the task definition the service maintains. |
| <a name="output_id"></a> [id](#output\_id) | The ARN that identifies the ECS service. |
| <a name="output_name"></a> [name](#output\_name) | The name of the ECS service. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The ID of the service security group, when created via composition. |
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
