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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">ECR Module</h3>
  <p align="center">
    This module manages AWS Elastic Container Registry (ECR) resources.
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

### Simple Example

```hcl
module "ecr" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ecr"

  name = "my-app"

  tags = {
    created_by  = "terraform"
    environment = "prod"
    team        = "platform"
    terraform   = "true"
  }
}
```

### With Lifecycle Policy

```hcl
module "ecr" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ecr"

  name            = "my-app"
  encryption_type = "KMS"
  kms_key         = "arn:aws:kms:us-east-1:123456789012:key/mrk-abc123"

  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 30 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 30
        }
        action = { type = "expire" }
      }
    ]
  })

  tags = {
    created_by  = "terraform"
    environment = "prod"
    team        = "platform"
    terraform   = "true"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

## Notes

- **Encryption is always enabled.** ECR encrypts all images at rest. This module exposes `encryption_type` (`AES256` or `KMS`) and an optional `kms_key` ARN. When `encryption_type = "KMS"` and no `kms_key` is provided, the AWS-managed ECR CMK is used.
- **Tags are immutable by default.** `image_tag_mutability` defaults to `IMMUTABLE`, which prevents any image tag from being overwritten. Set to `MUTABLE` or use an exclusion filter if your pipeline requires reusing tags (e.g., `latest`).
- **Image scanning is enabled by default.** `scan_on_push = true` ensures every pushed image is scanned for vulnerabilities. Disable only if you manage scanning externally.
- **Lifecycle and repository policies are optional.** Pass a JSON-encoded policy string to `lifecycle_policy` or `repository_policy` to create the corresponding sub-resources inline.

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

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_encryption_type"></a> [encryption\_type](#input\_encryption\_type) | (Optional) The encryption type to use for the ECR repository. Valid values are 'AES256' or 'KMS'. Defaults to 'KMS' for Well-Architected compliance. | `string` | `"KMS"` | no |
| <a name="input_force_delete"></a> [force\_delete](#input\_force\_delete) | (Optional) Whether to force delete the repository even if it contains images. Defaults to false. | `bool` | `false` | no |
| <a name="input_image_tag_mutability"></a> [image\_tag\_mutability](#input\_image\_tag\_mutability) | (Optional) The tag mutability setting for the repository. Valid values are 'MUTABLE', 'IMMUTABLE', 'IMMUTABLE\_WITH\_EXCLUSION', or 'MUTABLE\_WITH\_EXCLUSION'. Defaults to 'IMMUTABLE' to prevent tag overwrites. | `string` | `"IMMUTABLE"` | no |
| <a name="input_image_tag_mutability_exclusion_filter"></a> [image\_tag\_mutability\_exclusion\_filter](#input\_image\_tag\_mutability\_exclusion\_filter) | (Optional) A list of tag filter expressions. Tags matching these filters will remain mutable even when the repository is set to IMMUTABLE\_WITH\_EXCLUSION or MUTABLE\_WITH\_EXCLUSION. Wildcards (*) match zero or more tag characters. Defaults to null (no exclusions). | `list(string)` | `null` | no |
| <a name="input_kms_key"></a> [kms\_key](#input\_kms\_key) | (Optional) The ARN of the KMS CMK to use when encryption\_type is 'KMS'. If not specified, the AWS-managed ECR CMK is used. Must be a valid KMS key ARN. Ignored when encryption\_type is 'AES256'. | `string` | `null` | no |
| <a name="input_lifecycle_policy"></a> [lifecycle\_policy](#input\_lifecycle\_policy) | (Optional) A JSON-encoded ECR lifecycle policy document. When set, an aws\_ecr\_lifecycle\_policy resource is created for this repository. Defaults to null (no lifecycle policy). | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the ECR repository. | `string` | n/a | yes |
| <a name="input_repository_policy"></a> [repository\_policy](#input\_repository\_policy) | (Optional) A JSON-encoded IAM policy document to attach to the repository. When set, an aws\_ecr\_repository\_policy resource is created. Defaults to null (no repository policy). | `string` | `null` | no |
| <a name="input_scan_on_push"></a> [scan\_on\_push](#input\_scan\_on\_push) | (Optional) Whether to enable automatic image scanning on push. Defaults to true. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the ECR repository. A 'Name' tag is added by default using the repository name and may be overridden by passing a 'Name' key in this map. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the ECR repository. |
| <a name="output_id"></a> [id](#output\_id) | The registry ID (AWS account ID) where the repository was created. |
| <a name="output_registry_id"></a> [registry\_id](#output\_registry\_id) | The registry ID (AWS account ID) where the repository was created. |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | The URL of the ECR repository in the form <registry\_id>.dkr.ecr.<region>.amazonaws.com/<repository\_name>. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | A map of all tags assigned to the ECR repository, including those inherited from the provider default\_tags block. |
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
