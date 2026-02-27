<!-- Blank module readme template: Do a search and replace with your text editor for the following: `module_name`, `module_description` -->
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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">Cloud WAN Connect Peer</h3>
  <p align="center">
    This module creates AWS Cloud WAN Connect peers for BGP peering with SD-WAN appliances. Supports both tunnel-less (NO_ENCAP) and GRE configurations.
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

### Tunnel-less BGP Peer (NO_ENCAP)

For tunnel-less connect attachments, the peer establishes native BGP sessions without tunneling:

```hcl
module "connect_peer" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/connect_peer"

  connect_attachment_id = module.connect_attachment.attachment_ids["sdwan-connect-us-east-1"]

  peers = {
    "sdwan-appliance-1" = {
      peer_address = "10.0.1.10"  # SD-WAN appliance IP
      bgp_asn      = 65001
      subnet_arn   = aws_subnet.sdwan_subnet_az1.arn
    }
    "sdwan-appliance-2" = {
      peer_address = "10.0.2.10"  # SD-WAN appliance IP in different AZ
      bgp_asn      = 65001
      subnet_arn   = aws_subnet.sdwan_subnet_az2.arn
    }
  }

  tags = {
    environment = "production"
  }
}
```

### GRE Tunnel BGP Peer

For GRE-based connect attachments, specify inside_cidr_blocks:

```hcl
module "connect_peer_gre" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/connect_peer"

  connect_attachment_id = module.connect_attachment.attachment_ids["sdwan-connect-gre"]

  peers = {
    "gre-peer-1" = {
      peer_address       = "192.168.100.1"
      bgp_asn            = 65002
      inside_cidr_blocks = ["169.254.100.0/29"]
    }
  }

  tags = {
    environment = "production"
  }
}
```

### Multiple Peers with Custom Core Network Addresses

```hcl
module "connect_peers" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/connect_peer"

  connect_attachment_id = module.connect_attachment.attachment_ids["sdwan-connect"]

  peers = {
    "sdwan-primary" = {
      peer_address         = "10.1.1.10"
      bgp_asn              = 65100
      subnet_arn           = aws_subnet.primary.arn
      core_network_address = "10.1.1.1"  # Optional: specify core network BGP address
    }
    "sdwan-secondary" = {
      peer_address         = "10.1.2.10"
      bgp_asn              = 65100
      subnet_arn           = aws_subnet.secondary.arn
      core_network_address = "10.1.2.1"
    }
  }

  tags = {
    environment = "production"
  }
}
```

## Important Notes

### BGP Configuration
- **ASN Range**: Must be in range 64512-65534 or 4200000000-4294967294
- **Redundancy**: Create two BGP peers per connect attachment for high availability
- **Peer Address**: IP address of the SD-WAN appliance (not Cloud WAN)

### Tunnel-less (NO_ENCAP) Requirements
- `subnet_arn` is required for tunnel-less connect peers
- Peer address must be in the same subnet as the VPC attachment
- No `inside_cidr_blocks` needed

### GRE Requirements
- `inside_cidr_blocks` is required for GRE peers
- Minimum /29 for IPv4 or /125 for IPv6
- Core Network Edge auto-assigns addresses from inside CIDR blocks

### Route Table Configuration
For tunnel-less connect with SD-WAN appliances in different subnets:
- Add core network edge BGP IP to VPC route table
- Add destination prefixes advertised by core network to VPC route table

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.34.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_networkmanager_connect_peer.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_connect_peer) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_connect_attachment_id"></a> [connect\_attachment\_id](#input\_connect\_attachment\_id) | (Required) The ID of the connect attachment. | `string` | n/a | yes |
| <a name="input_peers"></a> [peers](#input\_peers) | (Required) Map of BGP peers to create. The key is the peer name. | <pre>map(object({<br/>    peer_address         = string<br/>    bgp_asn              = number<br/>    core_network_address = optional(string)<br/>    inside_cidr_blocks   = optional(list(string))<br/>    subnet_arn           = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the resource. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configurations"></a> [configurations](#output\_configurations) | Map of connect peer configurations (BGP addresses) |
| <a name="output_core_network_addresses"></a> [core\_network\_addresses](#output\_core\_network\_addresses) | Map of core network addresses assigned to each peer |
| <a name="output_edge_locations"></a> [edge\_locations](#output\_edge\_locations) | Map of edge locations for each peer |
| <a name="output_peer_arns"></a> [peer\_arns](#output\_peer\_arns) | Map of connect peer ARNs |
| <a name="output_peer_ids"></a> [peer\_ids](#output\_peer\_ids) | Map of connect peer IDs |
| <a name="output_peer_states"></a> [peer\_states](#output\_peer\_states) | Map of connect peer states |
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
