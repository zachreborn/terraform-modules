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

<h3 align="center">AWS Organizations Account Module</h3>
  <p align="center">
    This module generates and manages an AWS Organization Account
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

If you need the Organization itself, its OUs, and its member accounts all managed together from one YAML file, use [`modules/aws/organizations`](..) instead of calling this module directly — it wires this module and [`modules/aws/organizations/ou`](../ou) together automatically. This module remains fully usable standalone (as shown below) for partial adoption, e.g. accounts managed here attaching to OUs created by a different process.

Upgrading from v8 and using this module alongside `organization`/`ou`? See the
[migration guide](../MIGRATION.md) for both options: keep the modules separate (Path A, summarized in
the Migration Guide below), or consolidate into the composed module (Path B).

### Flat Example

This example creates two member accounts, one attached via a literal parent OU ID and one attached via `parent_key` to an OU ID supplied by the caller (e.g. sourced from `modules/aws/organizations/ou`). `name` is optional and defaults to the entry's map key, so it's omitted below; `email` has no default and is always required.

```
module "accounts" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/account"

  organizational_unit_ids = {
    workloads = "ou-abcd-11111111"
  }

  accounts = {
    account_prod_infrastructure = {
      email     = "aws_environments+account@example.com"
      parent_id = var.account_parent_id
    }
    company_name = {
      email      = "jdoe@example.com"
      parent_key = "workloads"
    }
  }
}
```

Other resources can look up a specific account's ID via `module.accounts.ids["company_name"]`.

### YAML File Example

For larger organizations, source the map from a YAML file instead of inlining it:

```yaml
# accounts.yaml
company_name:
  name: company_name
  email: jdoe@example.com
  parent_key: workloads
```

```
locals {
  accounts = yamldecode(file("${path.module}/accounts.yaml"))
}

module "accounts" {
  source                   = "github.com/zachreborn/terraform-modules//modules/aws/organizations/account"
  accounts                 = local.accounts
  organizational_unit_ids  = { workloads = "ou-abcd-11111111" }
}
```

### Cross-Module Composition with the OU Module

This module's `organizational_unit_ids` input is designed to accept [`modules/aws/organizations/ou`](../ou)'s `ids` output directly, so accounts can attach to OUs via `parent_key` instead of a hardcoded ID. Both modules' inputs can be sourced from a single YAML file with `organizational_units:` and `accounts:` top-level keys:

```yaml
# organization_structure.yaml
organizational_units:
  workloads:
    name: workloads
    parent_id: r-n1v2

accounts:
  company_name:
    name: company_name
    email: jdoe@example.com
    parent_key: workloads
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

Version 9 replaces the single-account `name`/`email`/`parent_id` inputs and singular `id`/`arn`/`tags_all` outputs with the map-based `accounts` input and keyed `ids`/`arns`/`tags_all` outputs described above. This ships alongside the equivalent [OU module](../ou) breaking change as a single `feat!:` commit (MAJOR version bump) per this repo's release-please conventions, because:
- The `name`, `email`, and `parent_id` variables no longer exist; all configuration moves into `accounts` map entries.
- The `id`, `arn`, and `tags_all` outputs are now `ids`, `arns`, and `tags_all` maps keyed by logical name instead of single values.
- A new `organizational_unit_ids` input was added to let `parent_key` resolve against the OU module's `ids` output.
- Within each `accounts` entry, `name` is optional and defaults to the entry's map key, so it can be omitted whenever it would just repeat the key; `email` remains required, since there is no reasonable default.

#### Step 1: Convert each module call into one map entry

Each existing `module "x_account" { name = ...; email = ...; parent_id = ... }` block becomes one entry in a single `accounts` map. Replace any `parent_id = module.<ou>.id` reference with `parent_key = "<ou_key>"` and pass that OU module's `ids` output as `organizational_unit_ids`.

For example, this:

```
module "company_name" {
  source    = "github.com/zachreborn/terraform-modules//modules/aws/organizations/account"
  name      = "company_name"
  email     = "jdoe@example.com"
  parent_id = module.prod_ou.id
}
```

becomes:

```
module "accounts" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/account"

  organizational_unit_ids = module.organizational_units.ids

  accounts = {
    company_name = {
      name       = "company_name"
      email      = "jdoe@example.com"
      parent_key = "prod"
    }
  }
}
```

#### Step 2: Move state instead of letting Terraform destroy/recreate

AWS refuses to delete a member account still in the organization, so a plain apply of the config above would fail: Terraform would want to destroy `module.company_name.aws_organizations_account.account` and create a new resource at a different address. Add a `moved` block per existing account to your **consumer** configuration (not this module) so Terraform reconciles state instead:

```
moved {
  from = module.company_name.aws_organizations_account.account
  to   = module.accounts.aws_organizations_account.this["company_name"]
}
```

This pattern is already used in downstream consumers (e.g. this repo's reference consumer keeps a `moved.tf` for module renames).

#### Step 3: Update downstream references

| Old reference | New reference |
|---|---|
| `module.company_name.id` | `module.accounts.ids["company_name"]` |
| `module.company_name.arn` | `module.accounts.arns["company_name"]` |
| `module.company_name.tags_all` | `module.accounts.tags_all["company_name"]` |

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
| [aws_organizations_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_accounts"></a> [accounts](#input\_accounts) | (Required) Map of AWS Organization member accounts to create, keyed by a caller-chosen logical name<br/>(e.g. "company\_name").<br/>Each entry must set exactly one of:<br/>  - parent\_id:  A literal parent Root or Organizational Unit ID.<br/>  - parent\_key: A key into var.organizational\_unit\_ids (e.g. the `ids` output of<br/>                modules/aws/organizations/ou) identifying the OU this account should be attached to.<br/>Bare/null entries (e.g. an empty `foo:` in YAML) are not supported here, unlike<br/>modules/aws/organizations/ou — there is no reasonable default for email, so every entry must at minimum<br/>set email.<br/>Fields:<br/>  - name:                       (Optional) A friendly name for the member account. Defaults to the<br/>                                 entry's map key when unset.<br/>  - email:                      (Required) The email address of the owner to assign to the new member<br/>                                 account. This email address must not already be associated with<br/>                                 another AWS account.<br/>  - parent\_id:                  (Optional) Literal parent Root or OU ID. Conflicts with parent\_key.<br/>  - parent\_key:                 (Optional) Key into var.organizational\_unit\_ids. Conflicts with parent\_id.<br/>  - iam\_user\_access\_to\_billing: (Optional) ALLOW or DENY. Defaults to ALLOW.<br/>  - role\_name:                  (Optional) Name of the IAM role Organizations preconfigures in the new<br/>                                 account. Defaults to OrganizationAccountAccessRole.<br/>  - close\_on\_deletion:          (Optional) If true, a deletion event will close the account. Defaults to false.<br/>  - tags:                       (Optional) Additional tags for this account, merged with var.tags. | <pre>map(object({<br/>    name                       = optional(string)<br/>    email                      = string<br/>    parent_id                  = optional(string)<br/>    parent_key                 = optional(string)<br/>    iam_user_access_to_billing = optional(string, "ALLOW")<br/>    role_name                  = optional(string, "OrganizationAccountAccessRole")<br/>    close_on_deletion          = optional(bool, false)<br/>    tags                       = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_organizational_unit_ids"></a> [organizational\_unit\_ids](#input\_organizational\_unit\_ids) | (Optional) Map of Organizational Unit IDs keyed by logical name, e.g. the `ids` output of modules/aws/organizations/ou. Referenced by each accounts entry's parent\_key. | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Key-value map of resource tags applied to every account, merged with each entry's optional per-account tags. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arns"></a> [arns](#output\_arns) | Map of AWS Organization account ARNs, keyed by the same keys as var.accounts. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of AWS Organization account IDs, keyed by the same keys as var.accounts. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | Map of the resolved tags for each account, keyed by the same keys as var.accounts. |
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
