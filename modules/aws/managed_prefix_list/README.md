<!-- Blank module readme template: Do a search and replace with your text editor for the following: `managed_prefix_list`, `Managed Prefix List` -->
<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
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

<h3 align="center">Managed Prefix List</h3>
  <p align="center">
    Creates and manages an AWS EC2 Managed Prefix List — a named, versioned group of CIDR blocks that can be referenced in security groups, route tables, and other AWS resources to simplify network management.
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

### Empty Prefix List

Create a prefix list with no initial entries (entries can be managed separately or added later).

```hcl
module "corp_cidrs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/managed_prefix_list"

  name           = "corp-office-cidrs"
  address_family = "IPv4"
  max_entries    = 20

  tags = {
    terraform   = "true"
    environment = "prod"
    team        = "network"
  }
}
```

### IPv4 Prefix List with Entries

Manage a set of trusted IPv4 CIDR blocks inline.

```hcl
module "trusted_networks" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/managed_prefix_list"

  name           = "trusted-networks"
  address_family = "IPv4"
  max_entries    = 10

  entries = [
    {
      cidr        = "10.0.0.0/8"
      description = "RFC1918 - 10.x private space"
    },
    {
      cidr        = "172.16.0.0/12"
      description = "RFC1918 - 172.16.x private space"
    },
    {
      cidr        = "192.168.0.0/16"
      description = "RFC1918 - 192.168.x private space"
    },
  ]

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

### IPv6 Prefix List

Create a prefix list for IPv6 CIDR blocks.

```hcl
module "ipv6_ranges" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/managed_prefix_list"

  name           = "ipv6-allowed-ranges"
  address_family = "IPv6"
  max_entries    = 5

  entries = [
    {
      cidr        = "2001:db8::/32"
      description = "Documentation range"
    },
  ]

  tags = {
    terraform   = "true"
    environment = "dev"
  }
}
```

### Referencing the Prefix List in a Security Group

```hcl
module "app_prefix_list" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/managed_prefix_list"

  name           = "app-allowed-sources"
  address_family = "IPv4"
  max_entries    = 25

  entries = [
    { cidr = "10.1.0.0/16", description = "VPC A" },
    { cidr = "10.2.0.0/16", description = "VPC B" },
  ]
}

resource "aws_security_group_rule" "allow_from_prefix_list" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [module.app_prefix_list.id]
  security_group_id = aws_security_group.app.id
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ec2_managed_prefix_list.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_family"></a> [address\_family](#input\_address\_family) | (Optional) Address family (IPv4 or IPv6) of this prefix list. Changing this forces a new resource to be created. | `string` | `"IPv4"` | no |
| <a name="input_entries"></a> [entries](#input\_entries) | (Optional) List of CIDR entry objects to add to the prefix list. Each object requires a 'cidr' key and accepts an optional 'description' key. | <pre>list(object({<br/>    cidr        = string<br/>    description = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_max_entries"></a> [max\_entries](#input\_max\_entries) | (Optional) Maximum number of entries that this prefix list can contain. | `number` | `10` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Name of this prefix list. The name must not start with 'com.amazonaws'. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to this resource. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the managed prefix list. |
| <a name="output_id"></a> [id](#output\_id) | ID of the managed prefix list. Use this value to reference the prefix list in security groups, route tables, and other resources. |
| <a name="output_owner_id"></a> [owner\_id](#output\_owner\_id) | ID of the AWS account that owns this prefix list. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | Map of tags assigned to the resource, including those inherited from the provider default\_tags configuration block. |
| <a name="output_version"></a> [version](#output\_version) | Latest version of this prefix list. |
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

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)

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
