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

<h3 align="center">AWS ECS (Integrated)</h3>
  <p align="center">
    Integrated root module that composes the ECS submodules to stand up a whole ECS stack from a single, declarative map / YAML input.
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

This is the integrated root module for the `modules/aws/ecs/` family. It
declares **no `aws_*` resources directly**; instead it composes the focused
submodules and wires their outputs together so dependency ordering and Service
Connect plumbing are automatic:

- `namespace` — Cloud Map HTTP namespace for Service Connect.
- `capacity_provider` — EC2 Auto Scaling-backed capacity providers.
- `cluster` — the ECS cluster + capacity provider associations.
- `task_definition` — task definitions (with least-privilege IAM roles).
- `service` — ECS services.

The whole stack is accepted as a map of objects (in-line HCL) **or** a YAML
document via `yamldecode(file(...))`. The module fans out task definitions and
services with `for_each`, resolves each service's `task_definition` map key to
the produced task-definition ARN, injects `cluster_arn` automatically, and wires
the resolved namespace ARN into the cluster (`service_connect_defaults`) and each
service (`service_connect_configuration`).

If you only need one building block, consume the relevant submodule directly
(for example `modules/aws/ecs/cluster`).

### Prerequisites

- A VPC and subnets for the services' `awsvpc` networking.
- Container images (for example an ECR repository via `modules/aws/ecr`) and
  caller-supplied `container_definitions` JSON for each task definition.
- For EC2 capacity providers, existing Auto Scaling group ARNs.
- For load balancing, target group ARNs from `modules/aws/alb` /
  `modules/aws/lb`.

<!-- USAGE EXAMPLES -->

## Usage

### Map-of-objects Example

```hcl
module "ecs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ecs"

  namespace = {
    name = "example-app"
  }

  cluster = {
    name = "example-app"
  }

  task_definitions = {
    web = {
      cpu    = "256"
      memory = "512"
      container_definitions = jsonencode([
        {
          name      = "web"
          image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/web:latest"
          essential = true
          portMappings = [
            { name = "http", containerPort = 8080, protocol = "tcp" }
          ]
        }
      ])
    }
  }

  services = {
    web = {
      task_definition    = "web"
      desired_count      = 2
      subnet_ids         = ["subnet-aaaa1111", "subnet-bbbb2222"]
      security_group_ids = ["sg-0123456789abcdef0"]
      capacity_provider_strategy = [
        { capacity_provider = "FARGATE", base = 1, weight = 100 }
      ]
    }
  }

  tags = {
    Team       = "platform"
    CostCenter = "12345"
  }
}
```

### YAML-driven Example

```hcl
locals {
  ecs = yamldecode(file("${path.module}/ecs.yaml"))
}

module "ecs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ecs"

  namespace        = local.ecs.namespace
  cluster          = local.ecs.cluster
  task_definitions = local.ecs.task_definitions
  services         = local.ecs.services

  tags = {
    Team = "platform"
  }
}
```

```yaml
# ecs.yaml
namespace:
  name: "example-app"
cluster:
  name: "example-app"
task_definitions:
  web:
    cpu: "256"
    memory: "512"
    container_definitions: '[{"name":"web","image":"123456789012.dkr.ecr.us-east-1.amazonaws.com/web:latest","essential":true,"portMappings":[{"name":"http","containerPort":8080,"protocol":"tcp"}]}]'
services:
  web:
    task_definition: "web"
    desired_count: 2
    subnet_ids:
      - "subnet-aaaa1111"
      - "subnet-bbbb2222"
    security_group_ids:
      - "sg-0123456789abcdef0"
    capacity_provider_strategy:
      - capacity_provider: "FARGATE"
        base: 1
        weight: 100
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

## Notes / Design Decisions

- This module composes the submodules only; it declares no `aws_*` resources, so
  all ordering is handled by inter-module references.
- The resolved namespace ARN (created via `namespace` or supplied via
  `existing_namespace_arn`) is wired into the cluster and every service
  automatically. Set a service's own `service_connect_configuration.namespace`
  to override.
- Created EC2 capacity-provider names are merged into the cluster's capacity
  provider list automatically.
- Secure, Well-Architected defaults are inherited from the submodules: Container
  Insights enabled, encrypted exec-command logging, deployment circuit breaker +
  rollback, `assign_public_ip = false`, and least-privilege separate
  task/execution roles.
- `namespace` and `existing_namespace_arn` are mutually exclusive — set at most
  one.

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

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_capacity_provider"></a> [capacity\_provider](#module\_capacity\_provider) | ./capacity_provider | n/a |
| <a name="module_cluster"></a> [cluster](#module\_cluster) | ./cluster | n/a |
| <a name="module_namespace"></a> [namespace](#module\_namespace) | ./namespace | n/a |
| <a name="module_service"></a> [service](#module\_service) | ./service | n/a |
| <a name="module_task_definition"></a> [task\_definition](#module\_task\_definition) | ./task_definition | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_capacity_providers"></a> [capacity\_providers](#input\_capacity\_providers) | (Optional) Map of EC2 capacity providers keyed by logical name (each mirrors the `capacity_provider` submodule). Created provider names are merged into the cluster's provider list. | `map(any)` | `{}` | no |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | (Required) Cluster configuration object. Mirrors the `cluster` submodule variables (`name`, `container_insights`, `capacity_providers`, `default_capacity_provider_strategy`, execute-command logging toggles, etc.). At minimum, `name` is required. | `any` | n/a | yes |
| <a name="input_existing_namespace_arn"></a> [existing\_namespace\_arn](#input\_existing\_namespace\_arn) | (Optional) Reference an existing Cloud Map namespace ARN instead of creating one. Mutually exclusive with `namespace`. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | (Optional) When set, creates a Cloud Map HTTP namespace (via the namespace submodule) whose ARN is wired into the cluster (service\_connect\_defaults) and every service (service\_connect\_configuration). Mutually exclusive with `existing_namespace_arn`. | <pre>object({<br/>    name        = string<br/>    description = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_services"></a> [services](#input\_services) | (Optional) Map of services keyed by logical name (each mirrors the `service` submodule) plus a `task_definition` field naming a `task_definitions` key. The root resolves that key to the produced task-definition ARN and injects `cluster_arn` automatically. | `map(any)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags merged into every child module's tags. | `map(string)` | `{}` | no |
| <a name="input_task_definitions"></a> [task\_definitions](#input\_task\_definitions) | (Optional) Map of task definitions keyed by logical name (each mirrors the `task_definition` submodule). The map key is what services reference via their `task_definition` field. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloud_watch_log_group_name"></a> [cloud\_watch\_log\_group\_name](#output\_cloud\_watch\_log\_group\_name) | The name of the exec-command CloudWatch log group created by the cluster submodule, when created. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The ARN that identifies the ECS cluster. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The ID (ARN) of the ECS cluster. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the ECS cluster. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the CMK created by the cluster submodule for exec-command logging, when created. |
| <a name="output_namespace_arn"></a> [namespace\_arn](#output\_namespace\_arn) | The effective Cloud Map namespace ARN (created or passed through). |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | The ID of the created Cloud Map namespace, when created. |
| <a name="output_service_ids"></a> [service\_ids](#output\_service\_ids) | Map of service ARNs keyed by the `services` map key. |
| <a name="output_service_names"></a> [service\_names](#output\_service\_names) | Map of service names keyed by the `services` map key. |
| <a name="output_task_definition_arns"></a> [task\_definition\_arns](#output\_task\_definition\_arns) | Map of task-definition ARNs keyed by the `task_definitions` map key. |
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
