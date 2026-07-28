<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Infracost Integration Module</h3>
  <p align="center">
    This module manages <code>scalr_integration_infracost</code> resources in Scalr, surfacing Infracost cost estimates on runs in the linked environments.
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

- An Infracost API key. Generate one at [infracost.io](https://www.infracost.io).

### Simple Example

```hcl
module "infracost_integration" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/infracost"

  infracost_integrations = {
    default = {
      name         = "infracost"
      environments = ["*"]
    }
  }

  # Keyed to match var.infracost_integrations; kept out of the main object so it can be
  # sourced from a secret manager without tainting the rest of the config.
  infracost_api_keys = {
    default = var.infracost_api_key
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
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_integration_infracost.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_infracost_api_keys"></a> [infracost\_api\_keys](#input\_infracost\_api\_keys) | Map of Infracost API keys, keyed to match the same logical name used in var.infracost\_integrations. Sensitive. | `map(string)` | `{}` | no |
| <a name="input_infracost_integrations"></a> [infracost\_integrations](#input\_infracost\_integrations) | Map of Scalr Infracost integrations keyed by a caller-supplied logical name. Each entry<br/>manages one `scalr_integration_infracost` resource, surfacing Infracost cost estimates on<br/>runs in the linked environments.<br/><br/>Note: `api_key` is intentionally NOT a field of this object. Supply it via the sibling<br/>`infracost_api_keys` variable, keyed to the same logical name, so this variable (and any<br/>output derived from it) never needs to be marked sensitive. Every key in this map must have<br/>a matching key in var.infracost\_api\_keys.<br/><br/>Fields:<br/>  - name:         (Required) Name of the Infracost integration.<br/>  - environments: (Optional) List of environments this integration is linked to. Use ["*"]<br/>                   to allow in all environments.<br/><br/>Example:<br/>  infracost\_integrations = {<br/>    default = {<br/>      name         = "infracost"<br/>      environments = ["*"]<br/>    }<br/>  }<br/>  infracost\_api\_keys = {<br/>    default = var.infracost\_api\_key<br/>  } | <pre>map(object({<br/>    name         = string<br/>    environments = optional(set(string))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Infracost integration IDs keyed by the same logical name used in var.infracost\_integrations. |
| <a name="output_infracost_integrations"></a> [infracost\_integrations](#output\_infracost\_integrations) | Map of scalr\_integration\_infracost resource objects (excluding the sensitive api\_key attribute, which remains in state) keyed by the same logical name used in var.infracost\_integrations. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **`api_key` lives in a separate, sensitive variable.** The provider marks `api_key` as a sensitive, required attribute. Rather than marking the entire `infracost_integrations` map(object) sensitive, this module accepts the key through the dedicated `infracost_api_keys = map(string)` variable, keyed to the same logical name as `infracost_integrations`. This keeps plan diffs readable for non-sensitive fields while still protecting the secret.
- **Clear error on a missing key.** Each resource instance has a `precondition` that fails with a clear message if its logical name has no matching entry in `var.infracost_api_keys`, rather than a generic provider error about a missing required argument.
- **`infracost_integrations` output omits `api_key`.** Since `api_key` is never read back, the output only surfaces the non-sensitive attributes.

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
