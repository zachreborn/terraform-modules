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

<h3 align="center">AWS Organizations OU</h3>
  <p align="center">
    This module creates an OU within the AWS Organization based on the configuration.
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

### Composed Module

If you need the Organization itself, its OUs, and its member accounts all managed together from one YAML file, use [`modules/aws/organizations`](..) instead of calling this module directly — it wires this module and [`modules/aws/organizations/account`](../account) together automatically, including defaulting a bare top-level OU's `parent_id` to the managed Organization's root. This module remains fully usable standalone (as shown below) for partial adoption, e.g. OUs managed here with accounts vended by a different process.

Upgrading from v8 and using this module alongside `organization`/`account`? See the
[migration guide](../MIGRATION.md) for both options: keep the modules separate (Path A, summarized in
the Migration Guide below), or consolidate into the composed module (Path B).

### Flat and Nested Example

This example creates four top-level OUs and three OUs nested under `workloads`, mirroring a typical AWS Organizations layout. `name` is optional and defaults to the entry's map key, so it's omitted below; called standalone (without the composed module above), every entry must still set `parent_id` or `parent_key` explicitly, since this module has no way to default a parent on its own.

```
module "organizational_units" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/ou"

  organizational_units = {
    aws_infrastructure = {
      parent_id = "r-n1v2"
    }
    cybersecurity = {
      parent_id = "r-n1v2"
    }
    workloads = {
      parent_id = "r-n1v2"
    }
    suspended = {
      parent_id = "r-n1v2"
    }
    prod = {
      parent_key = "workloads"
    }
    staging = {
      parent_key = "workloads"
    }
    dev = {
      parent_key = "workloads"
    }
  }
}
```

Other resources can look up a specific OU's ID via `module.organizational_units.ids["prod"]`.

### YAML File Example

For larger organizations, source the map from a YAML file instead of inlining it:

```yaml
# organizational_units.yaml
workloads:
  parent_id: r-n1v2
prod:
  parent_key: workloads
```

```
locals {
  organizational_units = yamldecode(file("${path.module}/organizational_units.yaml"))
}

module "organizational_units" {
  source                = "github.com/zachreborn/terraform-modules//modules/aws/organizations/ou"
  organizational_units  = local.organizational_units
}
```

### Cross-Module Composition with the Account Module

This module's `ids` output is designed to be passed directly into [`modules/aws/organizations/account`](../account)'s `organizational_unit_ids` input, so accounts can attach to OUs created here via a `parent_key` instead of a hardcoded ID. Both modules' inputs can be sourced from a single YAML file with `organizational_units:` and `accounts:` top-level keys — or use [`modules/aws/organizations`](..), which does this wiring for you:

```yaml
# organization_structure.yaml
organizational_units:
  workloads:
    parent_id: r-n1v2
  prod:
    parent_key: workloads

accounts:
  company_name:
    email: jdoe@example.com
    parent_key: prod
```

```
locals {
  org_structure = yamldecode(file("${path.module}/organization_structure.yaml"))
}

module "organizational_units" {
  source                = "github.com/zachreborn/terraform-modules//modules/aws/organizations/ou"
  organizational_units  = local.org_structure.organizational_units
}

module "accounts" {
  source                   = "github.com/zachreborn/terraform-modules//modules/aws/organizations/account"
  accounts                 = local.org_structure.accounts
  organizational_unit_ids  = module.organizational_units.ids
}
```

### Migration Guide (v8 -> v9)

Version 9 replaces the single-OU `name`/`parent_id` inputs and singular `id`/`arn`/`accounts` outputs with the map-based `organizational_units` input and keyed `ids`/`arns`/`accounts` outputs described above. This is a **breaking change** (shipped as a `feat!:` commit, bumping the module's MAJOR version per this repo's release-please conventions) because:
- The `name` and `parent_id` variables no longer exist; all configuration moves into `organizational_units` map entries.
- The `id`, `arn`, and `accounts` outputs are now `ids`, `arns`, and `accounts` maps keyed by logical name instead of single values.
- Within each `organizational_units` entry, `name` is optional and defaults to the entry's map key, so it can be omitted whenever it would just repeat the key.

#### Step 1: Convert each module call into one map entry

Each existing `module "x_ou" { name = ...; parent_id = ... }` block becomes one entry in a single `organizational_units` map. Replace any `parent_id = module.<other_ou>.id` reference with `parent_key = "<other_ou_key>"` when the parent OU is also being created by this same module call.

For example, this:

```
module "workloads_ou" {
  source    = "github.com/zachreborn/terraform-modules//modules/aws/organizations/ou"
  name      = "workloads"
  parent_id = module.company_organization.roots[0].id
}

module "prod_ou" {
  source    = "github.com/zachreborn/terraform-modules//modules/aws/organizations/ou"
  name      = "prod"
  parent_id = module.workloads_ou.id
}
```

becomes:

```
module "organizational_units" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/ou"

  organizational_units = {
    workloads = {
      name      = "workloads"
      parent_id = module.company_organization.roots[0].id
    }
    prod = {
      name       = "prod"
      parent_key = "workloads"
    }
  }
}
```

#### Step 2: Move state instead of letting Terraform destroy/recreate

AWS refuses to delete a non-empty OU, so a plain apply of the config above would fail: Terraform would want to destroy `module.workloads_ou.aws_organizations_organizational_unit.this` and create a new resource at a different address. Add a `moved` block per existing OU to your **consumer** configuration (not this module) so Terraform reconciles state instead:

```
moved {
  from = module.workloads_ou.aws_organizations_organizational_unit.this
  to   = module.organizational_units.aws_organizations_organizational_unit.level_0["workloads"]
}

moved {
  from = module.prod_ou.aws_organizations_organizational_unit.this
  to   = module.organizational_units.aws_organizations_organizational_unit.level_1["prod"]
}
```

The destination resource name depends on how deeply nested the OU is: entries with a literal `parent_id` land in `level_0`, entries whose `parent_key` points at a `level_0` entry land in `level_1`, and so on up to `level_3`. `moved` blocks work across module-instance boundaries like this; this pattern is already used in downstream consumers (e.g. this repo's reference consumer keeps a `moved.tf` for module renames).

#### Step 3: Update downstream references

| Old reference | New reference |
|---|---|
| `module.workloads_ou.id` | `module.organizational_units.ids["workloads"]` |
| `module.workloads_ou.arn` | `module.organizational_units.arns["workloads"]` |
| `module.workloads_ou.accounts` | `module.organizational_units.accounts["workloads"]` |

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_organizations_organizational_unit.level_0](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.level_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.level_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |
| [aws_organizations_organizational_unit.level_3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_organizational_units"></a> [organizational\_units](#input\_organizational\_units) | (Required) Map of Organizational Units to create, keyed by a caller-chosen logical name (e.g. "workloads").<br/>A bare entry (e.g. `workloads:` with no value in YAML, which decodes to null) is a valid value for this<br/>map's element type, but this module's own validation always rejects it, since a null entry has neither<br/>parent\_id nor parent\_key set (see below). Bare entries are only useful as an authoring convenience for a<br/>caller (such as the modules/aws/organizations composed module) that resolves each entry into a concrete<br/>object -- typically injecting a default parent\_id -- before passing the map to this module; by the time<br/>this module validates organizational\_units, no entry may still be null.<br/>Each entry must set exactly one of:<br/>  - parent\_id:  A literal parent Root ID (e.g. "r-abcd") or an externally-managed OU ID. Use this for<br/>                top-level entries whose parent is not itself created by this module call.<br/>  - parent\_key: The map key of another entry in this same variable that is this OU's parent. Use this<br/>                for OUs nested under an OU also being created by this module call (e.g. an entry named<br/>                "prod" can set parent\_key = "workloads" to nest under the "workloads" entry).<br/>Nesting via parent\_key is supported up to 4 levels deep (i.e. an entry's parent\_key chain may pass<br/>through at most 3 other entries before reaching an entry that sets a literal parent\_id). AWS<br/>Organizations itself supports up to 5 levels of OUs below the root; entries that would resolve deeper<br/>than the 4 levels supported here will fail the precondition on the module's `ids` output.<br/>Fields:<br/>  - name:       (Optional) The name of the Organizational Unit. Defaults to the entry's map key when unset.<br/>  - parent\_id:  (Optional) Literal parent Root or OU ID. Conflicts with parent\_key.<br/>  - parent\_key: (Optional) Key of another entry in this map that is this OU's parent. Conflicts with parent\_id.<br/>  - tags:       (Optional) Additional tags for this OU, merged with var.tags. | <pre>map(object({<br/>    name       = optional(string)<br/>    parent_id  = optional(string)<br/>    parent_key = optional(string)<br/>    tags       = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to every Organizational Unit, merged with each entry's optional per-OU tags. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_accounts"></a> [accounts](#output\_accounts) | Map of the list of accounts in each Organizational Unit, keyed by the same keys as var.organizational\_units. |
| <a name="output_arns"></a> [arns](#output\_arns) | Map of Organizational Unit ARNs, keyed by the same keys as var.organizational\_units. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Organizational Unit IDs, keyed by the same keys as var.organizational\_units. |
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
