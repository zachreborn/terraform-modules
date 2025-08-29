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

<h3 align="center">Bootstrapping for AWS</h3>
  <p align="center">
    This module is to be used for bootstrapping a new AWS account for use with Terraform Cloud or Terraform Enterprise. It helps to solve the issue where you would normally need to set up an AWS IAM user, access ID, and secret key in terraform. Instead, this module enables dynamic credentials which are single use and more secure. Should be utilized with modules/terraform/workspace and setting 'enable_dynamic_credentials = true'.
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
This module should be used to bootstrap an AWS account for Terraform Cloud or Terraform Enterprise. The following is an overview of the steps required to accomplish this.
### Steps
1. Download terraform cli
```
brew install terraform
```
2. Generate temporary credentials for the AWS account.
3. Copy the credentials as environment variables to your CLI
```
export AWS_ACCESS_KEY_ID="xxxxxx"
export AWS_SECRET_ACCESS_KEY="yyyyyy"
export AWS_SESSION_TOKEN="zzzzzz"
```
4. Run terraform init
```
terraform init
```
5. Run terraform plan
```
terraform plan
```
6. Run terraform apply
```
terraform apply
```
7. Update the terraform workspaces variables to enable dynamic authentication
```
module "workspace" {
  ...
  enable_dynamic_auth = true
  ...
}
```
8. Cleanup
```
sudo rm -r .terraform
rm .terraform.lock.hcl
rm *.tfstate
```


### Terraform Code Example
This example allows any project OU and any workspace name to leverage this OIDC identity provider
```
################################################################
# AWS Setup
################################################################

provider "aws" {
  region     = "us-east-1"
}

################################################################
# Bootstrapping
################################################################

module "bootstrap_aws" {
  source                         = "github.com/zachreborn/terraform-modules//modules/bootstrapping/aws"
  terraform_cloud_organization   = "your-tfe-org-name"
  terraform_cloud_project_name   = "*"
  terraform_cloud_workspace_name = "*"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.terraform_cloud](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.terraform_cloud](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.terraform_cloud](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [tls_certificate.terraform_cloud_certificate](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | (Optional) The name of the IAM role to assume when generating dynamic credentials for this workspace. | `string` | `"terraform_cloud"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the workspace. | `map(string)` | <pre>{<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_terraform_cloud_aws_audience"></a> [terraform\_cloud\_aws\_audience](#input\_terraform\_cloud\_aws\_audience) | (Optional) The audience value to use in the terraform run identity tokens | `string` | `"aws.workload.identity"` | no |
| <a name="input_terraform_cloud_hostname"></a> [terraform\_cloud\_hostname](#input\_terraform\_cloud\_hostname) | The hostname of the Terraform Cloud or Terraform Enterprise environment you'd like to use with the identity provider | `string` | `"app.terraform.io"` | no |
| <a name="input_terraform_cloud_organization"></a> [terraform\_cloud\_organization](#input\_terraform\_cloud\_organization) | (Required) The name of the Terraform Cloud organization which the workspace is in. | `string` | n/a | yes |
| <a name="input_terraform_cloud_project_name"></a> [terraform\_cloud\_project\_name](#input\_terraform\_cloud\_project\_name) | (Optional) The name of the Terraform Cloud project which the workspace is in. | `string` | `"Default Project"` | no |
| <a name="input_terraform_cloud_workspace_name"></a> [terraform\_cloud\_workspace\_name](#input\_terraform\_cloud\_workspace\_name) | (Optional) The name of the Terraform Cloud workspace which will use OIDC. | `string` | `"*"` | no |
| <a name="input_terraform_role_policy_arn"></a> [terraform\_role\_policy\_arn](#input\_terraform\_role\_policy\_arn) | (Optional) AWS IAM AdministratorAccess policy arn | `string` | `"arn:aws:iam::aws:policy/AdministratorAccess"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM role for 'terraform\_cloud' that Terraform Cloud/Enterprise will assume. |
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

* [Zachary Hill](https://zacharyhill.co)
* [Jake Jones](https://github.com/jakeasarus)

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