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

<h3 align="center">AWS Resource Access Manager (RAM)</h3>
  <p align="center">
    This modules creates and configures RAM resources, allowing for existing resources to be shared with your organization or other AWS accounts.
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
    <li><a href="#migration">Migration</a></li>
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

This example shares a transit gateway with the current AWS organization. This allows all accounts in the organization to use the transit gateway and attach VPCs from other accounts.

```hcl
module "tgw_ram_share" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ram"

  name = "transit_tgw"
  resource_arns = {
    transit = module.transit_gateway.arn
  }
}
```

### Multi-Resource Example

This example shares two managed prefix lists in a single resource share, consolidating what would otherwise require two separate module calls.

```hcl
module "prefix_list_ram_share" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ram"

  name = "managed_prefix_lists"
  resource_arns = {
    app_connectors = module.zpa_app_connectors_prefix_list.arn
    switches       = module.cisco_switches_prefix_list.arn
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_
## Prerequisites

- Resources supported by AWS Resource Access Manager (RAM). They may be created
  in the same plan as this module.
- An AWS Organization with organization sharing enabled in RAM when using the
  default organization principal. Set `principal` to share with a specific
  account, organization, or organizational unit instead. The module always
  reads the current organization, so the provider needs permission to describe it.

## Notes / Design Decisions

- One module instance manages one resource share, with one association per
  `resource_arns` entry.
- `resource_arns` is a required `map(string)`. Keys are stable, caller-defined
  logical names that must be known at plan time; values are resource Amazon
  Resource Names (ARNs) and may remain unknown until apply. Do not derive keys
  from newly created resource identifiers or convert a list of unknown ARNs
  into a set for `for_each`.
- `resource_association_ids` uses the same logical keys. For example,
  `module.tgw_ram_share.resource_association_ids["transit"]` selects the transit
  gateway association. Changing a key changes its state address; use a `moved`
  block when renaming a key without changing the associated resource.
- Use each resource ARN only once per share. An empty map (`{}`) is allowed and
  creates a share with no resource associations.
- External principals remain disabled by default.

## Migration

This is a breaking change. The original required `resource_arn` string input
has been replaced by the `resource_arns` map. The association also moves from a
singleton state address to a logical-keyed address.

### From the original singleton input

Replace `resource_arn = module.transit_gateway.arn` with the map shown in the
simple example above. Before applying, add this block in the caller's
configuration, alongside the module block:

```hcl
moved {
  from = module.tgw_ram_share.aws_ram_resource_association.this
  to   = module.tgw_ram_share.aws_ram_resource_association.this["transit"]
}
```

Use your actual module address and the same key used in `resource_arns`.
No resource-share or principal-association move is needed. The module cannot
provide a universal move because the destination key is chosen by each caller.

### From the unreleased list-based implementation

If you already applied the list-based version of this change, convert each
list entry to a logical-keyed map entry and move each ARN-keyed association:

```hcl
moved {
  from = module.tgw_ram_share.aws_ram_resource_association.this["arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0"]
  to   = module.tgw_ram_share.aws_ram_resource_association.this["transit"]
}
```

Replace the example ARN with the exact key in your existing state. Update any
`resource_association_ids` lookups from ARN keys to logical keys as well.
Use only the migration matching your current state; do not add both moves for
the same association.

### Existing address-management module callers

The `modules/aws/ipam` module now passes a map keyed by the pool's logical name.
Its public inputs are unchanged. For an existing organization share of the
`primary` pool, migrate the nested singleton association from the root caller:

```hcl
moved {
  from = module.ipam.module.ram["primary-org"].aws_ram_resource_association.this
  to   = module.ipam.module.ram["primary-org"].aws_ram_resource_association.this["primary"]
}
```

Repeat for every existing share. For explicit-principal shares, use the existing
share key such as `"primary-0"` instead of `"primary-org"`. If you applied the
unreleased ARN-keyed version, use that keyed address as the source instead.

### Verify the migration

Run `tofu plan` (or `terraform plan`) before applying. With unchanged resources
and sharing settings, existing associations should be reported as moved, not
destroyed and recreated. Newly added resources will still create associations.
Stop and correct the addresses if the plan proposes replacing an existing
association. Keep the migration blocks until every consuming state has upgraded.
Terraform callers using `moved` blocks need Terraform 1.1 or later; all supported
OpenTofu versions support them.

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
| [aws_ram_principal_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association) | resource |
| [aws_ram_resource_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association) | resource |
| [aws_ram_resource_share.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share) | resource |
| [aws_organizations_organization.current_org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allow_external_principals"></a> [allow\_external\_principals](#input\_allow\_external\_principals) | Indicates whether principals outside your AWS organization can be associated with a resource share. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the resource share. | `string` | n/a | yes |
| <a name="input_permission_arns"></a> [permission\_arns](#input\_permission\_arns) | The ARNs of the permissions to associate with the resource share. | `list(string)` | `null` | no |
| <a name="input_principal"></a> [principal](#input\_principal) | The principal to associate with the resource share. | `string` | `null` | no |
| <a name="input_resource_arns"></a> [resource\_arns](#input\_resource\_arns) | Map of resource ARNs to associate with the resource share, keyed by stable logical names known at plan time. Values may be unknown until apply. | `map(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource share. | `map(string)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the resource share. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the resource share. |
| <a name="output_resource_association_ids"></a> [resource\_association\_ids](#output\_resource\_association\_ids) | Map of logical resource key to the ID of its aws\_ram\_resource\_association. |
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
