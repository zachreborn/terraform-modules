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

<h3 align="center">Terraform Team Module</h3>
  <p align="center">
    This module creates a terraform team.
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
module "example_team" {
    source            = "github.com/zachreborn/terraform-modules//modules/terraform/team"

    name              = "example_team"
    organization      = var.example_organization
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                   | Version  |
| ------------------------------------------------------ | -------- |
| <a name="requirement_tfe"></a> [tfe](#requirement_tfe) | >=0.42.0 |

## Providers

| Name                                             | Version  |
| ------------------------------------------------ | -------- |
| <a name="provider_tfe"></a> [tfe](#provider_tfe) | >=0.42.0 |

## Modules

No modules.

## Resources

| Name                                                                                              | Type     |
| ------------------------------------------------------------------------------------------------- | -------- |
| [tfe_team.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team) | resource |

## Inputs

| Name                                                                                                   | Description                                                                                      | Type     | Default    | Required |
| ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ | -------- | ---------- | :------: |
| <a name="input_manage_modules"></a> [manage_modules](#input_manage_modules)                            | (Optional) Allow members to publish and delete modules in the organization's private registry.   | `bool`   | `false`    |    no    |
| <a name="input_manage_policies"></a> [manage_policies](#input_manage_policies)                         | (Optional) Allows members to create, edit, and delete the organization's Sentinel policies.      | `bool`   | `false`    |    no    |
| <a name="input_manage_policy_overrides"></a> [manage_policy_overrides](#input_manage_policy_overrides) | (Optional) Allows members to override soft-mandatory policy checks.                              | `bool`   | `false`    |    no    |
| <a name="input_manage_providers"></a> [manage_providers](#input_manage_providers)                      | (Optional) Allow members to publish and delete providers in the organization's private registry. | `bool`   | `false`    |    no    |
| <a name="input_manage_run_tasks"></a> [manage_run_tasks](#input_manage_run_tasks)                      | (Optional) Allow members to create, edit, and delete the organization's run tasks.               | `bool`   | `false`    |    no    |
| <a name="input_manage_vcs_settings"></a> [manage_vcs_settings](#input_manage_vcs_settings)             | (Optional) Allows members to manage the organization's VCS Providers and SSH keys.               | `bool`   | `false`    |    no    |
| <a name="input_manage_workspaces"></a> [manage_workspaces](#input_manage_workspaces)                   | (Optional) Allows members to create and administrate all workspaces within the organization.     | `bool`   | `false`    |    no    |
| <a name="input_name"></a> [name](#input_name)                                                          | (Required) Name of the team.                                                                     | `string` | n/a        |   yes    |
| <a name="input_organization"></a> [organization](#input_organization)                                  | (Required) Name of the organization.                                                             | `string` | n/a        |   yes    |
| <a name="input_sso_team_id"></a> [sso_team_id](#input_sso_team_id)                                     | (Optional) Unique Identifier to control team membership via SAML. Defaults to null               | `string` | `null`     |    no    |
| <a name="input_visibility"></a> [visibility](#input_visibility)                                        | (Optional) The visibility of the team ('secret' or 'organization'). Defaults to 'secret'.        | `string` | `"secret"` |    no    |

## Outputs

| Name                                      | Description |
| ----------------------------------------- | ----------- |
| <a name="output_id"></a> [id](#output_id) | n/a         |

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
