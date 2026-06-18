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

<h3 align="center">ECS Capacity Provider</h3>
  <p align="center">
    Manages an EC2 Auto Scaling-backed ECS capacity provider (aws_ecs_capacity_provider).
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

This module manages an EC2 Auto Scaling-backed ECS capacity provider
(`aws_ecs_capacity_provider`). It associates an existing EC2 Auto Scaling group
with ECS and enables managed scaling, managed draining, and managed termination
protection by default.

Fargate and Fargate Spot capacity providers are referenced by name directly in
the cluster (`modules/aws/ecs/cluster`) and require no resource of their own —
use this module only for EC2 Auto Scaling-backed capacity.

### Prerequisites

- An existing EC2 Auto Scaling group (its ARN is supplied via
  `auto_scaling_group_arn`). This module does not create or manage the Auto
  Scaling group.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "ecs_capacity_provider" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ecs/capacity_provider"

  name                   = "ec2-general"
  auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

  managed_scaling = {
    status          = "ENABLED"
    target_capacity = 100
  }

  tags = {
    Team       = "platform"
    CostCenter = "12345"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

## Notes / Design Decisions

- EC2-only by design. Fargate / Fargate Spot need no capacity-provider resource;
  reference them by name in the cluster module.
- Secure defaults. Managed draining and managed termination protection are
  enabled by default, and managed scaling targets 100% capacity utilization.
- Single resource per block. Scale to multiple providers by calling this module
  with `for_each`.

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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecs_capacity_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_scaling_group_arn"></a> [auto\_scaling\_group\_arn](#input\_auto\_scaling\_group\_arn) | (Required) The ARN of the existing EC2 Auto Scaling group to back the capacity provider. | `string` | n/a | yes |
| <a name="input_managed_draining"></a> [managed\_draining](#input\_managed\_draining) | (Optional) Enables or disables a graceful shutdown of instances without disturbing workloads. Valid values are ENABLED and DISABLED. | `string` | `"ENABLED"` | no |
| <a name="input_managed_scaling"></a> [managed\_scaling](#input\_managed\_scaling) | (Optional) Configuration block defining the parameters of the Auto Scaling group capacity provider's managed scaling. | <pre>object({<br/>    status                    = optional(string, "ENABLED")<br/>    target_capacity           = optional(number, 100)<br/>    minimum_scaling_step_size = optional(number)<br/>    maximum_scaling_step_size = optional(number)<br/>    instance_warmup_period    = optional(number)<br/>  })</pre> | `{}` | no |
| <a name="input_managed_termination_protection"></a> [managed\_termination\_protection](#input\_managed\_termination\_protection) | (Optional) Enables or disables container-aware termination of instances in the Auto Scaling group when scale-in happens. Valid values are ENABLED and DISABLED. | `string` | `"ENABLED"` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the capacity provider. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the capacity provider. A `Name` tag is merged automatically. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN that identifies the capacity provider. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the capacity provider. |
| <a name="output_name"></a> [name](#output\_name) | The name of the capacity provider. |
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
