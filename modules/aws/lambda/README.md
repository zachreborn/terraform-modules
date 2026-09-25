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

<h3 align="center">Lambda Module</h3>
  <p align="center">
    This module configures a Lambda function.
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

```hcl
module "test" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/lambda"

  description       = "Test function"
  filename          = "./lambda_functions/test_v1.1.0.zip"
  source_code_hash  = filebase64sha256("./lambda_functions/test_v1.1.0.zip")
  function_name     = "test"
  role              = module.test_role.arn
  handler           = "lambda_test.lambda_handler"
  timeout           = 60

  variables = {
    regions = var.aws_prod_region
  }

  tags = {
    Team = "platform"
  }
}
```

A second example, attaching the function to a VPC and enabling a dead-letter queue,
X-Ray tracing, and a reserved concurrency limit. The execution role must additionally be
granted ENI permissions equivalent to the `AWSLambdaVPCAccessExecutionRole` managed policy
(e.g. via `modules/aws/iam/role`) for the function to run inside a VPC -- this module does
not manage that policy attachment:

```hcl
module "vpc_test" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/lambda"

  filename          = "./lambda_functions/test_v1.1.0.zip"
  source_code_hash  = filebase64sha256("./lambda_functions/test_v1.1.0.zip")
  function_name     = "vpc-test"
  role              = module.test_role.arn
  handler           = "lambda_test.lambda_handler"

  vpc_config = {
    subnet_ids          = ["subnet-0123456789abcdef0"]
    security_group_ids = ["sg-0123456789abcdef0"]
  }

  dead_letter_config = {
    target_arn = "arn:aws:sqs:us-east-1:123456789012:vpc-test-dlq"
  }

  tracing_config = {
    mode = "Active"
  }

  reserved_concurrent_executions = 5
}
```

All inputs above except `function_name`, `role`, and `handler` are genuinely optional --
`description`, `filename`, and `source_code_hash` now default to `null`, and `tags`,
`vpc_config`, `reserved_concurrent_executions`, `dead_letter_config`, and `tracing_config`
all default to a no-op value that reproduces the provider's own defaults.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lambda_function.lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_dead_letter_config"></a> [dead\_letter\_config](#input\_dead\_letter\_config) | (Optional) Dead-letter queue configuration. `target_arn` must be an SQS queue or SNS topic ARN, and the function's execution role must be granted `sqs:SendMessage` / `sns:Publish` on it (not managed by this module). | <pre>object({<br/>    target_arn = string<br/>  })</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional) Description of what your Lambda Function does. When omitted (null), the provider does not set a description on the function. | `string` | `null` | no |
| <a name="input_filename"></a> [filename](#input\_filename) | (Optional) The path to the function's deployment package within the local filesystem. If defined, The s3\_-prefixed options cannot be used. When omitted (null), a function created without a local package source requires an alternative source (e.g. S3 or a container image) configured outside this module today. | `string` | `null` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | (Required) A unique name for your Lambda Function. | `string` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | (Required) The function entrypoint in your code. | `string` | `"main.handler"` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | (Optional) Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128. See Limits | `string` | `128` | no |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | (Optional) Amount of reserved concurrent executions for this function. `0` disables the function (throttles all invocations); omit (or `null`) to leave the function unreserved, which is the provider's own default. | `number` | `null` | no |
| <a name="input_role"></a> [role](#input\_role) | (Required) IAM role attached to the Lambda Function. This governs both who or what can invoke your Lambda Function, as well as what resources our Lambda Function has access to. See Lambda Permission Model for more details. | `string` | n/a | yes |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | (Required) See Runtimes for valid values. | `string` | `"python3.6"` | no |
| <a name="input_source_code_hash"></a> [source\_code\_hash](#input\_source\_code\_hash) | (Optional) Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3\_key | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the Lambda function. A `Name` tag is merged automatically from `function_name`; a caller-supplied `Name` wins. | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | (Optional) The amount of time your Lambda Function has to run in seconds. Defaults to 180. See Limits | `number` | `180` | no |
| <a name="input_tracing_config"></a> [tracing\_config](#input\_tracing\_config) | (Optional) AWS X-Ray tracing mode. | <pre>object({<br/>    mode = string<br/>  })</pre> | `null` | no |
| <a name="input_variables"></a> [variables](#input\_variables) | (Optional) A map that defines environment variables for the Lambda function. | `map(string)` | <pre>{<br/>  "lambda": "true"<br/>}</pre> | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | (Optional) VPC configuration attaching the function to a VPC. When omitted, the function runs outside any VPC. `ipv6_allowed_for_dual_stack` left unset defers to the provider's own default. | <pre>object({<br/>    subnet_ids                  = list(string)<br/>    security_group_ids          = list(string)<br/>    ipv6_allowed_for_dual_stack = optional(bool)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) identifying the Lambda function. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | The unique name of the Lambda function. |
| <a name="output_invoke_arn"></a> [invoke\_arn](#output\_invoke\_arn) | ARN to be used for invoking the Lambda function from API Gateway, e.g. in aws\_api\_gateway\_integration's uri or aws\_lambda\_permission. |
| <a name="output_last_modified"></a> [last\_modified](#output\_last\_modified) | The date this resource was last modified. |
| <a name="output_qualified_arn"></a> [qualified\_arn](#output\_qualified\_arn) | The ARN identifying the function's published version. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | Map of tags assigned to the resource, including those inherited from the provider default\_tags configuration block. |
| <a name="output_version"></a> [version](#output\_version) | Latest published version of the Lambda function. |
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
