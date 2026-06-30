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

<h3 align="center">AWS VPC IP Address Manager (IPAM)</h3>
  <p align="center">
    This module provisions an AWS VPC IPAM instance, scopes, and hierarchical pools to centrally plan, allocate, and monitor IP address space across an AWS Organization and all of its regions. It optionally registers the IPAM delegated administrator and shares pools across the organization by composing the RAM module.
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

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

A single top-level IPv4 pool with a provisioned CIDR in the default private scope.

```hcl
module "ipam" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ipam"

  name              = "org-ipam"
  operating_regions = ["us-east-1"]

  pools = {
    primary = {
      address_family    = "ipv4"
      locale            = "us-east-1"
      provisioned_cidrs = ["10.0.0.0/8"]
    }
  }
}
```

### Hierarchical Pools with Organization Sharing

A three-level hierarchy (global -> regional -> environment), shared with the
entire AWS Organization via RAM, with the IPAM delegated administrator
registered. Apply this from the Organization management account.

```hcl
module "ipam" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ipam"

  name              = "org-ipam"
  operating_regions = ["us-east-1", "us-west-2"]

  pools = {
    global = {
      address_family    = "ipv4"
      description        = "Top-level global pool"
      provisioned_cidrs = ["10.0.0.0/8"]
    }
    region_use1 = {
      address_family                    = "ipv4"
      parent_pool_key                   = "global"
      locale                            = "us-east-1"
      provisioned_cidrs                 = ["10.0.0.0/12"]
      allocation_default_netmask_length = 16
    }
    prod_use1 = {
      address_family    = "ipv4"
      parent_pool_key   = "region_use1"
      locale            = "us-east-1"
      provisioned_cidrs = ["10.0.0.0/16"]
    }
  }

  # Register the IPAM delegated administrator (run from the management account).
  delegated_admin_account_id = "123456789012"

  # Share the regional pool with the entire organization.
  share_with_organization = true
  ram_share_pool_keys     = ["region_use1"]
}
```

### Sourcing a VPC CIDR from an IPAM Pool

The `modules/aws/vpc` module can source its IPv4 CIDR directly from an IPAM pool
instead of a static `vpc_cidr`.

```hcl
module "vpc" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/vpc"

  name                = "app-vpc"
  ipv4_ipam_pool_id   = module.ipam.pool_ids["prod_use1"]
  ipv4_netmask_length = 24
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- An AWS account. For organization-wide features (cross-region pools, delegated
  administration, and org-wide RAM sharing) an AWS Organization with all
  features enabled is required, and the `tier` must be `advanced` (the default).
- To register the IPAM delegated administrator (`delegated_admin_account_id`),
  the configuration must be applied from the **Organization management account**.
- To share pools with the entire organization (`share_with_organization = true`),
  resource sharing with AWS Organizations must be enabled in RAM.
- This module composes the [`modules/aws/ram`](../ram) module for sharing; no RAM
  resources are declared inline.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **Hierarchical pools are created in depth tiers.** A child pool references its
  parent's ID via `source_ipam_pool_id`. Because OpenTofu/Terraform reject a
  single `for_each` resource that references another instance of itself as a
  dependency cycle, pools are split internally into `level_0`, `level_1`, and
  `level_2` resources keyed off each pool's `parent_pool_key`. The public
  interface remains a single scalable `pools` map, and outputs (`pool_ids`,
  `pool_arns`, `pool_cidrs`) are merged across tiers. As a result, pool nesting
  is supported up to **three levels** (a pool, its parent, and its grandparent);
  this is validated on the `pools` input.
- **`advanced` tier by default.** The advanced tier is required for the
  cross-region and AWS Organizations features that make org-wide IPAM useful.
  Set `tier = "free"` for single-region, single-account usage.
- **Default scopes always exist.** Every IPAM is created with a default private
  and public scope; their IDs are exposed as `private_scope_id` /
  `public_scope_id`. Reference them from a pool with `scope_key = "private"`
  (the default) or `scope_key = "public"`. Additional private scopes can be
  created via `additional_private_scopes` and referenced by their key.
- **`cascade` defaults to `false`** on the IPAM and on pools to protect against
  accidental deletion of pools and allocations.
- **RAM sharing via composition.** Sharing is performed by calling the
  `modules/aws/ram` module once per shared pool (and per principal when not
  sharing org-wide), keeping cross-cutting RAM concerns consistent with the rest
  of the library. Pool ARNs are also exposed via `pool_arns` for callers who
  prefer to manage sharing externally.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ram"></a> [ram](#module\_ram) | ../ram | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_vpc_ipam.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipam) | resource |
| [aws_vpc_ipam_organization_admin_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipam_organization_admin_account) | resource |
| [aws_vpc_ipam_pool.level_0](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipam_pool) | resource |
| [aws_vpc_ipam_pool.level_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipam_pool) | resource |
| [aws_vpc_ipam_pool.level_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipam_pool) | resource |
| [aws_vpc_ipam_pool_cidr.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipam_pool_cidr) | resource |
| [aws_vpc_ipam_pool_cidr_allocation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipam_pool_cidr_allocation) | resource |
| [aws_vpc_ipam_scope.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipam_scope) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_private_scopes"></a> [additional\_private\_scopes](#input\_additional\_private\_scopes) | (Optional) Additional private scopes to create, keyed by logical name. Reference a scope from a pool via its key in `scope_key`. | <pre>map(object({<br/>    description = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_allocations"></a> [allocations](#input\_allocations) | (Optional) Reserved/static CIDR allocations from a pool, keyed by logical name. Fields:<br/>  - pool\_key:         Logical key of the pool to allocate from (required).<br/>  - cidr:             A specific CIDR to allocate. Conflicts with netmask\_length.<br/>  - netmask\_length:   Netmask length to allocate from the pool. Conflicts with cidr.<br/>  - description:      Description of the allocation.<br/>  - disallowed\_cidrs: CIDRs that should not be allocated from when using netmask\_length.<br/>  - tags:             Tags for the allocation. | <pre>map(object({<br/>    pool_key         = string<br/>    cidr             = optional(string)<br/>    netmask_length   = optional(number)<br/>    description      = optional(string)<br/>    disallowed_cidrs = optional(list(string))<br/>    tags             = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_cascade"></a> [cascade](#input\_cascade) | (Optional) Enables you to quickly delete an IPAM, its scopes, pools, and any allocations in the pools. Defaults to false to protect against accidental deletion. | `bool` | `false` | no |
| <a name="input_delegated_admin_account_id"></a> [delegated\_admin\_account\_id](#input\_delegated\_admin\_account\_id) | (Optional) When set, registers the given account ID as the IPAM delegated administrator for the AWS Organization. Must be applied from the Organization management account. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional) A description for the IPAM. | `string` | `null` | no |
| <a name="input_enable_private_default_scope"></a> [enable\_private\_default\_scope](#input\_enable\_private\_default\_scope) | (Optional) Whether the default private scope is available for pools to reference via `scope_key = "private"`. The default private scope always exists on the IPAM; this gate only controls module-side resolution. | `bool` | `true` | no |
| <a name="input_enable_private_gua"></a> [enable\_private\_gua](#input\_enable\_private\_gua) | (Optional) Enable this option to use your own GUA ranges as private IPv6 addresses. Defaults to the provider default when null. | `bool` | `null` | no |
| <a name="input_enable_public_default_scope"></a> [enable\_public\_default\_scope](#input\_enable\_public\_default\_scope) | (Optional) Whether the default public scope is available for pools to reference via `scope_key = "public"`. The default public scope always exists on the IPAM; this gate only controls module-side resolution. | `bool` | `true` | no |
| <a name="input_metered_account"></a> [metered\_account](#input\_metered\_account) | (Optional) The AWS account that is charged for active IP addresses managed in the IPAM. Valid values are `ipam-owner` and `resource-owner`. Defaults to the provider default when null. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Name for the IPAM. Used as the tag `Name` value and as a prefix for pool, scope, and RAM share names. | `string` | n/a | yes |
| <a name="input_operating_regions"></a> [operating\_regions](#input\_operating\_regions) | (Required) Determines which regions the IPAM is enabled to operate in. The region in which the IPAM is created must be included. Each entry is an AWS region name (e.g. us-east-1). | `list(string)` | n/a | yes |
| <a name="input_pools"></a> [pools](#input\_pools) | (Optional) Map of IPAM pools keyed by logical name. Pools may be nested up to three levels deep<br/>(a pool, its parent, and its grandparent) by setting `parent_pool_key` to another pool's key.<br/>Fields:<br/>  - address\_family:                    "ipv4" or "ipv6".<br/>  - scope\_key:                         Scope to create the pool in: "private", "public", or an additional scope key. Defaults to "private".<br/>  - parent\_pool\_key:                   Logical key of the parent pool for hierarchical pools.<br/>  - locale:                            The region the pool is scoped to. Required for pools that allocate CIDRs to VPCs.<br/>  - description:                       Description of the pool.<br/>  - provisioned\_cidrs:                 CIDRs to provision into the pool.<br/>  - allocation\_default\_netmask\_length: Default netmask length for allocations from this pool.<br/>  - allocation\_min\_netmask\_length:     Minimum netmask length for allocations from this pool.<br/>  - allocation\_max\_netmask\_length:     Maximum netmask length for allocations from this pool.<br/>  - auto\_import:                       Whether to auto-import discovered resources into the pool.<br/>  - publicly\_advertisable:             For public-scope IPv6 pools only.<br/>  - aws\_service:                       Limits the pool to a specific AWS service (e.g. "ec2") for public IPv6 pools.<br/>  - public\_ip\_source:                  For public IPv4 pools: "amazon" or "byoip".<br/>  - cascade:                           Enables deletion of the pool and its allocations.<br/>  - allocation\_resource\_tags:          Tags required on resources to allocate from this pool.<br/>  - tags:                              Additional tags for the pool. | <pre>map(object({<br/>    address_family                    = string<br/>    scope_key                         = optional(string)<br/>    parent_pool_key                   = optional(string)<br/>    locale                            = optional(string)<br/>    description                       = optional(string)<br/>    provisioned_cidrs                 = optional(list(string), [])<br/>    allocation_default_netmask_length = optional(number)<br/>    allocation_min_netmask_length     = optional(number)<br/>    allocation_max_netmask_length     = optional(number)<br/>    auto_import                       = optional(bool, false)<br/>    publicly_advertisable             = optional(bool)<br/>    aws_service                       = optional(string)<br/>    public_ip_source                  = optional(string)<br/>    cascade                           = optional(bool, false)<br/>    allocation_resource_tags          = optional(map(string), {})<br/>    tags                              = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | (Optional) Specific principals (account IDs or Organization/OU ARNs) to RAM-share pools with when `share_with_organization` is false. | `list(string)` | `[]` | no |
| <a name="input_ram_share_pool_keys"></a> [ram\_share\_pool\_keys](#input\_ram\_share\_pool\_keys) | (Optional) Logical keys of the pools to share via RAM. Sharing is performed by composing the `modules/aws/ram` module; no RAM resources are declared inline. | `list(string)` | `[]` | no |
| <a name="input_share_with_organization"></a> [share\_with\_organization](#input\_share\_with\_organization) | (Optional) When true, pools listed in `ram_share_pool_keys` are RAM-shared with the entire AWS Organization. When false, sharing targets the principals in `ram_principals`. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the IPAM and its child resources. A `Name` tag is merged in automatically. | `map(string)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_tier"></a> [tier](#input\_tier) | (Optional) IPAM tier. Valid values are `free` and `advanced`. The `advanced` tier is required for cross-region and AWS Organizations features. | `string` | `"advanced"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_allocation_cidrs"></a> [allocation\_cidrs](#output\_allocation\_cidrs) | Map of allocation key to the allocated CIDR block, suitable for feeding into the VPC module. |
| <a name="output_ipam_arn"></a> [ipam\_arn](#output\_ipam\_arn) | The ARN of the IPAM. |
| <a name="output_ipam_id"></a> [ipam\_id](#output\_ipam\_id) | The ID of the IPAM. |
| <a name="output_pool_arns"></a> [pool\_arns](#output\_pool\_arns) | Map of pool key to pool ARN across all hierarchy levels. |
| <a name="output_pool_cidrs"></a> [pool\_cidrs](#output\_pool\_cidrs) | Map of pool key to the list of CIDR(s) provisioned into that pool. |
| <a name="output_pool_ids"></a> [pool\_ids](#output\_pool\_ids) | Map of pool key to pool ID across all hierarchy levels. |
| <a name="output_private_scope_id"></a> [private\_scope\_id](#output\_private\_scope\_id) | The ID of the IPAM's default private scope. |
| <a name="output_public_scope_id"></a> [public\_scope\_id](#output\_public\_scope\_id) | The ID of the IPAM's default public scope. |
| <a name="output_ram_share_arns"></a> [ram\_share\_arns](#output\_ram\_share\_arns) | Map of RAM share key to the RAM resource-share ARN (populated when sharing is enabled). |
| <a name="output_scope_ids"></a> [scope\_ids](#output\_scope\_ids) | Map of additional private scope keys to their scope IDs. |
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
