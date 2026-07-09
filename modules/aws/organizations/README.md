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

<h3 align="center">AWS Organizations (Composed)</h3>
  <p align="center">
    This module composes the organization, ou, and account submodules so an entire AWS Organization's structure can be managed from one module call and one YAML file.
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

This module composes three independent, standalone submodules that live alongside it:
[`organization`](organization), [`ou`](ou), and [`account`](account). Each remains fully usable on its
own for partial adoption (e.g. an Organization managed by Control Tower, with only accounts vended by
this module). Use this composed module when you always want all three managed together from a single
set of inputs, as described in each submodule's own README.

Already calling `organization`, `ou`, and/or `account` directly? See [MIGRATION.md](MIGRATION.md) for
both available paths: keep the modules separate and update to their new map-based interfaces, or
consolidate into this composed module.

### Single YAML File Example

One YAML file with `organization:`, `organizational_units:`, and `accounts:` top-level keys drives all
three submodules. A bare OU entry (e.g. `workloads:` with nothing after it) is attached automatically to
the managed Organization's root; `name` on both OU and account entries defaults to the entry's map key.

```yaml
# organization_structure.yaml
organization:
  enabled_policy_types:
    - SERVICE_CONTROL_POLICY
    - TAG_POLICY

organizational_units:
  workloads:
  prod:
    parent_key: workloads
  staging:
    parent_key: workloads
  security:

accounts:
  company_ventures:
    email: jdoe@example.com
    parent_key: prod
  company_security:
    email: security@example.com
    parent_key: security
```

```
locals {
  org_structure = yamldecode(file("${path.module}/organization_structure.yaml"))
}

module "organizations" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations"

  organization          = try(local.org_structure.organization, null)
  organizational_units  = local.org_structure.organizational_units
  accounts              = local.org_structure.accounts
}
```

Look up a specific OU or account ID via `module.organizations.organizational_unit_ids["prod"]` or
`module.organizations.account_ids["company_ventures"]`.

### Inline Example (No YAML)

The same structure can be written directly in HCL instead of a YAML file:

```
module "organizations" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations"

  organization = {
    enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]
  }

  organizational_units = {
    workloads = {}
    prod = {
      parent_key = "workloads"
    }
  }

  accounts = {
    company_ventures = {
      email      = "jdoe@example.com"
      parent_key = "prod"
    }
  }
}
```

### Attaching to an Existing Organization

Leave `organization` unset (the default, `null`) if the Organization already exists and is managed
elsewhere. This module then creates no `aws_organizations_organization` resource, and every top-level
`organizational_units` entry must set an explicit `parent_id` (the automatic root-ID default requires a
managed `organization`):

```
module "organizations" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations"

  organizational_units = {
    workloads = {
      parent_id = "r-n1v2"
    }
  }

  accounts = {
    company_ventures = {
      email      = "jdoe@example.com"
      parent_key = "workloads"
    }
  }
}
```

### Full Example (All Options)

A "kitchen sink" reference showing every field available across `organization`, `organizational_units`,
and `accounts` in one YAML file. Most fields have sensible defaults and don't need to be set explicitly
— see the simpler examples above for the common case. This example intentionally sets every field so
you can see the full shape each submodule accepts; cross-reference field meanings in
[`organization/README.md`](organization/README.md), [`ou/README.md`](ou/README.md), and
[`account/README.md`](account/README.md).

```yaml
# organization_structure.yaml
organization:
  aws_service_access_principals:
    - access-analyzer.amazonaws.com
    - account.amazonaws.com
    - aws-artifact-account-sync.amazonaws.com
    - backup.amazonaws.com
    - cloudtrail.amazonaws.com
    - config.amazonaws.com
    - guardduty.amazonaws.com
    - health.amazonaws.com
    - inspector2.amazonaws.com
    - securityhub.amazonaws.com
    - sso.amazonaws.com
  enabled_policy_types:
    - SERVICE_CONTROL_POLICY
    - TAG_POLICY
    - BACKUP_POLICY
  feature_set: ALL
  enabled_features:
    - RootCredentialsManagement
    - RootSessions
  enable_identity_center_scp: true
  identity_center_scp_name: DenyMemberAccountIdentityCenter
  identity_center_scp_description: Denies sso:CreateInstance org-wide so member accounts cannot create account-level IAM Identity Center instances.
  attach_identity_center_scp: true
  identity_center_scp_target_ids:
    - r-n1v2
  enable_region_scp: true
  allowed_regions:
    - us-east-1
    - us-west-2
  region_scp_name: DenyAccessOutsideApprovedRegions
  region_scp_description: Denies regional AWS service actions outside the approved Regions, exempting global services.
  attach_region_scp: true
  region_scp_target_ids:
    - r-n1v2
  region_scp_exempted_principal_arns:
    - arn:aws:iam::*:role/AWSControlTowerExecution
    - arn:aws:iam::*:role/OrganizationAccountAccessRole
  region_scp_exempted_actions:
    - pricingplanmanager:*
  enable_organization_backup: true
  tags:
    terraform: "true"
    managed_by: platform-team

organizational_units:
  aws_infrastructure:
    name: aws_infrastructure
    parent_id: r-n1v2
    tags:
      purpose: infrastructure
  cybersecurity:
    name: cybersecurity
    parent_id: r-n1v2
  workloads:
    name: workloads
    parent_id: r-n1v2
  suspended:
    name: suspended
    parent_id: r-n1v2
  prod:
    name: prod
    parent_key: workloads
    tags:
      environment: prod
  staging:
    name: staging
    parent_key: workloads
    tags:
      environment: staging
  dev:
    name: dev
    parent_key: workloads
    tags:
      environment: dev

accounts:
  company_organization:
    name: company.organization
    email: jdoe+organization@example.com
    parent_key: aws_infrastructure
    iam_user_access_to_billing: ALLOW
    role_name: OrganizationAccountAccessRole
    close_on_deletion: false
    tags:
      purpose: management
  company_security:
    name: company.security
    email: jdoe+security@example.com
    parent_key: cybersecurity
    iam_user_access_to_billing: DENY
  company_ventures:
    name: company.ventures
    email: jdoe@company.ventures
    parent_key: prod
    close_on_deletion: true
    tags:
      environment: prod
      purpose: consulting-business
```

```
locals {
  org_structure = yamldecode(file("${path.module}/organization_structure.yaml"))
}

module "organizations" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations"

  organization          = try(local.org_structure.organization, null)
  organizational_units  = local.org_structure.organizational_units
  accounts              = local.org_structure.accounts

  # Module-wide default tags, merged with each organizational_units/accounts entry's own tags.
  tags = {
    terraform = "true"
  }
}
```

### Testing

This module, [`ou`](ou), and [`account`](account) each have native OpenTofu tests under their own
`tests/` directory, using `mock_provider "aws"` so they run without real AWS credentials, cost, or
cloud side effects. Run them per module:

```sh
tofu -chdir=modules/aws/organizations/ou init -backend=false
tofu -chdir=modules/aws/organizations/ou test

tofu -chdir=modules/aws/organizations/account init -backend=false
tofu -chdir=modules/aws/organizations/account test

tofu -chdir=modules/aws/organizations init -backend=false
tofu -chdir=modules/aws/organizations test
```

CI runs the same commands automatically for every module directory that has a `tests/` directory (see
`.github/workflows/test.yml`), so new test files are picked up with no additional wiring.

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

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_accounts"></a> [accounts](#module\_accounts) | ./account | n/a |
| <a name="module_organization"></a> [organization](#module\_organization) | ./organization | n/a |
| <a name="module_organizational_units"></a> [organizational\_units](#module\_organizational\_units) | ./ou | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_accounts"></a> [accounts](#input\_accounts) | (Optional) Map of AWS Organization member accounts to create, identical shape to<br/>modules/aws/organizations/account's accounts variable. organizational\_unit\_ids is wired<br/>automatically from the organizational\_units created by this same module call, so there is no<br/>separate organizational\_unit\_ids input here.<br/>Note: iam\_user\_access\_to\_billing has no default here either, for the same reason it has none in the<br/>account submodule -- see that module's variable description for details. | <pre>map(object({<br/>    name                       = optional(string)<br/>    email                      = string<br/>    parent_id                  = optional(string)<br/>    parent_key                 = optional(string)<br/>    iam_user_access_to_billing = optional(string)<br/>    role_name                  = optional(string, "OrganizationAccountAccessRole")<br/>    close_on_deletion          = optional(bool, false)<br/>    tags                       = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_organization"></a> [organization](#input\_organization) | (Optional) Configuration for the AWS Organization itself, passed through to the organization<br/>submodule (modules/aws/organizations/organization). Leave unset (the default, null) if the<br/>Organization already exists and is managed elsewhere -- this module then manages no<br/>aws\_organizations\_organization resource, and every organizational\_units entry must set an explicit<br/>parent\_id or parent\_key (the automatic root-ID default described on organizational\_units below<br/>requires organization to be set).<br/>Fields mirror modules/aws/organizations/organization's variables exactly; every field here is<br/>optional with no default of its own, so an unset field passes through as null and the organization<br/>submodule's own default takes over -- defaults stay single-sourced there. | <pre>object({<br/>    aws_service_access_principals                 = optional(list(string))<br/>    enabled_policy_types                          = optional(list(string))<br/>    feature_set                                   = optional(string)<br/>    enabled_features                              = optional(list(string))<br/>    enable_identity_center_scp                    = optional(bool)<br/>    identity_center_scp_name                      = optional(string)<br/>    identity_center_scp_description               = optional(string)<br/>    attach_identity_center_scp                    = optional(bool)<br/>    identity_center_scp_target_ids                = optional(list(string))<br/>    enable_region_scp                             = optional(bool)<br/>    allowed_regions                               = optional(list(string))<br/>    region_scp_name                               = optional(string)<br/>    region_scp_description                        = optional(string)<br/>    attach_region_scp                             = optional(bool)<br/>    region_scp_target_ids                         = optional(list(string))<br/>    region_scp_exempted_principal_arns            = optional(list(string))<br/>    region_scp_exempted_actions                   = optional(list(string))<br/>    enable_leave_organization_scp                 = optional(bool)<br/>    leave_organization_scp_name                   = optional(string)<br/>    leave_organization_scp_description            = optional(string)<br/>    attach_leave_organization_scp                 = optional(bool)<br/>    leave_organization_scp_target_ids             = optional(list(string))<br/>    enable_root_access_key_scp                    = optional(bool)<br/>    root_access_key_scp_name                      = optional(string)<br/>    root_access_key_scp_description               = optional(string)<br/>    attach_root_access_key_scp                    = optional(bool)<br/>    root_access_key_scp_target_ids                = optional(list(string))<br/>    enable_security_services_scp                  = optional(bool)<br/>    security_services_scp_name                    = optional(string)<br/>    security_services_scp_description             = optional(string)<br/>    attach_security_services_scp                  = optional(bool)<br/>    security_services_scp_target_ids              = optional(list(string))<br/>    security_services_scp_exempted_principal_arns = optional(list(string))<br/>    enable_root_actions_scp                       = optional(bool)<br/>    root_actions_scp_name                         = optional(string)<br/>    root_actions_scp_description                  = optional(string)<br/>    attach_root_actions_scp                       = optional(bool)<br/>    root_actions_scp_target_ids                   = optional(list(string))<br/>    root_actions_scp_exempted_actions             = optional(list(string))<br/>    enable_organization_backup                    = optional(bool)<br/>    tags                                          = optional(map(string))<br/>  })</pre> | `null` | no |
| <a name="input_organizational_units"></a> [organizational\_units](#input\_organizational\_units) | (Optional) Map of Organizational Units to create, identical shape to<br/>modules/aws/organizations/ou's organizational\_units variable (including support for bare/null<br/>entries and parent\_key nesting up to 4 levels). Any entry that sets neither parent\_id nor parent\_key<br/>is automatically attached to the managed Organization's root -- this requires var.organization to be<br/>set; otherwise such an entry fails validation in the ou submodule. | <pre>map(object({<br/>    name       = optional(string)<br/>    parent_id  = optional(string)<br/>    parent_key = optional(string)<br/>    tags       = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags applied to every Organizational Unit and Account created by this module, merged with each entry's optional per-resource tags. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_arns"></a> [account\_arns](#output\_account\_arns) | Map of AWS Organization account ARNs, keyed by the same keys as var.accounts. |
| <a name="output_account_ids"></a> [account\_ids](#output\_account\_ids) | Map of AWS Organization account IDs, keyed by the same keys as var.accounts. |
| <a name="output_account_tags_all"></a> [account\_tags\_all](#output\_account\_tags\_all) | Map of the resolved tags for each account, keyed by the same keys as var.accounts. |
| <a name="output_organization"></a> [organization](#output\_organization) | Full set of organization submodule outputs (id, arn, roots, master\_account\_id, SCP ids/arns, etc.), or null when var.organization was not set. |
| <a name="output_organizational_unit_accounts"></a> [organizational\_unit\_accounts](#output\_organizational\_unit\_accounts) | Map of the list of accounts in each Organizational Unit, keyed by the same keys as var.organizational\_units. |
| <a name="output_organizational_unit_arns"></a> [organizational\_unit\_arns](#output\_organizational\_unit\_arns) | Map of Organizational Unit ARNs, keyed by the same keys as var.organizational\_units. |
| <a name="output_organizational_unit_ids"></a> [organizational\_unit\_ids](#output\_organizational\_unit\_ids) | Map of Organizational Unit IDs, keyed by the same keys as var.organizational\_units. If an entry has neither parent\_id nor parent\_key and cannot default to an Organization root (var.organization not set), the nested ou module's own validation fails with a message explaining the fix. |
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
