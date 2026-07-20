<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
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

<h3 align="center">AWS WorkSpaces Service Role Module</h3>
  <p align="center">
    This module creates the account-wide workspaces_DefaultRole IAM role that the Amazon WorkSpaces service requires.
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
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
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

IAM roles are account-global, not regional -- this module manages a single, account-wide resource, so only call it once per AWS account (calling it again in a second region will fail with `EntityAlreadyExists`). Set `enable_service_role = false` on the parent `modules/aws/workspaces` module for every additional call (e.g. one per region) once the role already exists.

### Simple Example

```
module "workspaces_service_role" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/workspaces/service_role"
}
```

### Self-Service Access Example

```
module "workspaces_service_role" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/workspaces/service_role"

  enable_self_service_access = true

  tags = {
    team = "it"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

None -- this module only creates an IAM role and does not depend on any other WorkSpaces resources. It is a prerequisite *for* the other `modules/aws/workspaces/*` modules, since Amazon WorkSpaces will not provision desktops without a `workspaces_DefaultRole` role present in the account.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- This module composes `modules/aws/iam/role` rather than declaring an inline `aws_iam_role`, per this repository's module composition guidance.
- `AmazonWorkSpacesServiceAccess` is always attached; `AmazonWorkSpacesSelfServiceAccess` is attached by default via `enable_self_service_access` (default `true`), matching AWS's own default `workspaces_DefaultRole` setup and the directory submodule's secure-by-default `restart_workspace = true`. Set `enable_self_service_access = false` to omit it if you don't delegate any self-service actions (rebuild, restart, change compute type) to end users.
- Only one `workspaces_DefaultRole` is useful per account -- this module does not accept a map input (see Module Design Spec §5's documented exception for standalone singleton resources).

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.54.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_role"></a> [role](#module\_role) | ../../iam/role | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_enable_self_service_access"></a> [enable\_self\_service\_access](#input\_enable\_self\_service\_access) | (Optional) If true (the default), additionally attaches the AmazonWorkSpacesSelfServiceAccess managed policy so this role also covers self-service actions (rebuild, restart, change compute type, etc.), in addition to the always-attached AmazonWorkSpacesServiceAccess policy. Defaults to true to match AWS's own default workspaces\_DefaultRole setup (both managed policies attached) and modules/aws/workspaces/directory's own secure-by-default restart\_workspace = true -- setting this false would advertise self-service restart without the IAM permission needed to perform it. Set to false only if you intend to also disable every directory self-service permission. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | (Optional) Name of the IAM role. Amazon WorkSpaces looks up this role by the exact, hard-coded name workspaces\_DefaultRole -- the WorkSpaces directory/desktop APIs do not accept an alternate role name, so this must always be exactly "workspaces\_DefaultRole". Exposed as a variable (rather than a hard-coded literal) purely for self-documentation/testability; it is validated below and cannot actually be changed to a working alternate value. | `string` | `"workspaces_DefaultRole"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the IAM role. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The Amazon Resource Name (ARN) of the workspaces\_DefaultRole IAM role. |
| <a name="output_name"></a> [name](#output\_name) | The name of the workspaces\_DefaultRole IAM role. |
| <a name="output_policy_arns"></a> [policy\_arns](#output\_policy\_arns) | List of managed policy ARNs attached to the role (always includes AmazonWorkSpacesServiceAccess, plus AmazonWorkSpacesSelfServiceAccess when enable\_self\_service\_access is true). |
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
