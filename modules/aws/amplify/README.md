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

<h3 align="center">module_name</h3>
  <p align="center">
    module_description
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
```
module test {
  source = 

  variable = 
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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_amplify_app.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_app) | resource |
| [aws_amplify_branch.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_branch) | resource |
| [aws_amplify_domain_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_domain_association) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_token"></a> [access\_token](#input\_access\_token) | Access token for the Amplify App. | `string` | `null` | no |
| <a name="input_auto_branch_creation_config"></a> [auto\_branch\_creation\_config](#input\_auto\_branch\_creation\_config) | Auto branch creation config for the Amplify App. | <pre>map(object({<br/>    basic_auth_credentials        = optional(string)<br/>    build_spec                    = optional(string)<br/>    enable_auto_build             = optional(bool)<br/>    enable_basic_auth             = optional(bool)<br/>    enable_performance_mode       = optional(bool)<br/>    enable_pull_request_preview   = optional(bool)<br/>    environment_variables         = optional(map(string))<br/>    framework                     = optional(string)<br/>    pull_request_environment_name = optional(string)<br/>    stage                         = optional(string) # Description of the stage. Valid values are PRODUCTION, BETA, DEVELOPMENT, EXPERIMENTAL, PULL_REQUEST.<br/>  }))</pre> | `null` | no |
| <a name="input_auto_branch_creation_patterns"></a> [auto\_branch\_creation\_patterns](#input\_auto\_branch\_creation\_patterns) | Patterns for auto branch creation. | `list(string)` | `null` | no |
| <a name="input_basic_auth_credentials"></a> [basic\_auth\_credentials](#input\_basic\_auth\_credentials) | Basic auth credentials for the Amplify App. | `string` | `null` | no |
| <a name="input_branches"></a> [branches](#input\_branches) | Branches for the Amplify App. | <pre>map(object({<br/>    basic_auth_credentials        = optional(string)      # Basic auth credentials for the branch.<br/>    branch_name                   = string                # The name of the branch.<br/>    certificate_type              = optional(string)      # The certificate type for the domain association. Valid values are AMPLIFY_MANAGED or CUSTOM.<br/>    custom_certificate_arn        = optional(string)      # The ARN for the custom certificate.<br/>    description                   = optional(string)      # The description of the branch.<br/>    display_name                  = optional(string)      # The display name of the branch. This gets used as the default domain prefix.<br/>    domain_name                   = string                # The domain name for the domain association.<br/>    enable_auto_build             = optional(bool, true)  # Enable auto build for the branch.<br/>    enable_auto_sub_domain        = optional(bool, false) # Enable auto sub domain for the domain association.<br/>    enable_basic_auth             = optional(bool)        # Enable basic auth for the branch.<br/>    enable_certificate            = optional(bool, true)  # Enable certificate for the domain association.<br/>    enable_notification           = optional(bool)        # Enable notification for the branch.<br/>    enable_performance_mode       = optional(bool)        # Enable performance mode for the branch.<br/>    enable_pull_request_preview   = optional(bool)        # Enable pull request preview for the branch.<br/>    environment_variables         = optional(map(string)) # Map of environment variables for the branch.<br/>    framework                     = optional(string)      # The framework for the branch.<br/>    pull_request_environment_name = optional(string)      # The name of the pull request environment.<br/>    stage                         = optional(string)      # The stage for the branch. Valid values are PRODUCTION, BETA, DEVELOPMENT, EXPERIMENTAL, PULL_REQUEST.<br/>    sub_domains = optional(map(object({<br/>      branch_name = string                       # The branch name for the sub domain.<br/>      prefix      = string                       # The prefix for the sub domain.<br/>    })))                                         # The sub domains for the domain association.<br/>    ttl                   = optional(number)     # The TTL for the branch.<br/>    wait_for_verification = optional(bool, true) # Wait for verification for the domain association.<br/>  }))</pre> | n/a | yes |
| <a name="input_build_spec"></a> [build\_spec](#input\_build\_spec) | Build spec for the Amplify App. | `string` | `null` | no |
| <a name="input_cache_config_type"></a> [cache\_config\_type](#input\_cache\_config\_type) | Cache config type for the Amplify App. Valid values are AMPLIFY\_MANAGED, AMPLIFY\_MANAGED\_NO\_COOKIES, | `string` | `"AMPLIFY_MANAGED"` | no |
| <a name="input_custom_headers"></a> [custom\_headers](#input\_custom\_headers) | Custom headers string for the Amplify App. | `string` | `null` | no |
| <a name="input_custom_rules"></a> [custom\_rules](#input\_custom\_rules) | Custom rules for the Amplify App. | <pre>map(object({<br/>    condition = optional(string) # Condition for a URL redirect or rewrite.<br/>    source    = string           # Source pattern for URL redirect or rewrite.<br/>    status    = optional(string) # Status code for URL redirect or rewrite. Valid values are 200, 301, 302, 404, 404-200.<br/>    target    = string           # Target pattern for URL redirect or rewrite.<br/>  }))</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the Amplify App. | `string` | `null` | no |
| <a name="input_enable_auto_branch_creation"></a> [enable\_auto\_branch\_creation](#input\_enable\_auto\_branch\_creation) | Enable auto branch creation for the Amplify App. | `bool` | `false` | no |
| <a name="input_enable_basic_auth"></a> [enable\_basic\_auth](#input\_enable\_basic\_auth) | Enable basic auth for the Amplify App. | `bool` | `false` | no |
| <a name="input_enable_branch_auto_build"></a> [enable\_branch\_auto\_build](#input\_enable\_branch\_auto\_build) | Enable branch auto build for the Amplify App. | `bool` | `false` | no |
| <a name="input_enable_branch_auto_deletion"></a> [enable\_branch\_auto\_deletion](#input\_enable\_branch\_auto\_deletion) | Enable branch auto deletion for the Amplify App. | `bool` | `false` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables in a map for the Amplify App. | `map(string)` | `null` | no |
| <a name="input_iam_service_role_arn"></a> [iam\_service\_role\_arn](#input\_iam\_service\_role\_arn) | IAM service role ARN for the Amplify App. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the Amplify App. | `string` | n/a | yes |
| <a name="input_oauth_token"></a> [oauth\_token](#input\_oauth\_token) | OAuth token for the Amplify App. | `string` | `null` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | Platform for the Amplify App. Options are WEB or WEB\_COMPUTE. | `string` | `"WEB"` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | Repository for the Amplify App. This could be hosted in AWS Code Commit, Bitbucket, GitHub, GitLab, etc. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the Amplify App. | `map(string)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

No outputs.
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