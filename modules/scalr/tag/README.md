<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Tag Module</h3>
  <p align="center">
    This module manages one or more Scalr tags (<code>scalr_tag</code>).
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

- A Scalr account and a configured `scalr` provider (account token or run-scoped credentials). This module does not
  call `data.scalr_current_account`, so if `account_id` is left unset on an entry, the provider's own default account
  scoping is used.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "tags" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/tag"

  tags = {
    network    = {}
    compliance = { name = "pci-scope" }
    sandbox    = { account_id = "acc-xxxxxxxxxx" }
  }
}

# environment/workspace modules can then reference module.tags.ids["network"], etc.
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- Each entry's `name` defaults to its map key when unset, matching the convention used elsewhere in this repository
  (e.g. `modules/aws/organizations/account`) so simple, single-word tags don't need a redundant `name` attribute.
- `account_id` is exposed per-entry (rather than a single module-wide default) since a caller may need to tag
  resources across more than one Scalr account with a single module call.
- This module unblocks the `tag_ids` inputs already accepted by the root `modules/scalr` module's environment and
  workspace resources.

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
| scalr_tag.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_tags"></a> [tags](#input\_tags) | (Required) Map of Scalr tags to create, keyed by a caller-chosen logical name (e.g. "network").<br/>Fields:<br/>  - name:       (Optional) The literal tag name in Scalr. Defaults to the entry's map key when unset.<br/>  - account\_id: (Optional) ID of the account the tag belongs to, in the format `acc-<RANDOM STRING>`.<br/>                Defaults to null, in which case the provider resolves the account from its own<br/>                configuration (e.g. the ACCOUNT\_ID it was configured with). | <pre>map(object({<br/>    name       = optional(string)<br/>    account_id = optional(string)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr tag IDs, keyed by the same keys as var.tags. |
| <a name="output_names"></a> [names](#output\_names) | Map of the resolved tag names (after the name-defaults-to-key behavior is applied), keyed by the same keys as var.tags. |
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
