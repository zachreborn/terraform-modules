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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">Transit Gateway Connect Module</h3>
  <p align="center">
    This module creates a transit gateway (tgw) connect resource. This allows attaching other network devices to a transit gateway over an encrypted tunnel.
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

```
module "transit_gateway_sdwan_connect" {
    source                  = "github.com/zachreborn/terraform-modules//modules/aws/transit_gateway/connect"

    name                    = "tgw_sdwan_connect"
    transport_attachment_id = module.prod_vpc_attachment.id
    transit_gateway_id      = module.transit_gateway.id
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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_connect.connect_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_connect) | resource |
| [aws_ec2_transit_gateway_connect_peer.peer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_connect_peer) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the transit gateway connect resources. | `string` | n/a | yes |
| <a name="input_peers"></a> [peers](#input\_peers) | (Required) A map of transit gateway connect peers, where the key is the name of the peer and the value is a map of peer configuration options. | <pre>map(object({<br/>    bgp_asn                 = optional(number, 64512) # (Optional) The BGP ASN number assigned customer device. If not provided, it will use the same BGP ASN as is associated with transit gateway.<br/>    inside_cidr_blocks      = list(string)            # (Required) The CIDR block that will be used for addressing within the tunnel. It must contain exactly one IPv4 CIDR block and up to one IPv6 CIDR block. The IPv4 CIDR block must be /29 size and must be within 169.254.0.0/16 range, with exception of: 169.254.0.0/29, 169.254.1.0/29, 169.254.2.0/29, 169.254.3.0/29, 169.254.4.0/29, 169.254.5.0/29, 169.254.169.248/29. The IPv6 CIDR block must be /125 size and must be within fd00::/8. The first IP from each CIDR block is assigned for customer gateway, the second and third is for Transit Gateway (An example: from range 169.254.100.0/29, .1 is assigned to customer gateway and .2 and .3 are assigned to the transit gateway)<br/>    peer_address            = string                  # (Required) The IP addressed assigned to customer device, which will be used as tunnel endpoint. It can be IPv4 or IPv6 address, but must be the same address family as transit_gateway_address<br/>    transit_gateway_address = optional(string)        # (Optional) The IP address assigned to the transit gateway, which will be used as tunnel endpoint. This address must be from associated transit gateway CIDR block. The address must be from the same address family as peer_address. If not set explicitly, it will be selected from associated transit gateway CIDR blocks.<br/>  }))</pre> | n/a | yes |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | (Optional) The tunnel protocol. Valid values: gre. Default is gre. | `string` | `"gre"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Key-value tags for the EC2 transit gateway connect resources. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(any)` | <pre>{<br/>  "environment": "prod",<br/>  "project": "core_infrastructure",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_transit_gateway_default_route_table_association"></a> [transit\_gateway\_default\_route\_table\_association](#input\_transit\_gateway\_default\_route\_table\_association) | (Optional) Boolean whether the Connect should be associated with the EC2 transit gateway association default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways. Default value: true. | `bool` | `true` | no |
| <a name="input_transit_gateway_default_route_table_propagation"></a> [transit\_gateway\_default\_route\_table\_propagation](#input\_transit\_gateway\_default\_route\_table\_propagation) | (Optional) Boolean whether the Connect should propagate routes with the EC2 transit gateway propagation default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 Transit Gateways. Default value: true. | `bool` | `true` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | (Required) Identifier of EC2 transit gateway. | `string` | n/a | yes |
| <a name="input_transport_attachment_id"></a> [transport\_attachment\_id](#input\_transport\_attachment\_id) | (Required) The underlaying transit gateway VPC attachment ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arns"></a> [arns](#output\_arns) | A map of ARNs of the transit gateway connect peers. |
| <a name="output_attachment_id"></a> [attachment\_id](#output\_attachment\_id) | The ID of the transit gateway connect attachment. |
| <a name="output_bgp_asns"></a> [bgp\_asns](#output\_bgp\_asns) | A map of BGP ASNs of the connect peers. |
| <a name="output_configurations"></a> [configurations](#output\_configurations) | A map of the transit gateway connect peer configurations. |
| <a name="output_ids"></a> [ids](#output\_ids) | A map of the IDs of the transit gateway connect peers |
| <a name="output_inside_cidr_blocks"></a> [inside\_cidr\_blocks](#output\_inside\_cidr\_blocks) | The CIDR blocks associated with the inside IP addresses of the connect peer. |
| <a name="output_peer_addresses"></a> [peer\_addresses](#output\_peer\_addresses) | A map of the IP address of the connect peers. |
| <a name="output_transit_gateway_addresses"></a> [transit\_gateway\_addresses](#output\_transit\_gateway\_addresses) | A map of IP address of the transit gateway. This is the IP used to connect to the transit gateway. |
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
