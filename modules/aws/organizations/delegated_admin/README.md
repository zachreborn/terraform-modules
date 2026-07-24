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

<h3 align="center">AWS Organization Delegated Admins Module</h3>
  <p align="center">
    This module generates and manages AWS organization delegated administrators. This delegates administrative functionality of a service to an account within an organization. This module takes a map of AWS account IDs and the service principal name to associate with the account. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com. See the [AWS Organizations documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html) for more information.
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

This module manages `aws_organizations_delegated_administrator` resources. It is keyed by a
caller-supplied **static logical name** (not the AWS account ID), which allows the `account_id`
value to be an apply-time-unknown reference (e.g. `module.organizations.account_ids["backups"]`)
without triggering `Invalid for_each argument`.

### Simple Example

Delegate AWS Backup administration to an existing account:

```hcl
module "delegated_admin" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/delegated_admin"

  delegated_admins = {
    backups = {
      account_id = "123456789012"
      services   = ["backup.amazonaws.com"]
    }
  }
}
```

### New Account in the Same Apply

The primary motivation for the static-key design: `account_id` may be an apply-time-unknown
value from a concurrently created account without causing a plan-time error:

```hcl
module "organizations" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations"

  # ... organization, organizational_units, accounts ...
  accounts = {
    backups = {
      email      = "backups@example.com"
      parent_key = "aws_infrastructure"
    }
  }
}

module "delegated_admin" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/delegated_admin"

  delegated_admins = {
    # Map key is the static logical name "backups" — known at plan time.
    # account_id is the apply-time-unknown account ID — used only as a value.
    backups = {
      account_id = module.organizations.account_ids["backups"]
      services   = ["backup.amazonaws.com"]
    }
  }
}
```

### Multiple Accounts and Services

```hcl
module "delegated_admin" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/delegated_admin"

  delegated_admins = {
    backups = {
      account_id = module.organizations.account_ids["backups"]
      services   = ["backup.amazonaws.com"]
    }
    security = {
      account_id = module.organizations.account_ids["security"]
      services   = [
        "guardduty.amazonaws.com",
        "securityhub.amazonaws.com",
        "inspector2.amazonaws.com",
      ]
    }
  }
}
```

### Resolving Account IDs from a Sibling Map (`account_key`)

Each entry may set `account_key` instead of `account_id`, resolving the account ID from `var.account_ids`
(e.g. the `ids` output of [`modules/aws/organizations/account`](../account)). This is how the composed
[`modules/aws/organizations`](..) module wires `delegated_admins` entries directly to accounts created
by its own `accounts` input, without requiring a separate, external module block:

```hcl
module "accounts" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/account"

  accounts = {
    backups = {
      email     = "backups@example.com"
      parent_id = "r-abcd1234"
    }
  }
}

module "delegated_admin" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/delegated_admin"

  account_ids = module.accounts.ids

  delegated_admins = {
    backups = {
      account_key = "backups" # resolved against module.accounts.ids["backups"]
      services    = ["backup.amazonaws.com"]
    }
  }
}
```

An `account_key` that doesn't match any key in `var.account_ids` fails with a clear
`precondition`-driven error rather than a generic provider error.

## Migration from the Previous Interface

The `delegated_admins` variable changed from `map(list(string))` keyed by AWS account ID to
`map(object({ account_id, services }))` keyed by a static logical name. This is a **breaking
change** — callers must update their configuration.

### Configuration update

```hcl
# Before (old interface — account ID as map key)
delegated_admins = {
  (module.organizations.account_ids["backups"]) = ["backup.amazonaws.com"]
}

# After (new interface — static logical name as map key)
delegated_admins = {
  backups = {
    account_id = module.organizations.account_ids["backups"]
    services   = ["backup.amazonaws.com"]
  }
}
```

### Avoiding destroy+recreate with `moved` blocks

Because the resource instance keys change from `"<account_id>-<service>"` to
`"<logical_key>-<service>"`, OpenTofu/Terraform will plan destroy+recreate of every managed
delegated-administrator registration unless you add `moved` blocks. Because
`aws_organizations_delegated_administrator` registration is idempotent on
`(account_id, service_principal)`, adding `moved` blocks is strongly recommended to avoid
needless churn:

```hcl
# Example: account 123456789012 was previously registered for backup.amazonaws.com.
# The old resource key was "123456789012-backup.amazonaws.com";
# the new key is "backups-backup.amazonaws.com".
moved {
  from = module.delegated_admin.aws_organizations_delegated_administrator.this["123456789012-backup.amazonaws.com"]
  to   = module.delegated_admin.aws_organizations_delegated_administrator.this["backups-backup.amazonaws.com"]
}
```

Alternatively, use `tofu state mv` (or `terraform state mv`) to rename the resource in state
before applying, which avoids the need for `moved` blocks in configuration.

## Notes / Design Decisions

- **Static map keys are required.** The map key must be a string literal, `local` value, or other
  plan-time-known expression. Using a resource attribute (e.g. an account ID output) as a map key
  causes `Invalid for_each argument` if that value is unknown at plan time.

- **`account_id` is a value, not a key.** Moving `account_id` from the map key to an object
  attribute is the sole purpose of this interface. It allows the account ID to be supplied from a
  concurrently-created `aws_organizations_account` in the same plan/apply without splitting work
  across two applies.

- **Instance key format.** The `for_each` key for each resource instance is
  `"<logical_key>-<service_principal>"` (e.g. `"backups-backup.amazonaws.com"`). Output maps use
  this same key so outputs are easy to cross-reference with inputs.

- **No tags.** `aws_organizations_delegated_administrator` does not accept a `tags` argument, so
  this module has no tagging support.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.56.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_organizations_delegated_administrator.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_ids"></a> [account\_ids](#input\_account\_ids) | (Optional) Map of AWS account IDs keyed by logical name, e.g. the `ids` output of modules/aws/organizations/account. Referenced by each delegated\_admins entry's account\_key. | `map(string)` | `{}` | no |
| <a name="input_delegated_admins"></a> [delegated\_admins](#input\_delegated\_admins) | (Optional) Map of delegated administrator configurations keyed by a caller-supplied static logical<br/>name (e.g. "backups", "security"). The map key must be known at plan time — a string literal or<br/>local value, never a resource attribute such as an AWS account ID — so the resource for\_each key<br/>remains resolvable even when the resolved account ID is an apply-time-unknown value.<br/><br/>Each entry must set exactly one of:<br/>  - account\_id:  A literal AWS account ID to register as a delegated administrator. May be an<br/>                 apply-time value such as module.organizations.account\_ids["backups"]; it is<br/>                 passed only as a resource argument value, never used as a for\_each key.<br/>  - account\_key: A key into var.account\_ids (e.g. the `ids` output of<br/>                 modules/aws/organizations/account), letting a caller resolve the account ID from a<br/>                 sibling map instead of hard-coding or wiring it in from an outer module block.<br/>Fields:<br/>  - account\_id:  (Optional) Literal AWS account ID. Conflicts with account\_key.<br/>  - account\_key: (Optional) Key into var.account\_ids. Conflicts with account\_id.<br/>  - services:    (Required) Non-empty list of service principal names to associate with the account<br/>                 (e.g. ["backup.amazonaws.com", "config.amazonaws.com"]).<br/><br/>Example:<br/>  delegated\_admins = {<br/>    backups = {<br/>      account\_id = module.organizations.account\_ids["backups"]<br/>      services   = ["backup.amazonaws.com"]<br/>    }<br/>    security = {<br/>      account\_key = "security"<br/>      services    = ["guardduty.amazonaws.com", "securityhub.amazonaws.com"]<br/>    }<br/>  } | <pre>map(object({<br/>    account_id  = optional(string)<br/>    account_key = optional(string)<br/>    services    = list(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_delegated_administrator_ids"></a> [delegated\_administrator\_ids](#output\_delegated\_administrator\_ids) | Map of delegated administrator instance IDs keyed by '<logical\_key>-<service\_principal>' (e.g. 'backups-backup.amazonaws.com'). Each value is the resource ID in the form '<account\_id>/<service\_principal>'. |
| <a name="output_delegated_administrators"></a> [delegated\_administrators](#output\_delegated\_administrators) | Map of full delegated administrator resource objects keyed by '<logical\_key>-<service\_principal>'. Each object exposes account\_id, service\_principal, arn, name, email, status, joined\_method, joined\_timestamp, and delegation\_enabled\_date. |
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
