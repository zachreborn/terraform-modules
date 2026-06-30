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

<h3 align="center">AWS Config Organization</h3>
  <p align="center">
    This module enables AWS Config at the organization level by registering a delegated administrator, creating a configuration recorder, delivery channel (with optional S3 bucket), and optional organization conformance packs. Scope is read/reporting only — no enforcement rules are deployed.
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

## Prerequisites

The following must exist before deploying this module:

- **AWS Organizations** — the organization must already be set up and the management account must have permissions to register delegated administrators.
- **Delegated administrator account** — the account specified by `admin_account_id` must already be a member of the organization.
- **IAM role for Config recorder** — an IAM role with the `AWSConfigRole` managed policy (or equivalent) must be pre-created in the Config account and passed as `recorder_role_arn`. The AWS-managed service-linked role `AWSServiceRoleForConfig` is the standard choice.
- **Dual provider aliases** — the caller must configure two `aws` provider aliases: `aws.organization_management_account` (management account credentials) and `aws.organization_config_account` (the delegated Config account credentials) and pass them via the `providers` block.
- **S3 logging bucket** (optional) — if `enable_s3_bucket_logging = true`, a target logging bucket must exist before applying.

## Usage

### Organization Config with New S3 Bucket

This example delegates AWS Config administration to a security account and creates a new delivery bucket.

```hcl
provider "aws" {
  alias  = "organization_management_account"
  region = "us-east-1"
  # assume_role { role_arn = "arn:aws:iam::MANAGEMENT_ACCOUNT_ID:role/OrganizationRole" }
}

provider "aws" {
  alias  = "organization_config_account"
  region = "us-east-1"
  # assume_role { role_arn = "arn:aws:iam::SECURITY_ACCOUNT_ID:role/ConfigAdminRole" }
}
```

```hcl
module "config_organization" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/config/organization"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_config_account     = aws.organization_config_account
  }

  name             = "org-config"
  admin_account_id = "123456789012"
  recorder_role_arn = "arn:aws:iam::123456789012:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  create_s3_bucket   = true
  s3_bucket_prefix   = "config-"
  s3_key_prefix      = "org-config"
  delivery_frequency = "TwentyFour_Hours"

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

### Organization Config with Existing S3 Bucket

```hcl
module "config_organization" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/config/organization"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_config_account     = aws.organization_config_account
  }

  name              = "org-config"
  admin_account_id  = "123456789012"
  recorder_role_arn = "arn:aws:iam::123456789012:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  create_s3_bucket = false
  s3_bucket_name   = "my-existing-config-bucket"
  s3_key_prefix    = "config"

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

### Organization Config with Conformance Packs and Input Parameters

```hcl
module "config_organization" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/config/organization"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_config_account     = aws.organization_config_account
  }

  name              = "org-config"
  admin_account_id  = "123456789012"
  recorder_role_arn = "arn:aws:iam::123456789012:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  create_s3_bucket         = true
  s3_bucket_prefix         = "config-"
  enable_conformance_packs = true

  conformance_packs = [
    {
      name            = "operational-best-practices-for-cis-aws"
      template_s3_uri = "s3://my-templates-bucket/cis-conformance-pack.yaml"
      excluded_accounts = ["111111111111"]  # exclude a sandbox account
      input_parameters = [
        { parameter_name = "AccessKeysRotatedParamMaxAccessKeyAge", parameter_value = "90" }
      ]
    }
  ]

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

### Exclusion-Based Recording

```hcl
module "config_organization" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/config/organization"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_config_account     = aws.organization_config_account
  }

  name              = "org-config"
  admin_account_id  = "123456789012"
  recorder_role_arn = "arn:aws:iam::123456789012:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  all_supported        = true
  recording_strategy   = "EXCLUSION_BY_RESOURCE_TYPES"
  exclusion_resource_types = [
    "AWS::CloudFormation::Stack",
  ]

  create_s3_bucket = true
}
```

## Notes / Design Decisions

- **Dual-provider pattern** — registering a delegated administrator must be done from the management account, while the recorder, delivery channel, and bucket all live in the delegated (Config) account. Two provider aliases are required and cannot be collapsed.
- **Read/reporting scope only** — this module deploys the recorder and conformance packs but does not create Config Rules or remediation actions. Enforcement is left to callers to avoid overly prescriptive defaults at the org level.
- **S3 bucket policy is inline, not in the child module** — the Config delivery policy (`GetBucketAcl`, `ListBucket`, `PutObject` for `config.amazonaws.com`) depends on the bucket ARN. Passing the policy into the `s3/bucket` child module would create a Terraform cycle (policy document → bucket ARN → module input → module), so the policy and `aws_s3_bucket_policy` resource remain inline in this module. The `DenyInsecureTransport` statement is merged into the same policy document so it is not managed separately.
- **KMS encryption** — the delivery bucket uses SSE-KMS with the AWS-managed key by default. To use a customer-managed key for Config _deliveries_, pass `s3_kms_key_arn` (the delivery channel attribute). The bucket itself always uses `sse_algorithm = "aws:kms"`; `enable_kms_key = false` in the child module means the AWS-managed S3 key is used for bucket-level encryption.
- **Recording mode** — `recording_frequency` defaults to `CONTINUOUS`. For high-velocity resource types, consider switching to `DAILY` to reduce costs.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.46.0 |
| <a name="provider_aws.organization_config_account"></a> [aws.organization\_config\_account](#provider\_aws.organization\_config\_account) | 6.46.0 |
| <a name="provider_aws.organization_management_account"></a> [aws.organization\_management\_account](#provider\_aws.organization\_management\_account) | 6.46.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_config_bucket"></a> [config\_bucket](#module\_config\_bucket) | ../../s3/bucket | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_config_configuration_recorder.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_config_organization_conformance_pack.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_conformance_pack) | resource |
| [aws_organizations_delegated_administrator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_iam_policy_document.config_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_account_id"></a> [admin\_account\_id](#input\_admin\_account\_id) | (Required) The AWS account ID to register as the delegated administrator for AWS Config in the organization. | `string` | n/a | yes |
| <a name="input_all_supported"></a> [all\_supported](#input\_all\_supported) | (Optional) Specifies whether AWS Config records configuration changes for every supported type of regional resource. Defaults to true. Set to false when using resource\_types for inclusion-based recording. | `bool` | `true` | no |
| <a name="input_conformance_pack_delivery_s3_bucket"></a> [conformance\_pack\_delivery\_s3\_bucket](#input\_conformance\_pack\_delivery\_s3\_bucket) | (Optional) The name of the S3 bucket where AWS Config stores conformance pack templates and results. Set to null to use the main delivery bucket. | `string` | `null` | no |
| <a name="input_conformance_pack_delivery_s3_key_prefix"></a> [conformance\_pack\_delivery\_s3\_key\_prefix](#input\_conformance\_pack\_delivery\_s3\_key\_prefix) | (Optional) The prefix for the S3 key where conformance pack templates and results are stored. Defaults to null. | `string` | `null` | no |
| <a name="input_conformance_packs"></a> [conformance\_packs](#input\_conformance\_packs) | (Optional) List of organization conformance packs to deploy. Each object requires a name and either template\_s3\_uri or template\_body. Optionally supply excluded\_accounts (list of account IDs to exclude) and input\_parameters (list of name/value pairs to pass to the template). Only used when enable\_conformance\_packs is true. | <pre>list(object({<br/>    name              = string<br/>    template_s3_uri   = optional(string)<br/>    template_body     = optional(string)<br/>    excluded_accounts = optional(list(string), [])<br/>    input_parameters = optional(list(object({<br/>      parameter_name  = string<br/>      parameter_value = string<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_create_s3_bucket"></a> [create\_s3\_bucket](#input\_create\_s3\_bucket) | (Optional) If true, creates a new S3 bucket for AWS Config delivery. If false, the s3\_bucket\_name variable must reference an existing bucket. Defaults to true. | `bool` | `true` | no |
| <a name="input_delivery_channel_name"></a> [delivery\_channel\_name](#input\_delivery\_channel\_name) | (Optional) The name of the AWS Config delivery channel. Defaults to 'default'. | `string` | `"default"` | no |
| <a name="input_delivery_frequency"></a> [delivery\_frequency](#input\_delivery\_frequency) | (Optional) The frequency with which AWS Config delivers configuration snapshots to the S3 bucket. Valid values: One\_Hour, Three\_Hours, Six\_Hours, Twelve\_Hours, TwentyFour\_Hours. Defaults to TwentyFour\_Hours. | `string` | `"TwentyFour_Hours"` | no |
| <a name="input_enable_conformance_packs"></a> [enable\_conformance\_packs](#input\_enable\_conformance\_packs) | (Optional) If true, deploys the organization conformance packs defined in the conformance\_packs variable. Defaults to false. | `bool` | `false` | no |
| <a name="input_enable_s3_bucket_logging"></a> [enable\_s3\_bucket\_logging](#input\_enable\_s3\_bucket\_logging) | (Optional) If true, enables S3 server access logging for the Config delivery bucket. Requires s3\_logging\_target\_bucket to be set. Defaults to false. | `bool` | `false` | no |
| <a name="input_exclusion_resource_types"></a> [exclusion\_resource\_types](#input\_exclusion\_resource\_types) | (Optional) A list of resource types to exclude from recording when using EXCLUSION\_BY\_RESOURCE\_TYPES recording strategy. Leave empty when all\_supported is true and no exclusions are needed. | `list(string)` | `[]` | no |
| <a name="input_include_global_resource_types"></a> [include\_global\_resource\_types](#input\_include\_global\_resource\_types) | (Optional) Specifies whether AWS Config includes all supported types of global resources (e.g., IAM) with the resources it records. Only valid when all\_supported is true. Defaults to true. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) A name used as the Name tag on all taggable resources created by this module. | `string` | n/a | yes |
| <a name="input_recorder_name"></a> [recorder\_name](#input\_recorder\_name) | (Optional) The name of the AWS Config configuration recorder. Only one recorder per region is allowed. Defaults to 'default'. | `string` | `"default"` | no |
| <a name="input_recorder_role_arn"></a> [recorder\_role\_arn](#input\_recorder\_role\_arn) | (Required) ARN of the IAM role that AWS Config uses to record and deliver configuration changes. Must have the AWSConfigRole managed policy or equivalent permissions. | `string` | n/a | yes |
| <a name="input_recording_frequency"></a> [recording\_frequency](#input\_recording\_frequency) | (Optional) The recording frequency for the recorder. Valid values: CONTINUOUS, DAILY. Defaults to CONTINUOUS. | `string` | `"CONTINUOUS"` | no |
| <a name="input_recording_strategy"></a> [recording\_strategy](#input\_recording\_strategy) | (Optional) The recording strategy for the recorder. Valid values: ALL\_SUPPORTED\_RESOURCE\_TYPES, EXCLUSION\_BY\_RESOURCE\_TYPES, INCLUSION\_BY\_RESOURCE\_TYPES. Defaults to null (provider uses ALL\_SUPPORTED\_RESOURCE\_TYPES). | `string` | `null` | no |
| <a name="input_resource_types"></a> [resource\_types](#input\_resource\_types) | (Optional) A list of resource types to include for recording when using INCLUSION\_BY\_RESOURCE\_TYPES recording strategy. Leave empty when all\_supported is true. | `list(string)` | `[]` | no |
| <a name="input_s3_bucket_force_destroy"></a> [s3\_bucket\_force\_destroy](#input\_s3\_bucket\_force\_destroy) | (Optional) If true, all objects are deleted from the bucket when the bucket is destroyed, allowing the bucket to be destroyed without error. Defaults to false. | `bool` | `false` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | (Optional) The name of an existing S3 bucket to use for AWS Config delivery when create\_s3\_bucket is false. Must be set when create\_s3\_bucket is false. | `string` | `null` | no |
| <a name="input_s3_bucket_object_lock_enabled"></a> [s3\_bucket\_object\_lock\_enabled](#input\_s3\_bucket\_object\_lock\_enabled) | (Optional) Indicates whether this bucket has Object Lock enabled. Valid values are true or false. Defaults to false. | `bool` | `false` | no |
| <a name="input_s3_bucket_prefix"></a> [s3\_bucket\_prefix](#input\_s3\_bucket\_prefix) | (Optional) Name prefix for the S3 bucket created when create\_s3\_bucket is true. AWS will append a unique suffix to ensure global uniqueness. Defaults to 'config-'. | `string` | `"config-"` | no |
| <a name="input_s3_key_prefix"></a> [s3\_key\_prefix](#input\_s3\_key\_prefix) | (Optional) The S3 key prefix (folder path) within the delivery bucket where AWS Config stores configuration snapshots and history files. Set to null to store at bucket root. | `string` | `null` | no |
| <a name="input_s3_kms_key_arn"></a> [s3\_kms\_key\_arn](#input\_s3\_kms\_key\_arn) | (Optional) The ARN of the AWS KMS key used to encrypt objects delivered by AWS Config to the S3 delivery bucket. Set to null to use the bucket's default encryption. Defaults to null. | `string` | `null` | no |
| <a name="input_s3_logging_target_bucket"></a> [s3\_logging\_target\_bucket](#input\_s3\_logging\_target\_bucket) | (Optional) The name of the S3 bucket to receive server access logs from the Config delivery bucket. Required when enable\_s3\_bucket\_logging is true. | `string` | `null` | no |
| <a name="input_s3_logging_target_prefix"></a> [s3\_logging\_target\_prefix](#input\_s3\_logging\_target\_prefix) | (Optional) A prefix for all log object keys when S3 server access logging is enabled. Defaults to null. | `string` | `null` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | (Optional) The ARN of the SNS topic to which AWS Config sends notifications about configuration changes and compliance. Set to null to disable SNS notifications. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of additional tags to assign to all taggable resources. Merged with a Name tag derived from var.name. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_delegated_admin_id"></a> [delegated\_admin\_id](#output\_delegated\_admin\_id) | The unique identifier of the delegated administrator registration (account\_id:service\_principal). |
| <a name="output_delivery_channel_name"></a> [delivery\_channel\_name](#output\_delivery\_channel\_name) | The name of the AWS Config delivery channel. |
| <a name="output_recorder_name"></a> [recorder\_name](#output\_recorder\_name) | The name of the AWS Config configuration recorder. |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the S3 bucket used for AWS Config delivery. Returns null when create\_s3\_bucket is false. |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | The ID (name) of the S3 bucket used for AWS Config delivery. Returns null when create\_s3\_bucket is false. |
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
