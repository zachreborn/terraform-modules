<!-- Blank module readme template: Do a search and replace with your text editor for the following: `module_name`, `module_description` -->
<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

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

<h3 align="center">Direct Connect Transit Virtual Interface Module</h3>
  <p align="center">
    This module manages an AWS Direct Connect transit virtual interface (aws_dx_transit_virtual_interface). A transit VIF is a VLAN that carries traffic from a Direct Connect connection to a Direct Connect gateway, which can then be associated with transit gateways or Cloud WAN core networks for multi-account/multi-VPC routing. See https://aws.amazon.com/directconnect/ for more information.
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

### Create a Transit Virtual Interface

A transit VIF connects an existing dedicated/hosted connection (see the `connection` module) to an existing Direct Connect gateway (see the `gateway` module).

```
module "dx_transit_vif" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/directconnect/virtual_interface"

  connection_id = module.dx_connection.id
  dx_gateway_id = module.dx_gateway.id
  name          = "core-transit-vif"
  vlan          = 100
  bgp_asn       = 65000

  # Set mtu = 8500 to enable jumbo frames for Transit Gateway / Cloud WAN connectivity.
  mtu = 8500

  tags = {
    terraform   = "true"
    environment = "prod"
    project     = "core_infrastructure"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- NOTES -->

## Notes / Design Decisions

- **Only one transit VIF is allowed per connection.** The AWS API permits a single transit virtual interface per Direct Connect connection (or LAG); create additional connections if you need more transit VIFs.
- **`mtu = 8500` (jumbo frames) is opt-in.** The default of `1500` matches the AWS default and works everywhere; set `mtu = 8500` only when your connection and downstream Transit Gateway/Cloud WAN attachment both support jumbo frames.
- **`bgp_auth_key` is marked `sensitive`** so its value is redacted from plan/apply output, but it is still stored in plaintext in Terraform state. Ensure your state backend is encrypted and access-controlled.

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
| [aws_dx_transit_virtual_interface.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dx_transit_virtual_interface) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_address_family"></a> [address\_family](#input\_address\_family) | (Required) The address family for the BGP peer. Valid values: ipv4, ipv6. | `string` | `"ipv4"` | no |
| <a name="input_amazon_address"></a> [amazon\_address](#input\_amazon\_address) | (Optional) The IPv4 CIDR address to use for the Amazon side of the BGP session (e.g. 169.254.96.9/29). Required when address\_family is ipv4. | `string` | `null` | no |
| <a name="input_bgp_asn"></a> [bgp\_asn](#input\_bgp\_asn) | (Required) The customer-side autonomous system (AS) number for BGP configuration. | `number` | n/a | yes |
| <a name="input_bgp_auth_key"></a> [bgp\_auth\_key](#input\_bgp\_auth\_key) | (Optional) The MD5 authentication key for the BGP session. Store as a sensitive workspace variable. | `string` | `null` | no |
| <a name="input_connection_id"></a> [connection\_id](#input\_connection\_id) | (Required) The ID of the Direct Connect connection (or LAG) on which to create the virtual interface. | `string` | n/a | yes |
| <a name="input_customer_address"></a> [customer\_address](#input\_customer\_address) | (Optional) The IPv4 CIDR address to use for the customer side of the BGP session (e.g. 169.254.96.14/29). Required when address\_family is ipv4. | `string` | `null` | no |
| <a name="input_dx_gateway_id"></a> [dx\_gateway\_id](#input\_dx\_gateway\_id) | (Required) The ID of the Direct Connect gateway to which to connect the virtual interface. | `string` | n/a | yes |
| <a name="input_mtu"></a> [mtu](#input\_mtu) | (Optional) The maximum transmission unit (MTU) in bytes. Valid values: 1500 (default) or 8500 (jumbo frames). Set to 8500 for Cloud WAN / Transit Gateway connectivity. | `number` | `1500` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the virtual interface. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region where this transit virtual interface is managed. Defaults to the Region set in the provider configuration. | `string` | `null` | no |
| <a name="input_sitelink_enabled"></a> [sitelink\_enabled](#input\_sitelink\_enabled) | (Optional) Whether to enable SiteLink on the virtual interface. SiteLink allows direct connectivity between Direct Connect locations. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the virtual interface. A Name tag is automatically added from var.name. | `map(string)` | `{}` | no |
| <a name="input_vlan"></a> [vlan](#input\_vlan) | (Required) The VLAN ID. Must match the VLAN configured on the physical connection with the carrier. | `number` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_amazon_side_asn"></a> [amazon\_side\_asn](#output\_amazon\_side\_asn) | The Amazon-side ASN for the BGP session (inherited from the Direct Connect gateway). |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the transit virtual interface. |
| <a name="output_aws_device"></a> [aws\_device](#output\_aws\_device) | The Direct Connect endpoint on which the virtual interface terminates. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the transit virtual interface. |
| <a name="output_jumbo_frame_capable"></a> [jumbo\_frame\_capable](#output\_jumbo\_frame\_capable) | Whether jumbo frames (8500 MTU) are supported on this virtual interface. |
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
