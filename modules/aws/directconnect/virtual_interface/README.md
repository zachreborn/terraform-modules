<!-- Blank module readme template -->
<a name="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<h3 align="center">AWS Direct Connect Virtual Interface Module</h3>

## Usage

Create a private virtual interface attached to a Virtual Private Gateway, with jumbo frames and SiteLink enabled:

```hcl
module "dx_vif" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/directconnect/virtual_interface"

  vif_type          = "private"
  vif_name          = "my-private-vif"
  dx_connection_id  = module.dx_connection.id
  vlan              = 100
  customer_bgp_asn  = 65000
  customer_address  = "YOUR_CUSTOMER_SIDE_CIDR" # e.g. a /30 CIDR
  amazon_address    = "YOUR_AMAZON_SIDE_CIDR"   # e.g. a /30 CIDR
  vpn_gateway_id    = aws_vpn_gateway.example.id
  mtu               = 9001
  sitelink_enabled  = true

  tags = {
    Environment = "production"
  }
}
```

### Private VIF attached to a Direct Connect Gateway

A private VIF may attach to either a Virtual Private Gateway (`vpn_gateway_id`, above) or a Direct Connect Gateway (`direct_connect_gateway_id`, below), but not both.

```hcl
module "dx_vif_dxgw" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/directconnect/virtual_interface"

  vif_type                  = "private"
  vif_name                  = "my-private-vif-dxgw"
  dx_connection_id          = module.dx_connection.id
  vlan                      = 101
  customer_bgp_asn          = 65000
  customer_address          = "YOUR_CUSTOMER_SIDE_CIDR"
  amazon_address            = "YOUR_AMAZON_SIDE_CIDR"
  direct_connect_gateway_id = aws_dx_gateway.example.id

  tags = {
    Environment = "production"
  }
}
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
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
| [aws_dx_private_virtual_interface.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dx_private_virtual_interface) | resource |
| [aws_dx_public_virtual_interface.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dx_public_virtual_interface) | resource |
| [aws_dx_transit_virtual_interface.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dx_transit_virtual_interface) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_address_family"></a> [address\_family](#input\_address\_family) | (Optional) The address family for the BGP peer. ipv4 or ipv6. Defaults to ipv4. | `string` | `"ipv4"` | no |
| <a name="input_amazon_address"></a> [amazon\_address](#input\_amazon\_address) | (Required) The IPv4 CIDR address to use to tag the Amazon side of the connection. | `string` | n/a | yes |
| <a name="input_bgp_auth_key"></a> [bgp\_auth\_key](#input\_bgp\_auth\_key) | (Optional) The authentication key for the BGP configuration. If omitted, AWS generates one automatically. | `string` | `null` | no |
| <a name="input_customer_address"></a> [customer\_address](#input\_customer\_address) | (Required) The IPv4 CIDR address to use to tag the customer side of the connection. | `string` | n/a | yes |
| <a name="input_customer_bgp_asn"></a> [customer\_bgp\_asn](#input\_customer\_bgp\_asn) | (Required) The ASN used by the customer on the customer side of the connection. | `number` | n/a | yes |
| <a name="input_direct_connect_gateway_id"></a> [direct\_connect\_gateway\_id](#input\_direct\_connect\_gateway\_id) | (Optional) The ID of the Direct Connect Gateway to which the VIF is attached. Required if vif\_type is 'transit'. For vif\_type 'private', specify exactly one of vpn\_gateway\_id or direct\_connect\_gateway\_id. | `string` | `null` | no |
| <a name="input_dx_connection_id"></a> [dx\_connection\_id](#input\_dx\_connection\_id) | (Required) The ID of the Direct Connect connection. | `string` | n/a | yes |
| <a name="input_mtu"></a> [mtu](#input\_mtu) | (Optional) The maximum transmission unit (MTU) for private/transit VIFs. Valid values are 1500 or 9001 (jumbo frames). Not applicable to public VIFs. Defaults to 1500. | `number` | `1500` | no |
| <a name="input_route_filter_prefixes"></a> [route\_filter\_prefixes](#input\_route\_filter\_prefixes) | (Required if vif\_type is 'public') A list of IP prefixes to advertise to the customer for public VIFs. | `list(string)` | `[]` | no |
| <a name="input_sitelink_enabled"></a> [sitelink\_enabled](#input\_sitelink\_enabled) | (Optional) Whether to enable AWS Direct Connect SiteLink for private/transit VIFs. Not applicable to public VIFs. Defaults to false. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the VIF. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_vif_name"></a> [vif\_name](#input\_vif\_name) | (Required) The name of the virtual interface. | `string` | n/a | yes |
| <a name="input_vif_type"></a> [vif\_type](#input\_vif\_type) | (Required) The type of the virtual interface. Valid values are private, public, transit. | `string` | n/a | yes |
| <a name="input_vlan"></a> [vlan](#input\_vlan) | (Required) The VLAN ID for the VIF. Valid values are 1-4094. | `number` | n/a | yes |
| <a name="input_vpn_gateway_id"></a> [vpn\_gateway\_id](#input\_vpn\_gateway\_id) | (Optional) The ID of the virtual private gateway to which the VIF is attached. For vif\_type 'private', specify exactly one of vpn\_gateway\_id or direct\_connect\_gateway\_id. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_amazon_address"></a> [amazon\_address](#output\_amazon\_address) | The IPv4 CIDR address used on the Amazon side of the connection. |
| <a name="output_amazon_side_asn"></a> [amazon\_side\_asn](#output\_amazon\_side\_asn) | The autonomous system (AS) number for the Amazon side of the BGP session. |
| <a name="output_bgp_asn"></a> [bgp\_asn](#output\_bgp\_asn) | The ASN used by the customer. |
| <a name="output_customer_address"></a> [customer\_address](#output\_customer\_address) | The IPv4 CIDR address used on the customer side of the connection. |
| <a name="output_mtu"></a> [mtu](#output\_mtu) | The maximum transmission unit (MTU) of the VIF, in bytes. Only applicable to private/transit VIFs. |
| <a name="output_private_vif_id"></a> [private\_vif\_id](#output\_private\_vif\_id) | The ID of the private virtual interface. |
| <a name="output_public_vif_id"></a> [public\_vif\_id](#output\_public\_vif\_id) | The ID of the public virtual interface. |
| <a name="output_sitelink_enabled"></a> [sitelink\_enabled](#output\_sitelink\_enabled) | Whether AWS Direct Connect SiteLink is enabled for the VIF. Only applicable to private/transit VIFs. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | A map of tags assigned to the VIF. |
| <a name="output_transit_vif_id"></a> [transit\_vif\_id](#output\_transit\_vif\_id) | The ID of the transit virtual interface. |
| <a name="output_vif_id"></a> [vif\_id](#output\_vif\_id) | The ID of the created virtual interface. |
<!-- END_TF_DOCS -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

## Contact

Zachary Hill - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

## Acknowledgments

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasaurus)

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
