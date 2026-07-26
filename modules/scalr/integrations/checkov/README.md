<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Checkov Integration Module</h3>
  <p align="center">
    This module manages <code>scalr_checkov_integration</code> resources in Scalr, running Checkov static analysis against runs in the linked environments.
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
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- USAGE EXAMPLES -->
## Usage

### Prerequisites

- If `external_checks_enabled = true`, a Scalr VCS provider must already exist to reference via `vcs_provider_id`.

### Simple Example

```hcl
module "checkov_integration" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/checkov"

  checkov_integrations = {
    default = {
      name         = "my-checkov-integration"
      environments = ["*"]
      cli_args     = "--quiet"
    }
  }
}
```

### With External (Custom) Checks

```hcl
module "checkov_integration" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/checkov"

  checkov_integrations = {
    custom_checks = {
      name                    = "custom-checks"
      external_checks_enabled = true
      vcs_provider_id         = "vcs-xxxxxxxxxx"
      vcs_repo = {
        identifier = "my-org/my-checkov-checks"
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
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.17.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | 3.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_checkov_integration.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_checkov_integrations"></a> [checkov\_integrations](#input\_checkov\_integrations) | Map of Scalr Checkov integrations keyed by a caller-supplied logical name. Each entry<br/>manages one `scalr_checkov_integration` resource, running Checkov static analysis against<br/>runs in the linked environments.<br/><br/>Fields:<br/>  - name:                    (Required) Name of the Checkov integration.<br/>  - cli\_args:                (Optional) CLI parameters to be passed to the checkov command.<br/>  - environments:            (Optional) List of environments this integration is linked to.<br/>                              Use ["*"] to allow in all environments.<br/>  - external\_checks\_enabled: (Optional, default false) Whether external (custom) Checkov<br/>                              checks from a VCS repository should be enabled.<br/>  - vcs\_provider\_id:         (Required if external\_checks\_enabled is true) ID of the VCS<br/>                              provider, in the format "vcs-<RANDOM STRING>".<br/>  - vcs\_repo:                (Required if external\_checks\_enabled is true) Settings for the<br/>                              Checkov integration's VCS repository.<br/>      - identifier: (Required) Reference to the VCS repository (format varies by VCS type).<br/>      - branch:     (Optional) Branch the custom checks are associated with.<br/>      - path:       (Optional) Sub-directory of the repository where checks are stored.<br/>  - version:                 (Optional) Version of the Checkov integration to use.<br/><br/>Example:<br/>  checkov\_integrations = {<br/>    default = {<br/>      name         = "my-checkov-integration"<br/>      environments = ["*"]<br/>      cli\_args     = "--quiet"<br/>    }<br/>    custom\_checks = {<br/>      name                    = "custom-checks"<br/>      external\_checks\_enabled = true<br/>      vcs\_provider\_id         = "vcs-xxxxxxxxxx"<br/>      vcs\_repo = {<br/>        identifier = "my-org/my-checkov-checks"<br/>        branch     = "main"<br/>      }<br/>    }<br/>  } | <pre>map(object({<br/>    name                    = string<br/>    cli_args                = optional(string)<br/>    environments            = optional(set(string))<br/>    external_checks_enabled = optional(bool, false)<br/>    vcs_provider_id         = optional(string)<br/>    vcs_repo = optional(object({<br/>      identifier = string<br/>      branch     = optional(string)<br/>      path       = optional(string)<br/>    }))<br/>    version = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_checkov_integrations"></a> [checkov\_integrations](#output\_checkov\_integrations) | Map of full scalr\_checkov\_integration resource objects keyed by the same logical name used in var.checkov\_integrations. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Checkov integration IDs keyed by the same logical name used in var.checkov\_integrations. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **`external_checks_enabled` requires VCS settings.** When an entry sets `external_checks_enabled = true`, validation rules require both `vcs_provider_id` and `vcs_repo` to be set, matching the provider's documented behavior.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

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
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
