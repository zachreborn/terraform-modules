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

<h3 align="center">CloudWatch Log Destination</h3>
  <p align="center">
    Manages a cross-account CloudWatch Logs destination and its optional access policy.
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

This module manages an `aws_cloudwatch_log_destination` (a cross-account CloudWatch Logs subscription target) and, optionally, its companion `aws_cloudwatch_log_destination_policy`. It is a focused leaf module: the IAM role that grants CloudWatch Logs permission to write to the target, and the delivery target itself (e.g. a Kinesis stream or Firehose delivery stream), are cross-cutting resources that must be provisioned by the caller and wired in via the `destination_role_arn` and `destination_target_arn` variables (see `AGENTS.md` § 2, Module Composition).

### Prerequisites

- An IAM role that CloudWatch Logs can assume to write to the target (provision via `modules/aws/iam/role`), passed in as `destination_role_arn`.
- A delivery target (e.g. a Kinesis Firehose delivery stream), passed in as `destination_target_arn`.

### Example

```hcl
module "log_destination" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloudwatch/log_destination"

  destination_name       = "central-logging"
  destination_role_arn   = module.cloudwatch_to_firehose_role.arn
  destination_target_arn = aws_kinesis_firehose_delivery_stream.this.arn

  # Optional: attach a cross-account access policy so other accounts can
  # create subscription filters that target this destination.
  destination_policy_access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCrossAccountSubscription"
      Effect    = "Allow"
      Principal = { AWS = "111122223333" }
      Action    = "logs:PutSubscriptionFilter"
      Resource  = "arn:aws:logs:us-east-1:123456789012:destination:central-logging"
    }]
  })

  tags = {
    Team       = "platform"
    CostCenter = "12345"
  }
}
```

### Notes / design decisions

- The `aws_cloudwatch_log_destination_policy` resource is created only when `destination_policy_access_policy` is non-null, so single-account uses that do not need a cross-account policy remain valid.
- `destination_policy_access_policy` is validated to be parseable JSON when set.
- Per `AGENTS.md` § 2, this module does not declare the IAM role, IAM policy, or S3/delivery resources inline; the caller owns those cross-cutting concerns.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_destination.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination) | resource |
| [aws_cloudwatch_log_destination_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_destination_name"></a> [destination\_name](#input\_destination\_name) | (Required) A name for the log destination. | `string` | n/a | yes |
| <a name="input_destination_policy_access_policy"></a> [destination\_policy\_access\_policy](#input\_destination\_policy\_access\_policy) | (Optional) The cross-account access policy document (JSON) attached to the log destination via aws\_cloudwatch\_log\_destination\_policy. When null, no destination policy resource is created. | `string` | `null` | no |
| <a name="input_destination_policy_force_update"></a> [destination\_policy\_force\_update](#input\_destination\_policy\_force\_update) | (Optional) Whether to update the access policy on the log destination even if the destination is currently in use. Maps to the force\_update argument of aws\_cloudwatch\_log\_destination\_policy. | `bool` | `null` | no |
| <a name="input_destination_role_arn"></a> [destination\_role\_arn](#input\_destination\_role\_arn) | (Required) The ARN of an IAM role that grants CloudWatch Logs permission to write to the target ARN (destination\_target\_arn). Supplied by the caller (e.g. from the modules/aws/iam/role module). | `string` | n/a | yes |
| <a name="input_destination_target_arn"></a> [destination\_target\_arn](#input\_destination\_target\_arn) | (Required) The ARN of the target Amazon resource (e.g. a Kinesis stream or Kinesis Firehose delivery stream) that the log destination delivers matching log events to. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the log destination. A Name tag is merged in automatically from destination\_name. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_policy"></a> [access\_policy](#output\_access\_policy) | The effective cross-account access policy attached to the log destination, or null when no destination policy is created. |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the CloudWatch log destination. Used by other accounts as the destination\_arn of a subscription filter. |
| <a name="output_id"></a> [id](#output\_id) | The ID (name) of the CloudWatch log destination. |
| <a name="output_name"></a> [name](#output\_name) | The name of the CloudWatch log destination. |
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
