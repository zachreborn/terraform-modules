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

  admin_account_id  = "123456789012"
  recorder_role_arn = "arn:aws:iam::123456789012:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  create_s3_bucket  = true
  s3_bucket_prefix  = "config-"
  s3_key_prefix     = "org-config"
  delivery_frequency = "TwentyFour_Hours"

  tags = {
    created_by  = "terraform"
    environment = "prod"
    terraform   = "true"
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

  admin_account_id  = "123456789012"
  recorder_role_arn = "arn:aws:iam::123456789012:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  create_s3_bucket = false
  s3_bucket_name   = "my-existing-config-bucket"
  s3_key_prefix    = "config"

  tags = {
    created_by  = "terraform"
    environment = "prod"
    terraform   = "true"
  }
}
```

### Organization Config with Conformance Packs

```hcl
module "config_organization" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/config/organization"

  providers = {
    aws.organization_management_account = aws.organization_management_account
    aws.organization_config_account     = aws.organization_config_account
  }

  admin_account_id  = "123456789012"
  recorder_role_arn = "arn:aws:iam::123456789012:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  create_s3_bucket         = true
  s3_bucket_prefix         = "config-"
  enable_conformance_packs = true

  conformance_packs = [
    {
      name            = "operational-best-practices-for-cis-aws"
      template_s3_uri = "s3://my-templates-bucket/cis-conformance-pack.yaml"
    },
    {
      name          = "custom-security-controls"
      template_body = <<-YAML
        Parameters: {}
        Resources: {}
      YAML
    }
  ]

  tags = {
    created_by  = "terraform"
    environment = "prod"
    terraform   = "true"
  }
}
```

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
| <a name="provider_aws.organization_management_account"></a> [aws.organization\_management\_account](#provider\_aws.organization\_management\_account) | >= 6.0.0 |
| <a name="provider_aws.organization_config_account"></a> [aws.organization\_config\_account](#provider\_aws.organization\_config\_account) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_organizations_delegated_administrator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_config_configuration_recorder.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_config_organization_conformance_pack.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_organization_conformance_pack) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.config_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.config_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_account_id"></a> [admin\_account\_id](#input\_admin\_account\_id) | (Required) The AWS account ID to register as the delegated administrator for AWS Config in the organization. | `string` | n/a | yes |
| <a name="input_recorder_role_arn"></a> [recorder\_role\_arn](#input\_recorder\_role\_arn) | (Required) ARN of the IAM role that AWS Config uses to record and deliver configuration changes. | `string` | n/a | yes |
| <a name="input_recorder_name"></a> [recorder\_name](#input\_recorder\_name) | (Optional) The name of the AWS Config configuration recorder. Defaults to 'default'. | `string` | `"default"` | no |
| <a name="input_include_global_resource_types"></a> [include\_global\_resource\_types](#input\_include\_global\_resource\_types) | (Optional) Whether to include global resource types (e.g., IAM). Defaults to true. | `bool` | `true` | no |
| <a name="input_delivery_channel_name"></a> [delivery\_channel\_name](#input\_delivery\_channel\_name) | (Optional) The name of the AWS Config delivery channel. Defaults to 'default'. | `string` | `"default"` | no |
| <a name="input_delivery_frequency"></a> [delivery\_frequency](#input\_delivery\_frequency) | (Optional) Snapshot delivery frequency. Valid values: One\_Hour, Three\_Hours, Six\_Hours, Twelve\_Hours, TwentyFour\_Hours. Defaults to TwentyFour\_Hours. | `string` | `"TwentyFour_Hours"` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | (Optional) ARN of an SNS topic for Config notifications. Defaults to null. | `string` | `null` | no |
| <a name="input_create_s3_bucket"></a> [create\_s3\_bucket](#input\_create\_s3\_bucket) | (Optional) If true, creates a new S3 bucket for Config delivery. Defaults to true. | `bool` | `true` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | (Optional) Name of an existing S3 bucket when create\_s3\_bucket is false. | `string` | `null` | no |
| <a name="input_s3_bucket_prefix"></a> [s3\_bucket\_prefix](#input\_s3\_bucket\_prefix) | (Optional) Name prefix for a newly created S3 bucket. Defaults to 'config-'. | `string` | `"config-"` | no |
| <a name="input_s3_key_prefix"></a> [s3\_key\_prefix](#input\_s3\_key\_prefix) | (Optional) S3 key prefix for Config delivery within the bucket. Defaults to null. | `string` | `null` | no |
| <a name="input_enable_conformance_packs"></a> [enable\_conformance\_packs](#input\_enable\_conformance\_packs) | (Optional) If true, deploys organization conformance packs. Defaults to false. | `bool` | `false` | no |
| <a name="input_conformance_packs"></a> [conformance\_packs](#input\_conformance\_packs) | (Optional) List of organization conformance packs. Each requires name and template\_s3\_uri or template\_body. | `list(object({...}))` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to all taggable resources. | `map(string)` | `{...}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_delegated_admin_id"></a> [delegated\_admin\_id](#output\_delegated\_admin\_id) | The unique identifier of the delegated administrator registration. |
| <a name="output_recorder_name"></a> [recorder\_name](#output\_recorder\_name) | The name of the AWS Config configuration recorder. |
| <a name="output_delivery_channel_name"></a> [delivery\_channel\_name](#output\_delivery\_channel\_name) | The name of the AWS Config delivery channel. |
| <a name="output_s3_bucket_id"></a> [s3\_bucket\_id](#output\_s3\_bucket\_id) | The ID (name) of the S3 bucket used for AWS Config delivery. |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the S3 bucket used for AWS Config delivery. |
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
