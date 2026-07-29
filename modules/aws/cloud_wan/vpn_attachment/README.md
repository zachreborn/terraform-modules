<!-- Cloud WAN VPN Attachment Module README -->
<a name="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<h3 align="center">AWS Cloud WAN VPN Attachment Module</h3>

## Prerequisites

- A Cloud WAN core network must already exist (e.g. via `awscc_networkmanager_core_network`) before setting `create_cloud_wan_attachment = true`. This module does not create the core network or its policy document.
- If `create_cloud_wan_attachment` is `false` (the default), this module only creates standalone customer gateway(s) and VPN connection(s); attach them to Cloud WAN, a Transit Gateway, or a Virtual Private Gateway using resources managed outside of this module.

## Usage

Create a Site-to-Site VPN connection and attach it to an existing Cloud WAN core network:

```hcl
module "cloud_wan_vpn" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/vpn_attachment"

  customer_gateways = [
    {
      name       = "corporate-office"
      ip_address = "YOUR_CUSTOMER_GATEWAY_PUBLIC_IP" # e.g. a static public IPv4 address
      bgp_asn    = 65001
    }
  ]

  static_routes_only          = false
  create_cloud_wan_attachment = true
  core_network_id             = awscc_networkmanager_core_network.example.id

  tags = {
    Environment = "production"
  }
}
```

### Certificate-based customer gateway

```hcl
module "cloud_wan_vpn_cert" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/vpn_attachment"

  customer_gateways = [
    {
      name            = "partner-site"
      certificate_arn = module.customer_gateway_certificate.arn
      bgp_asn         = 65002
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

## Notes / Design Decisions

- Each entry in `customer_gateways` produces one `aws_customer_gateway` and one `aws_vpn_connection`, matched by list index. Every VPN connection shares the same tunnel security settings (IKE versions, DH groups, encryption/integrity algorithms, preshared keys, etc.) supplied via this module's top-level `tunnel_*` variables.
- The VPN connection(s) created by this module intentionally do not set `transit_gateway_id` or `vpn_gateway_id`, matching the AWS-documented pattern for VPN connections meant to be attached to Cloud WAN via `aws_networkmanager_site_to_site_vpn_attachment`.
- Set `create_cloud_wan_attachment = true` and provide `core_network_id` to also create the Cloud WAN attachment for each VPN connection. Leave it `false` to manage the attachment (or an alternative Transit Gateway/Virtual Private Gateway attachment) outside of this module.

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
| [aws_customer_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/customer_gateway) | resource |
| [aws_networkmanager_site_to_site_vpn_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_site_to_site_vpn_attachment) | resource |
| [aws_vpn_connection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_connection) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_core_network_id"></a> [core\_network\_id](#input\_core\_network\_id) | (Required if create\_cloud\_wan\_attachment is true) The ID of the Cloud WAN core network to attach the VPN connection(s) to. | `string` | `null` | no |
| <a name="input_create_cloud_wan_attachment"></a> [create\_cloud\_wan\_attachment](#input\_create\_cloud\_wan\_attachment) | (Optional) Whether to attach the created VPN connection(s) to a Cloud WAN core network via a Network Manager Site-to-Site VPN attachment. Defaults to false. | `bool` | `false` | no |
| <a name="input_customer_gateways"></a> [customer\_gateways](#input\_customer\_gateways) | (Required) List of customer gateway configurations. Each entry must specify either ip\_address or certificate\_arn for authentication, and may specify at most one of bgp\_asn (1-2147483647) or bgp\_asn\_extended (2147483648-4294967295); if neither is set, AWS applies its default ASN of 65000. | <pre>list(object({<br/>    name             = string<br/>    ip_address       = optional(string)<br/>    bgp_asn          = optional(number)<br/>    bgp_asn_extended = optional(number)<br/>    certificate_arn  = optional(string)<br/>    device_name      = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_local_ipv4_network_cidr"></a> [local\_ipv4\_network\_cidr](#input\_local\_ipv4\_network\_cidr) | (Optional) The IPv4 CIDR on the customer gateway (on-premises) side of the VPN connection(s). Defaults to the wildcard IPv4 CIDR (all addresses) when unset. | `string` | `null` | no |
| <a name="input_local_ipv6_network_cidr"></a> [local\_ipv6\_network\_cidr](#input\_local\_ipv6\_network\_cidr) | (Optional) The IPv6 CIDR on the customer gateway (on-premises) side of the VPN connection(s). Defaults to ::/0 when unset. | `string` | `null` | no |
| <a name="input_outside_ip_address_type"></a> [outside\_ip\_address\_type](#input\_outside\_ip\_address\_type) | (Optional) Indicates a Public or Private (over Direct Connect) Site-to-Site VPN. Valid values are PublicIpv4 \| PrivateIpv4. Defaults to PublicIpv4 when unset. PrivateIpv4 requires transport\_transit\_gateway\_attachment\_id and an EC2 Transit Gateway attachment managed outside of this module. | `string` | `null` | no |
| <a name="input_remote_ipv4_network_cidr"></a> [remote\_ipv4\_network\_cidr](#input\_remote\_ipv4\_network\_cidr) | (Optional) The IPv4 CIDR on the AWS side of the VPN connection(s). Defaults to the wildcard IPv4 CIDR (all addresses) when unset. | `string` | `null` | no |
| <a name="input_remote_ipv6_network_cidr"></a> [remote\_ipv6\_network\_cidr](#input\_remote\_ipv6\_network\_cidr) | (Optional) The IPv6 CIDR on the AWS side of the VPN connection(s). Defaults to ::/0 when unset. | `string` | `null` | no |
| <a name="input_routing_policy_label"></a> [routing\_policy\_label](#input\_routing\_policy\_label) | (Optional) The routing policy label to apply to the Site-to-Site VPN attachment(s) for traffic routing decisions. Maximum length of 256 characters. Changing this value forces recreation of the attachment. | `string` | `null` | no |
| <a name="input_static_routes_only"></a> [static\_routes\_only](#input\_static\_routes\_only) | (Optional) Whether the VPN connection uses static routes exclusively. Defaults to true. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the resources. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_transport_transit_gateway_attachment_id"></a> [transport\_transit\_gateway\_attachment\_id](#input\_transport\_transit\_gateway\_attachment\_id) | (Optional) The attachment ID of the Transit Gateway attachment to a Direct Connect Gateway. Required when outside\_ip\_address\_type is PrivateIpv4. Obtained from the aws\_ec2\_transit\_gateway\_dx\_gateway\_attachment data source. | `string` | `null` | no |
| <a name="input_tunnel1_dpd_timeout_action"></a> [tunnel1\_dpd\_timeout\_action](#input\_tunnel1\_dpd\_timeout\_action) | (Optional) Action to take after a DPD timeout occurs for the first tunnel. Valid values are clear \| none \| restart. Defaults to clear. | `string` | `"clear"` | no |
| <a name="input_tunnel1_dpd_timeout_seconds"></a> [tunnel1\_dpd\_timeout\_seconds](#input\_tunnel1\_dpd\_timeout\_seconds) | (Optional) Number of seconds after which a DPD timeout occurs for the first tunnel. Must be 30 or higher. Defaults to 30. | `number` | `30` | no |
| <a name="input_tunnel1_inside_cidr"></a> [tunnel1\_inside\_cidr](#input\_tunnel1\_inside\_cidr) | (Optional) The CIDR block of the inside IP addresses for the first VPN tunnel. Must be a /30 from the AWS-reserved link-local range for VPN tunnels (169 dot 254 dot 0 dot 0 slash 16). | `string` | `null` | no |
| <a name="input_tunnel1_log_options"></a> [tunnel1\_log\_options](#input\_tunnel1\_log\_options) | (Optional) Options for logging first VPN tunnel activity to CloudWatch Logs. | <pre>object({<br/>    cloudwatch_log_options = optional(object({<br/>      log_enabled       = optional(bool, false)<br/>      log_group_arn     = optional(string)<br/>      log_output_format = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_tunnel1_phase1_lifetime_seconds"></a> [tunnel1\_phase1\_lifetime\_seconds](#input\_tunnel1\_phase1\_lifetime\_seconds) | (Optional) Lifetime for phase 1 of the IKE negotiation for the first tunnel, in seconds. Valid range is 900-28800. Defaults to 28800. | `number` | `28800` | no |
| <a name="input_tunnel1_phase2_lifetime_seconds"></a> [tunnel1\_phase2\_lifetime\_seconds](#input\_tunnel1\_phase2\_lifetime\_seconds) | (Optional) Lifetime for phase 2 of the IKE negotiation for the first tunnel, in seconds. Valid range is 900-3600. Defaults to 3600. | `number` | `3600` | no |
| <a name="input_tunnel1_preshared_key"></a> [tunnel1\_preshared\_key](#input\_tunnel1\_preshared\_key) | (Optional) The preshared key of the first VPN tunnel, applied to every VPN connection created by this module. Must be 8-64 characters and cannot start with 0. If omitted, AWS generates one automatically. | `string` | `null` | no |
| <a name="input_tunnel1_rekey_fuzz_percentage"></a> [tunnel1\_rekey\_fuzz\_percentage](#input\_tunnel1\_rekey\_fuzz\_percentage) | (Optional) Percentage of the rekey window for the first tunnel during which the rekey time is randomly selected. Defaults to 100. | `number` | `100` | no |
| <a name="input_tunnel1_rekey_margin_time_seconds"></a> [tunnel1\_rekey\_margin\_time\_seconds](#input\_tunnel1\_rekey\_margin\_time\_seconds) | (Optional) Margin time, in seconds, before the phase 2 lifetime expires for the first tunnel, during which AWS performs an IKE rekey. Defaults to 540. | `number` | `540` | no |
| <a name="input_tunnel1_replay_window_size"></a> [tunnel1\_replay\_window\_size](#input\_tunnel1\_replay\_window\_size) | (Optional) Number of packets in an IKE replay window for the first tunnel. Valid range is 64-2048. Defaults to 1024. | `number` | `1024` | no |
| <a name="input_tunnel2_dpd_timeout_action"></a> [tunnel2\_dpd\_timeout\_action](#input\_tunnel2\_dpd\_timeout\_action) | (Optional) Action to take after a DPD timeout occurs for the second tunnel. Valid values are clear \| none \| restart. Defaults to clear. | `string` | `"clear"` | no |
| <a name="input_tunnel2_dpd_timeout_seconds"></a> [tunnel2\_dpd\_timeout\_seconds](#input\_tunnel2\_dpd\_timeout\_seconds) | (Optional) Number of seconds after which a DPD timeout occurs for the second tunnel. Must be 30 or higher. Defaults to 30. | `number` | `30` | no |
| <a name="input_tunnel2_inside_cidr"></a> [tunnel2\_inside\_cidr](#input\_tunnel2\_inside\_cidr) | (Optional) The CIDR block of the inside IP addresses for the second VPN tunnel. Must be a /30 from the AWS-reserved link-local range for VPN tunnels (169 dot 254 dot 0 dot 0 slash 16). | `string` | `null` | no |
| <a name="input_tunnel2_log_options"></a> [tunnel2\_log\_options](#input\_tunnel2\_log\_options) | (Optional) Options for logging second VPN tunnel activity to CloudWatch Logs. | <pre>object({<br/>    cloudwatch_log_options = optional(object({<br/>      log_enabled       = optional(bool, false)<br/>      log_group_arn     = optional(string)<br/>      log_output_format = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_tunnel2_phase1_lifetime_seconds"></a> [tunnel2\_phase1\_lifetime\_seconds](#input\_tunnel2\_phase1\_lifetime\_seconds) | (Optional) Lifetime for phase 1 of the IKE negotiation for the second tunnel, in seconds. Valid range is 900-28800. Defaults to 28800. | `number` | `28800` | no |
| <a name="input_tunnel2_phase2_lifetime_seconds"></a> [tunnel2\_phase2\_lifetime\_seconds](#input\_tunnel2\_phase2\_lifetime\_seconds) | (Optional) Lifetime for phase 2 of the IKE negotiation for the second tunnel, in seconds. Valid range is 900-3600. Defaults to 3600. | `number` | `3600` | no |
| <a name="input_tunnel2_preshared_key"></a> [tunnel2\_preshared\_key](#input\_tunnel2\_preshared\_key) | (Optional) The preshared key of the second VPN tunnel, applied to every VPN connection created by this module. Must be 8-64 characters and cannot start with 0. If omitted, AWS generates one automatically. | `string` | `null` | no |
| <a name="input_tunnel2_rekey_fuzz_percentage"></a> [tunnel2\_rekey\_fuzz\_percentage](#input\_tunnel2\_rekey\_fuzz\_percentage) | (Optional) Percentage of the rekey window for the second tunnel during which the rekey time is randomly selected. Defaults to 100. | `number` | `100` | no |
| <a name="input_tunnel2_rekey_margin_time_seconds"></a> [tunnel2\_rekey\_margin\_time\_seconds](#input\_tunnel2\_rekey\_margin\_time\_seconds) | (Optional) Margin time, in seconds, before the phase 2 lifetime expires for the second tunnel, during which AWS performs an IKE rekey. Defaults to 540. | `number` | `540` | no |
| <a name="input_tunnel2_replay_window_size"></a> [tunnel2\_replay\_window\_size](#input\_tunnel2\_replay\_window\_size) | (Optional) Number of packets in an IKE replay window for the second tunnel. Valid range is 64-2048. Defaults to 1024. | `number` | `1024` | no |
| <a name="input_tunnel_ike_versions"></a> [tunnel\_ike\_versions](#input\_tunnel\_ike\_versions) | (Optional) The IKE versions that are permitted for the VPN tunnels. Valid values are ikev1 \| ikev2. | `list(string)` | <pre>[<br/>  "ikev2"<br/>]</pre> | no |
| <a name="input_tunnel_phase1_dh_group_numbers"></a> [tunnel\_phase1\_dh\_group\_numbers](#input\_tunnel\_phase1\_dh\_group\_numbers) | (Optional) DH group numbers for Phase 1. Valid values are 2, 14-24. | `list(string)` | <pre>[<br/>  "14",<br/>  "15",<br/>  "16",<br/>  "17",<br/>  "18",<br/>  "19",<br/>  "20",<br/>  "21",<br/>  "22",<br/>  "23",<br/>  "24"<br/>]</pre> | no |
| <a name="input_tunnel_phase1_encryption_algorithms"></a> [tunnel\_phase1\_encryption\_algorithms](#input\_tunnel\_phase1\_encryption\_algorithms) | (Optional) Encryption algorithms for Phase 1. Valid values are AES128, AES256, AES128-GCM-16, AES256-GCM-16. | `list(string)` | <pre>[<br/>  "AES256",<br/>  "AES256-GCM-16"<br/>]</pre> | no |
| <a name="input_tunnel_phase1_integrity_algorithms"></a> [tunnel\_phase1\_integrity\_algorithms](#input\_tunnel\_phase1\_integrity\_algorithms) | (Optional) Integrity algorithms for Phase 1. Valid values are SHA1, SHA2-256, SHA2-384, SHA2-512. | `list(string)` | <pre>[<br/>  "SHA2-256",<br/>  "SHA2-384",<br/>  "SHA2-512"<br/>]</pre> | no |
| <a name="input_tunnel_phase2_dh_group_numbers"></a> [tunnel\_phase2\_dh\_group\_numbers](#input\_tunnel\_phase2\_dh\_group\_numbers) | (Optional) DH group numbers for Phase 2. Valid values are 2, 5, 14-24. | `list(string)` | <pre>[<br/>  "14",<br/>  "15",<br/>  "16",<br/>  "17",<br/>  "18",<br/>  "19",<br/>  "20",<br/>  "21",<br/>  "22",<br/>  "23",<br/>  "24"<br/>]</pre> | no |
| <a name="input_tunnel_phase2_encryption_algorithms"></a> [tunnel\_phase2\_encryption\_algorithms](#input\_tunnel\_phase2\_encryption\_algorithms) | (Optional) Encryption algorithms for Phase 2. Valid values are AES128, AES256, AES128-GCM-16, AES256-GCM-16. | `list(string)` | <pre>[<br/>  "AES256",<br/>  "AES256-GCM-16"<br/>]</pre> | no |
| <a name="input_tunnel_phase2_integrity_algorithms"></a> [tunnel\_phase2\_integrity\_algorithms](#input\_tunnel\_phase2\_integrity\_algorithms) | (Optional) Integrity algorithms for Phase 2. Valid values are SHA1, SHA2-256, SHA2-384, SHA2-512. | `list(string)` | <pre>[<br/>  "SHA2-256",<br/>  "SHA2-384",<br/>  "SHA2-512"<br/>]</pre> | no |
| <a name="input_tunnel_startup_action"></a> [tunnel\_startup\_action](#input\_tunnel\_startup\_action) | (Optional) Action to take when establishing the tunnel. Valid values are add \| start. Defaults to add. | `string` | `"add"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloud_wan_attachment_ids"></a> [cloud\_wan\_attachment\_ids](#output\_cloud\_wan\_attachment\_ids) | IDs of the Cloud WAN Site-to-Site VPN attachments (empty when create\_cloud\_wan\_attachment is false). |
| <a name="output_cloud_wan_attachments"></a> [cloud\_wan\_attachments](#output\_cloud\_wan\_attachments) | Map of Cloud WAN Site-to-Site VPN attachment details, keyed by customer gateway name (empty when create\_cloud\_wan\_attachment is false). |
| <a name="output_customer_gateway_ids"></a> [customer\_gateway\_ids](#output\_customer\_gateway\_ids) | IDs of the created customer gateways. |
| <a name="output_customer_gateways"></a> [customer\_gateways](#output\_customer\_gateways) | Map of customer gateway details. |
| <a name="output_vpn_connection_ids"></a> [vpn\_connection\_ids](#output\_vpn\_connection\_ids) | IDs of the created VPN connections. |
| <a name="output_vpn_connections"></a> [vpn\_connections](#output\_vpn\_connections) | Map of VPN connection details. |
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
