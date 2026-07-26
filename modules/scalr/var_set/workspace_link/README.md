<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Workspace Var Set Link Module</h3>
  <p align="center">
    This module links Scalr variable sets to workspaces (<code>scalr_workspace_var_set</code>).
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

- An existing Scalr workspace (`workspace_id`), e.g. from the root `modules/scalr` module or the `scalr_workspace`
  resource.
- An existing Scalr variable set (`var_set_id`), e.g. from the sibling `modules/scalr/var_set` module.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "workspace_var_set_links" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/var_set/workspace_link"

  workspace_var_set_links = {
    prod_shared_vars = {
      workspace_id = "ws-xxxxxxxxxx"
      var_set_id   = "varset-xxxxxxxxxx"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- This is a standalone companion submodule to `modules/scalr/var_set`, following the single-resource-focus
  convention. It can be used directly (with literal IDs, as shown above) or indirectly via
  `modules/scalr/var_set`'s own `workspace_links` input, which resolves `var_set_id` from that module's own
  `scalr_var_set` resources and calls this module internally -- see that module's README for the composed
  example and its wiring test for proof that the composition passes the right IDs through.

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
| scalr_workspace_var_set.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_workspace_var_set_links"></a> [workspace\_var\_set\_links](#input\_workspace\_var\_set\_links) | (Required) Map of workspace <-> variable set links (`scalr_workspace_var_set`) to create, keyed by a<br/>caller-chosen logical name.<br/>Fields:<br/>  - workspace\_id: (Required) ID of the workspace, in the format `ws-<RANDOM STRING>`.<br/>  - var\_set\_id:   (Required) ID of the variable set, in the format `varset-<RANDOM STRING>`. | <pre>map(object({<br/>    workspace_id = string<br/>    var_set_id   = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr workspace/var set link resource IDs (format '<workspace\_id>/<var\_set\_id>'), keyed by the same keys as var.workspace\_var\_set\_links. |
| <a name="output_links"></a> [links](#output\_links) | Map of the full resolved link (workspace\_id, var\_set\_id, id) for each entry, keyed by the same keys as var.workspace\_var\_set\_links. Useful for callers/tests that need to prove which workspace\_id/var\_set\_id combination was actually wired into each resource. |
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
