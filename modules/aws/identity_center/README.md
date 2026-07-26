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

<h3 align="center">Identity Center User</h3>
  <p align="center">
    This module creates one or more users and groups in AWS Identity Center (formerly AWS SSO). These users are then attached to groups in order to provide access to AWS accounts or applications.
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

## Prerequisites

- AWS Identity Center (IAM Identity Center) must be **enabled** in your AWS organization's management account before applying this module. The `data.aws_ssoadmin_instances` data source will fail if Identity Center is not yet configured.
- This module is intended for **manual** user/group management. If you use an external IdP (Okta, Entra ID, etc.) for SSO, users and groups will be managed by the IdP sync — use this module only if you are managing identities directly in Identity Center.

## Usage

### Simple Example

This example creates users and groups managed by Terraform and assigns a user to the `admins` group. Note: we recommend using an external IdP for production environments; this module offers a way to get started quickly with Identity Center without one.

```hcl
module "identity_center" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/identity_center"

  groups = {
    "admins" = {
      display_name = "admins"
      description  = "Admins from my domains"
    },
    "terraform" = {
      display_name = "terraform"
      # description is optional — omit to use the provider default (no description)
    }
  }

  users = {
    "Zachary Hill" = {
      given_name       = "Zachary"
      family_name      = "Hill"
      user_name        = "zhill@zacharyhill.co"
      email            = "zhill@zacharyhill.co"
      email_is_primary = true
      email_type       = "work"
      groups           = ["admins"]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

### Composed Usage: Permission Sets

This module can also create and wire [`modules/aws/identity_center/permission_set`](permission_set) instances via the optional `permission_sets` input, following the same parent/child composition pattern as [`modules/aws/organizations`](../organizations). A `permission_sets` entry can reference a group up to three ways, and may combine them:

- `groups`: pre-existing group display names, resolved by the `permission_set` submodule's own data source lookup (matched against `group_attribute_path`, forwarded straight through -- defaults to `"DisplayName"`).
- `group_ids`: pre-resolved group IDs, forwarded straight to the submodule -- use this for a group managed elsewhere (a different module, a different apply, or a raw resource outside this module call) whose ID you already have.
- `group_keys`: keys into this same module call's own `groups` map, resolved directly from the group resource this module creates (a resource attribute, never a data source lookup). This is what lets a brand-new group and its permission set be created together in a single apply, without the plan-time `GetGroupId` / `ResourceNotFoundException` failure described in [issue #456](https://github.com/zachreborn/terraform-modules/issues/456).

If the same logical group is reachable through more than one of these on the same entry, `group_keys` wins over an overlapping `group_ids` key, which in turn is resolved ahead of a name-based `groups` lookup for that key.

```hcl
module "identity_center" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/identity_center"

  groups = {
    "admins" = {
      display_name = "admins"
    }
  }

  users = {
    "Zachary Hill" = {
      given_name  = "Zachary"
      family_name = "Hill"
      user_name   = "zhill@zacharyhill.co"
      groups      = ["admins"]
    }
  }

  permission_sets = {
    admins = {
      description = "Full administrator access"
      # group_keys references the "admins" group above -- created and assigned in one apply.
      group_keys          = ["admins"]
      managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
      target_accounts = [
        module.organization.id
      ]
    }
  }
}
```

### YAML File Input

Every input to this module (`groups`, `users`, `permission_sets`) is a plain, YAML-serializable map, so a caller can drive the whole module from one YAML file, mirroring the pattern documented in [`modules/aws/organizations`](../organizations)'s README:

```yaml
# identity_center.yaml
groups:
  admins:
    display_name: admins

users:
  Zachary Hill:
    given_name: Zachary
    family_name: Hill
    user_name: zhill@zacharyhill.co
    groups:
      - admins

permission_sets:
  admins:
    description: Full administrator access
    group_keys:
      - admins
    managed_policy_arns:
      - arn:aws:iam::aws:policy/AdministratorAccess
    target_accounts:
      - "123456789012"
```

```hcl
locals {
  identity_center_config = yamldecode(file("${path.module}/identity_center.yaml"))
}

module "identity_center" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/identity_center"

  groups          = local.identity_center_config.groups
  users           = local.identity_center_config.users
  permission_sets = try(local.identity_center_config.permission_sets, {})
}
```

## Notes / Design Decisions

### Group membership interface

User-to-group assignment is expressed **per-user** via the optional `users[*].groups` list. Each entry must exactly match a key in `var.groups`. The module flattens these lists into `aws_identitystore_group_membership` resources internally and surfaces the results via the `group_memberships` output.

This user-centric approach means:
- Adding a user to a group is done by editing the user's `groups` list, not a separate membership block.
- A user with no `groups` value is still created; it simply has no memberships.
- The `group_memberships` output is keyed by `"<user_display_name>-<group_name>"` and exposes `membership_id`, `member` (user ID), and `group` (group ID) for downstream reference (e.g. audit tooling or permission-set modules).

### `groups.description` is optional

The underlying `aws_identitystore_group` resource treats `description` as optional. The module now reflects that — omitting it causes the provider to leave the description unset rather than requiring callers to pass an empty string.

### `permission_set`'s `assignment_ids` output key changed (breaking)

As part of adding the `permission_sets` composition above, the `permission_set` submodule's `assignment_ids` output is now keyed by `"<group_name>_<account_id>"` (the same key already used by its underlying `for_each`) instead of `"<principal_id>_<account_id>"` (parsed from the assignment resource's own runtime `id`). The old derivation could produce a duplicate-map-key error in the (rare) case of two assignments resolving to the same parsed key, and made native `tofu test` coverage of multiple assignments impossible, since mocked resource attributes are not unique per instance. If you index `permission_set`'s `assignment_ids` output by the old `<principal_id>_<account_id>` shape, update those references to the new `<group_name>_<account_id>` key before upgrading.

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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_permission_sets"></a> [permission\_sets](#module\_permission\_sets) | ./permission_set | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_identitystore_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group) | resource |
| [aws_identitystore_group_membership.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_group_membership) | resource |
| [aws_identitystore_user.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/identitystore_user) | resource |
| [aws_ssoadmin_instances.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_groups"></a> [groups](#input\_groups) | (Required) The list of groups to create. | <pre>map(object({<br/>    display_name = string           # (Required) The friendly name to identify the group.<br/>    description  = optional(string) # (Optional) The description of the group.<br/>  }))</pre> | n/a | yes |
| <a name="input_permission_sets"></a> [permission\_sets](#input\_permission\_sets) | (Optional) Map of AWS Identity Center permission sets to create, keyed by a caller-chosen logical<br/>name (e.g. "admins"). Each entry is wired to the modules/aws/identity\_center/permission\_set<br/>submodule -- see that submodule's README for the full field reference. Group associations can be<br/>expressed three ways, all of which may be combined on the same entry:<br/>  - groups:               Pre-existing group display names, resolved via the permission\_set<br/>                           submodule's own aws\_identitystore\_group data source (its<br/>                           group\_attribute\_path input, forwarded below, controls which attribute<br/>                           is matched). Use this for groups that are not managed by this same<br/>                           identity\_center module call.<br/>  - group\_ids:            Pre-resolved Identity Store group IDs, forwarded directly to the<br/>                           permission\_set submodule's own group\_ids input. Use this for a group<br/>                           managed elsewhere (e.g. a different module or apply) whose ID you<br/>                           already have -- including one created in this same apply by a resource<br/>                           outside this module call.<br/>  - group\_keys:           Keys into this module's own var.groups map. Resolved directly from the<br/>                           group resource created by this same module call (a resource attribute,<br/>                           never a data source lookup), so a brand-new group and its permission set<br/>                           can be created together in a single apply -- this is the fix for the<br/>                           eager-lookup failure described in issue #456. Every entry must exist in<br/>                           var.groups.<br/>If the same logical group is resolvable through more than one of the above, group\_keys takes<br/>precedence over a literal group\_ids entry for that same key, which in turn is resolved by the<br/>permission\_set submodule ahead of any name-based groups lookup for that key (matching that<br/>submodule's own groups/group\_ids precedence).<br/>A permission set with no group associations at all (policy-only) is a legitimate configuration and<br/>is not rejected, matching the permission\_set submodule's own behavior. | <pre>map(object({<br/>    name                             = optional(string)                # (Optional) Defaults to the map key when unset.<br/>    description                      = optional(string)                # (Optional) The description of the permission set.<br/>    groups                           = optional(set(string), [])       # (Optional) Pre-existing group display names.<br/>    group_ids                        = optional(map(string), {})       # (Optional) Pre-resolved group IDs for externally managed groups.<br/>    group_keys                       = optional(set(string), [])       # (Optional) Keys into this module's own var.groups.<br/>    group_attribute_path             = optional(string, "DisplayName") # (Optional) Forwarded to the permission_set submodule's own group_attribute_path.<br/>    customer_managed_iam_policy_name = optional(string)                # (Optional) See permission_set submodule.<br/>    customer_managed_iam_policy_path = optional(string, "/")           # (Optional) See permission_set submodule.<br/>    inline_policy                    = optional(string)                # (Optional) See permission_set submodule.<br/>    managed_policy_arns              = optional(list(string), [])      # (Optional) See permission_set submodule.<br/>    relay_state                      = optional(string)                # (Optional) See permission_set submodule.<br/>    session_duration                 = optional(string, "PT1H")        # (Optional) See permission_set submodule.<br/>    target_accounts                  = set(string)                     # (Required) AWS account IDs to assign the permission set to.<br/>    tags                             = optional(map(string), {})       # (Optional) Additional tags for this permission set.<br/>  }))</pre> | `{}` | no |
| <a name="input_users"></a> [users](#input\_users) | (Required) The list of users to create. | <pre>map(object({<br/>    given_name  = string # (Required) The given name of the user.<br/>    family_name = string # (Required) The family name of the user.<br/>    user_name   = string # (Required) The username of the user.<br/><br/>    honorific_prefix = optional(string) # (Optional) The honorific prefix of the user.<br/>    honorific_suffix = optional(string) # (Optional) The honorific suffix of the user.<br/>    middle_name      = optional(string) # (Optional) The middle name of the user.<br/>    nickname         = optional(string) # (Optional) The nickname of the user.<br/><br/>    email                   = optional(string) # (Optional) The email address of the user.<br/>    email_is_primary        = optional(bool)   # (Optional) Indicates whether the email address is the primary email address of the user.<br/>    email_type              = optional(string) # (Optional) The type of the email address of the user.<br/>    phone_number            = optional(string) # (Optional) The phone number of the user.<br/>    phone_number_is_primary = optional(bool)   # (Optional) Indicates whether the phone number is the primary phone number of the user.<br/>    phone_number_type       = optional(string) # (Optional) The type of the phone number of the user.<br/><br/>    preferred_language = optional(string) # (Optional) The user's preferred language.<br/>    timezone           = optional(string) # (Optional) The user's time zone.<br/>    title              = optional(string) # (Optional) The user's title.<br/>    user_type          = optional(string) # (Optional) The type of the user.<br/><br/>    groups = optional(list(string)) # (Optional) The list of groups the user belongs to.<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_group_ids"></a> [group\_ids](#output\_group\_ids) | The IDs of the groups in the identity store |
| <a name="output_group_memberships"></a> [group\_memberships](#output\_group\_memberships) | The group memberships created in the identity store, keyed by '<user\_display\_name>-<group\_name>' |
| <a name="output_permission_set_arns"></a> [permission\_set\_arns](#output\_permission\_set\_arns) | Map of permission set ARNs, keyed by the same keys as var.permission\_sets. |
| <a name="output_permission_set_assignment_ids"></a> [permission\_set\_assignment\_ids](#output\_permission\_set\_assignment\_ids) | Map of each permission set's own assignment\_ids output (account-assignment IDs and parsed fields), keyed by the same keys as var.permission\_sets. |
| <a name="output_permission_set_created_dates"></a> [permission\_set\_created\_dates](#output\_permission\_set\_created\_dates) | Map of the date each permission set was created, keyed by the same keys as var.permission\_sets. |
| <a name="output_permission_set_group_ids"></a> [permission\_set\_group\_ids](#output\_permission\_set\_group\_ids) | Map of each permission set's own effective resolved group-name to group-ID map, keyed by the same keys as var.permission\_sets. |
| <a name="output_permission_set_ids"></a> [permission\_set\_ids](#output\_permission\_set\_ids) | Map of permission set IDs, keyed by the same keys as var.permission\_sets. |
| <a name="output_permission_set_resolved_group_keys"></a> [permission\_set\_resolved\_group\_keys](#output\_permission\_set\_resolved\_group\_keys) | Map of permission\_sets[*].group\_keys resolved directly against this module's own group resources, independent of the permission\_set submodule call -- keyed by the same keys as var.permission\_sets, each value a map of group\_key to resolved group ID. Useful for confirming which of this module's own groups feed a given permission set before/without inspecting the submodule's own outputs. |
| <a name="output_user_ids"></a> [user\_ids](#output\_user\_ids) | The IDs of the users in the identity store |
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
