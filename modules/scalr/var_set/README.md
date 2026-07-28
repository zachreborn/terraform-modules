<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Var Set Module</h3>
  <p align="center">
    This module manages Scalr variable sets (<code>scalr_var_set</code>) and, optionally, their links to
    workspaces (<code>scalr_workspace_var_set</code>, via the companion <a href="./workspace_link">workspace_link</a> submodule).
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
- Any workspace IDs referenced by `workspace_links` entries must already exist (e.g. from the root `modules/scalr`
  module or the `scalr_workspace` resource).

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "var_sets" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/var_set"

  var_sets = {
    shared_defaults = {
      description  = "Variables shared across every environment"
      environments = ["*"]
    }
  }
}
```

### Composed with workspace links

```hcl
module "var_sets" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/var_set"

  var_sets = {
    shared_defaults = {
      description = "Variables shared with prod workspaces"
    }
  }

  workspace_links = {
    prod_app = {
      workspace_id = "ws-xxxxxxxxxx"
      var_set_key  = "shared_defaults" # resolves to module.var_sets.ids["shared_defaults"] internally
    }
    legacy_app = {
      workspace_id = "ws-yyyyyyyyyy"
      var_set_id   = "varset-zzzzzzzzzz" # an existing variable set managed outside this module call
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `modules/scalr/var_set/workspace_link` (`scalr_workspace_var_set`) is a standalone, single-resource-focus
  companion submodule that can be used on its own. This module optionally composes it via `workspace_links`, so
  a single module call can create variable sets and wire them to workspaces together -- mirroring the
  parent/companion composition pattern used by `modules/aws/organizations` (which composes `./account` and
  `./delegated_admin`).
- `workspace_links` entries may reference either a literal `var_set_id` or a `var_set_key` pointing at an entry
  in `var.var_sets` created by this same module call; exactly one must be set, enforced by a `validation` block.
- `name` on each `var_sets` entry defaults to its map key when unset, matching the convention used elsewhere in
  this repository (e.g. `modules/scalr/tag`, `modules/aws/organizations/account`).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.17.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.17.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_workspace_link"></a> [workspace\_link](#module\_workspace\_link) | ./workspace_link | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| scalr_var_set.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_var_sets"></a> [var\_sets](#input\_var\_sets) | (Optional) Map of Scalr variable sets (`scalr_var_set`) to create, keyed by a caller-chosen logical name<br/>(e.g. "shared\_defaults"). This key can also be referenced by var.workspace\_links entries via var\_set\_key.<br/>Fields:<br/>  - name:         (Optional) Name of the variable set. Defaults to the entry's map key when unset.<br/>  - description:  (Optional) Description of the variable set.<br/>  - environments: (Optional) Set of environment IDs this variable set is shared to. Use ["*"] to share with<br/>                   all environments.<br/>  - owners:       (Optional) Set of team IDs this variable set belongs to. | <pre>map(object({<br/>    name         = optional(string)<br/>    description  = optional(string)<br/>    environments = optional(set(string))<br/>    owners       = optional(set(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_workspace_links"></a> [workspace\_links](#input\_workspace\_links) | (Optional) Map of workspace <-> variable set links to create via the companion ./workspace\_link submodule,<br/>keyed by a caller-chosen logical name. Each entry must set exactly one of:<br/>  - var\_set\_id:  A literal variable set ID, in the format `varset-<RANDOM STRING>` (e.g. for a variable set<br/>                 managed outside this module call).<br/>  - var\_set\_key: A key into var.var\_sets, resolving to the ID of a variable set created by this same module<br/>                 call. An unknown key fails naturally when OpenTofu/Terraform tries to index<br/>                 scalr\_var\_set.this by that key.<br/>Fields:<br/>  - workspace\_id: (Required) ID of the workspace, in the format `ws-<RANDOM STRING>`.<br/>  - var\_set\_id:   (Optional) Literal variable set ID. Conflicts with var\_set\_key.<br/>  - var\_set\_key:  (Optional) Key into var.var\_sets. Conflicts with var\_set\_id. | <pre>map(object({<br/>    workspace_id = string<br/>    var_set_id   = optional(string)<br/>    var_set_key  = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_ids"></a> [account\_ids](#output\_account\_ids) | Map of the Scalr account ID each variable set belongs to, keyed by the same keys as var.var\_sets. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr variable set IDs, keyed by the same keys as var.var\_sets. |
| <a name="output_updated_at"></a> [updated\_at](#output\_updated\_at) | Map of the UTC timestamp of the last update to each variable set, keyed by the same keys as var.var\_sets. |
| <a name="output_updated_by_email"></a> [updated\_by\_email](#output\_updated\_by\_email) | Map of the email address of the user who last updated each variable set, keyed by the same keys as var.var\_sets. |
| <a name="output_workspace_link_ids"></a> [workspace\_link\_ids](#output\_workspace\_link\_ids) | Map of workspace/var set link resource IDs, keyed by the same keys as var.workspace\_links. |
| <a name="output_workspace_links"></a> [workspace\_links](#output\_workspace\_links) | Map of the full resolved link (workspace\_id, var\_set\_id, id) for each var.workspace\_links entry. |
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
