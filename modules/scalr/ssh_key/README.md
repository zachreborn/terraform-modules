<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr SSH Key Module</h3>
  <p align="center">
    This module manages Scalr SSH keys (<code>scalr_ssh_key</code>).
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

## Prerequisites

- A Scalr account and a configured `scalr` provider.
- The private key content for each SSH key, sourced securely (e.g. a secret manager or ephemeral variable) --
  never checked into version control in plain text.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "ssh_keys" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/ssh_key"

  ssh_keys = {
    deploy_key = {
      account_id   = "acc-xxxxxxxxxx"
      environments = ["*"]
    }
  }

  private_keys = {
    deploy_key = file("${path.module}/secrets/deploy_key.pem") # or sourced from a secret manager
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **Why `private_key` is a separate variable, not an attribute of `var.ssh_keys`:** OpenTofu/Terraform can only
  mark an entire variable as `sensitive`, not a single attribute inside an object-typed variable. Nesting
  `private_key` inside `var.ssh_keys` would force the whole entry (name, account_id, environments) to be hidden
  from plan output to keep the key safe, or leave the key un-redacted if the whole variable were left
  non-sensitive. Splitting it out into an always-sensitive `var.private_keys` map (keyed by the same logical
  name) keeps every other field visible for review while guaranteeing the key content is never shown in
  plan/apply output. This mirrors the same design decision made in `modules/scalr/variable`.
- Each entry's `name` defaults to its map key when unset, matching the convention used elsewhere in this
  repository (e.g. `modules/scalr/tag`).
- An `ssh_keys` entry with no matching `private_keys` entry resolves to a null `private_key`, which the Scalr
  provider rejects at plan/apply time since it is a required attribute -- there is no need for an additional
  cross-variable `validation` block to catch this case.

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
| scalr_ssh_key.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_private_keys"></a> [private\_keys](#input\_private\_keys) | (Required) Map of SSH private key content (the `private_key` attribute of `scalr_ssh_key`), keyed by the<br/>same keys as var.ssh\_keys. Kept as a separate, always-sensitive variable rather than an attribute nested<br/>inside var.ssh\_keys, since OpenTofu/Terraform cannot mark a single attribute of an object-typed variable as<br/>sensitive -- only whole variables can be marked sensitive. Splitting the key out keeps the rest of each<br/>entry's metadata (name, account\_id, environments) visible in plan output while still guaranteeing the<br/>private key content is never displayed.<br/>An entry with no matching key here resolves to a null private\_key, which the provider rejects as a<br/>required attribute. | `map(string)` | n/a | yes |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | (Required) Map of Scalr SSH keys (`scalr_ssh_key`) to create, keyed by a caller-chosen logical name.<br/>This variable intentionally excludes the actual private key content -- see var.private\_keys below.<br/>Fields:<br/>  - name:         (Optional) Name of the SSH key, must be unique within an account. Defaults to the<br/>                  entry's map key when unset.<br/>  - account\_id:   (Optional) ID of the account the SSH key belongs to, in the format `acc-<RANDOM STRING>`.<br/>  - environments: (Optional) Set of environment IDs where the SSH key can be used. Use ["*"] to share<br/>                  with all environments. | <pre>map(object({<br/>    name         = optional(string)<br/>    account_id   = optional(string)<br/>    environments = optional(set(string))<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr SSH key IDs, keyed by the same keys as var.ssh\_keys. |
| <a name="output_names"></a> [names](#output\_names) | Map of the resolved SSH key names (after the name-defaults-to-key behavior is applied), keyed by the same keys as var.ssh\_keys. |
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

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
