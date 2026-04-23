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

<h3 align="center">scalr/hook</h3>
  <p align="center">
    Terraform module for managing Scalr hooks registry entries. This module creates and manages one or more <code>scalr_hook</code> resources, sourcing scripts from a VCS provider for use in the Scalr hooks registry. Hooks can then be attached to environments or workspaces to execute custom scripts at specific stages of the Terraform/OpenTofu workflow.
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

### Single Hook — Terravision Post-Apply

This example registers the terravision post-apply script from a private GitHub repository into the Scalr hooks registry. The `vcs_provider_id` is the ID of the existing VCS provider already configured in Scalr for the SLFCU-Infrastructure org.

```hcl
module "scalr_hooks" {
  source          = "github.com/zachreborn/terraform-modules//modules/scalr/hook"
  vcs_provider_id = "vcs-xxxxxxxxxx"

  hooks = {
    terravision-post-apply = {
      description     = "Generates Terraform infrastructure visualization after apply"
      scriptfile_path = "hooks/scalr-post-apply.sh"
      vcs_repo = {
        identifier = "SLFCU-Infrastructure/terravision"
        branch     = "main"
      }
    }
  }
}
```

### Multiple Hooks with Shared VCS Provider and Repo

This example registers multiple hooks from the same repository, sharing the module-level VCS defaults.

```hcl
module "scalr_hooks" {
  source              = "github.com/zachreborn/terraform-modules//modules/scalr/hook"
  vcs_provider_id     = "vcs-xxxxxxxxxx"
  vcs_repo_identifier = "SLFCU-Infrastructure/terravision"

  hooks = {
    terravision-post-apply = {
      description     = "Generates Terraform infrastructure visualization after apply"
      scriptfile_path = "hooks/scalr-post-apply.sh"
    }
    terravision-post-plan = {
      description     = "Generates Terraform infrastructure visualization after plan"
      scriptfile_path = "hooks/scalr-post-plan.sh"
    }
  }
}
```

### Hook with Per-Hook VCS Provider Override

Hooks can override the module-level VCS provider or repo on a per-hook basis.

```hcl
module "scalr_hooks" {
  source          = "github.com/zachreborn/terraform-modules//modules/scalr/hook"
  vcs_provider_id = "vcs-xxxxxxxxxx"

  hooks = {
    custom-linter = {
      description     = "Runs custom linting before plan"
      interpreter     = "python3"
      scriptfile_path = "scripts/lint.py"
      vcs_repo = {
        identifier = "my-org/pipeline-tools"
        branch     = "stable"
      }
    }
    terravision-post-apply = {
      description     = "Generates Terraform infrastructure visualization after apply"
      scriptfile_path = "hooks/scalr-post-apply.sh"
      vcs_repo = {
        identifier = "SLFCU-Infrastructure/terravision"
        branch     = "main"
      }
    }
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
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| scalr_hook.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hooks"></a> [hooks](#input\_hooks) | Map of hooks to register in the Scalr hooks registry. The map key is used as a unique identifier and as the hook name if 'name' is not specified within the hook definition. | <pre>map(object({<br/>    description     = optional(string)<br/>    interpreter     = optional(string)<br/>    name            = optional(string)<br/>    scriptfile_path = string<br/>    vcs_provider_id = optional(string)<br/>    vcs_repo = optional(object({<br/>      identifier = string<br/>      branch     = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_interpreter"></a> [interpreter](#input\_interpreter) | The default interpreter used to execute hook scripts. Can be overridden per hook in the hooks map. Common values are 'bash' and 'python3'. | `string` | `"bash"` | no |
| <a name="input_vcs_provider_id"></a> [vcs\_provider\_id](#input\_vcs\_provider\_id) | The default VCS provider ID in the format 'vcs-<RANDOM STRING>'. Can be overridden per hook in the hooks map. | `string` | `null` | no |
| <a name="input_vcs_repo_branch"></a> [vcs\_repo\_branch](#input\_vcs\_repo\_branch) | The default VCS repository branch to pull hook scripts from. Can be overridden per hook in the hooks map. | `string` | `"main"` | no |
| <a name="input_vcs_repo_identifier"></a> [vcs\_repo\_identifier](#input\_vcs\_repo\_identifier) | The default VCS repository identifier in the format 'org/repo'. Used when vcs\_repo is not specified per hook. Can be overridden per hook in the hooks map. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_hook_ids"></a> [hook\_ids](#output\_hook\_ids) | Map of hook keys to their Scalr hook IDs in the format 'hook-<RANDOM STRING>'. |
| <a name="output_hook_names"></a> [hook\_names](#output\_hook\_names) | Map of hook keys to their registered Scalr hook names. |
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
