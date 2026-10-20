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

A container-image function. Set `package_type = "Image"` and supply `image_uri` instead of
`filename`; `handler` and `runtime` are then ignored (the image defines them), so there is no
need to override their zip-oriented defaults:

```hcl
module "image_test" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/lambda"

  function_name = "image-test"
  role          = module.test_role.arn
  package_type  = "Image"
  image_uri     = "${module.test_ecr.repository_url}:v1.0.0"
  architectures = ["x86_64"]

  memory_size            = 2048
  timeout                = 300
  ephemeral_storage_size = 2048

  vpc_config = {
    subnet_ids         = ["subnet-0123456789abcdef0"]
    security_group_ids = ["sg-0123456789abcdef0"]
  }

  # Optional: override the image's CMD/ENTRYPOINT/WORKDIR.
  # image_config = {
  #   command = ["app.handler"]
  # }
}
```

All inputs above except `function_name`, `role`, and (for zip functions) `handler` are
genuinely optional -- `description`, `filename`, `source_code_hash`, `image_uri`, `package_type`,
`architectures`, `ephemeral_storage_size`, and `image_config` default to `null` (the provider's
own default applies), and `tags`, `vpc_config`, `reserved_concurrent_executions`,
`dead_letter_config`, and `tracing_config` all default to a no-op value that reproduces the
provider's own defaults.

### Prerequisites

- An IAM execution role for the function (`role`). For a function attached to a VPC, it needs ENI
  permissions equivalent to the `AWSLambdaVPCAccessExecutionRole` managed policy.
- For container images: an ECR repository (see `modules/aws/ecr`) that already contains the image
  referenced by `image_uri`, built for the architecture selected in `architectures`. The image
  must exist before `apply`, or the function creation fails.

### Notes / design decisions

- **Zip behavior is unchanged.** With `package_type` left `null`, the module behaves exactly as
  before: `handler` and `runtime` pass through and `filename` is the package source.
- **Image functions null out `handler` and `runtime`.** The provider rejects both for
  `package_type = "Image"`, and their defaults (`main.handler`, `python3.6`) are non-null, so the
  module forces them to `null` for image functions instead of making callers do it.
- **Cross-variable rules are resource preconditions.** `image_uri` is required for `Image`, `image_uri`
  is not allowed otherwise, and `filename` cannot be set for `Image`. They are `lifecycle`
  preconditions (rather than variable validations) so the module keeps working on
  OpenTofu/Terraform 1.3+, since a variable validation referencing another variable needs 1.9+.
- **Image tags and updates.** Terraform only redeploys when `image_uri` changes. If the ECR
  repository has immutable tags (the `modules/aws/ecr` default), pass a new tag (for example a git
  SHA) on each release. A mutable tag such as `latest` will not trigger an update.
- **Not covered by this module:** S3-based deployment packages (`s3_bucket`, `s3_key`, ...), layers,
  KMS-encrypted environment variables, and function URLs. Use `filename` or `image_uri`.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.69.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lambda_function.lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_architectures"></a> [architectures](#input\_architectures) | (Optional) Instruction set architecture for the function. Exactly one of `x86_64` or `arm64`. When omitted (null), the provider default (`x86_64`) is used. A container image must be built for the architecture selected here. | `list(string)` | `null` | no |
| <a name="input_dead_letter_config"></a> [dead\_letter\_config](#input\_dead\_letter\_config) | (Optional) Dead-letter queue configuration. `target_arn` must be an SQS queue or SNS topic ARN, and the function's execution role must be granted `sqs:SendMessage` / `sns:Publish` on it (not managed by this module). | <pre>object({<br/>    target_arn = string<br/>  })</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional) Description of what your Lambda Function does. When omitted (null), the provider does not set a description on the function. | `string` | `null` | no |
| <a name="input_ephemeral_storage_size"></a> [ephemeral\_storage\_size](#input\_ephemeral\_storage\_size) | (Optional) Size in MB of the function's /tmp directory, from 512 to 10240. When omitted (null), the provider default (512 MB) is used. | `number` | `null` | no |
| <a name="input_filename"></a> [filename](#input\_filename) | (Optional) The path to the function's deployment package within the local filesystem. If defined, The s3\_-prefixed options cannot be used. Required for zip functions (the default `package_type`); must be null when `package_type` is "Image" (use `image_uri` instead). | `string` | `null` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | (Required) A unique name for your Lambda Function. | `string` | n/a | yes |
| <a name="input_handler"></a> [handler](#input\_handler) | (Required for zip functions) The function entrypoint in your code. Ignored when `package_type` is "Image". | `string` | `"main.handler"` | no |
| <a name="input_image_config"></a> [image\_config](#input\_image\_config) | (Optional) Overrides for a container image's CMD (`command`), ENTRYPOINT (`entry_point`) and WORKDIR (`working_directory`). Only meaningful when `package_type` is "Image". When omitted (null), the image's own settings are used. | <pre>object({<br/>    command           = optional(list(string))<br/>    entry_point       = optional(list(string))<br/>    working_directory = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | (Optional) ECR image URI containing the function's deployment package, including a tag or digest (for example `123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:v1.0.0`). Required when `package_type` is "Image" and not allowed otherwise. Exactly one of `filename` or `image_uri` must be supplied. | `string` | `null` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | (Optional) Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128. See Limits | `string` | `128` | no |
| <a name="input_package_type"></a> [package\_type](#input\_package\_type) | (Optional) Lambda deployment package type: "Zip" or "Image". When omitted (null), the provider default ("Zip") is used. Set to "Image" to deploy a container image from `image_uri`; `handler` and `runtime` are then ignored because the image defines them. | `string` | `null` | no |
| <a name="input_reserved_concurrent_executions"></a> [reserved\_concurrent\_executions](#input\_reserved\_concurrent\_executions) | (Optional) Amount of reserved concurrent executions for this function. `0` disables the function (throttles all invocations); omit (or `null`) to leave the function unreserved, which is the provider's own default. | `number` | `null` | no |
| <a name="input_role"></a> [role](#input\_role) | (Required) IAM role attached to the Lambda Function. This governs both who or what can invoke your Lambda Function, as well as what resources our Lambda Function has access to. See Lambda Permission Model for more details. | `string` | n/a | yes |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | (Required for zip functions) See Runtimes for valid values. Ignored when `package_type` is "Image". | `string` | `"python3.6"` | no |
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
