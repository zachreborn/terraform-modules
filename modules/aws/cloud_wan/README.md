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

<h3 align="center">AWS Cloud WAN Modules</h3>
  <p align="center">
    A collection of sub-modules for building AWS Cloud WAN infrastructure with tunnel-less SD-WAN connectivity support
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


<!-- OVERVIEW -->
## Overview

This directory contains sub-modules for building AWS Cloud WAN infrastructure. Each sub-module focuses on a specific component of Cloud WAN, following the same modular pattern as the `transit_gateway` modules.

## Sub-modules

### [global_network](./global_network/)
Creates the AWS Network Manager Global Network, which acts as the container for all Cloud WAN resources.

### [core_network](./core_network/)
Creates the Cloud WAN Core Network with optional policy attachment. The core network is the managed WAN backbone.

### [vpc_attachment](./vpc_attachment/)
Creates VPC attachments that serve as the transport layer for connect attachments.

### [connect_attachment](./connect_attachment/)
Creates connect attachments for SD-WAN integration. **Supports tunnel-less (NO_ENCAP) for high-performance SD-WAN connectivity without GRE overhead.**

### [connect_peer](./connect_peer/)
Creates BGP peers for SD-WAN appliances, supporting both tunnel-less and GRE configurations.

### [transit_gateway_peering](./transit_gateway_peering/)
Creates peering connections between Cloud WAN and existing Transit Gateways for migration or hybrid architectures.

## Quick Start: Tunnel-less SD-WAN

For eliminating GRE tunnels and enabling high-bandwidth SD-WAN connectivity:

```hcl
# 1. Create Global Network
module "global_network" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/global_network"
  name   = "my-sdwan-network"
}

# 2. Create Core Network with Policy
module "core_network" {
  source              = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/core_network"
  name                = "my-core-network"
  global_network_id   = module.global_network.id
  create_base_policy  = true
  base_policy_regions = ["us-east-1", "us-west-2"]
}

# 3. Create VPC Attachments (Transport)
module "vpc_attachment" {
  source          = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/vpc_attachment"
  core_network_id = module.core_network.id
  
  vpc_attachments = {
    "sdwan-vpc" = {
      vpc_arn     = aws_vpc.sdwan.arn
      subnet_arns = [aws_subnet.sdwan_az1.arn, aws_subnet.sdwan_az2.arn]
    }
  }
  
  tags = { segment = "sdwan" }
}

# 4. Create Tunnel-less Connect Attachment
module "connect_attachment" {
  source          = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/connect_attachment"
  core_network_id = module.core_network.id
  
  connect_attachments = {
    "sdwan-connect" = {
      transport_attachment_id = module.vpc_attachment.attachment_ids["sdwan-vpc"]
      edge_location           = "us-east-1"
      protocol                = "NO_ENCAP"  # Tunnel-less!
    }
  }
}

# 5. Create BGP Peers
module "connect_peer" {
  source                = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/connect_peer"
  connect_attachment_id = module.connect_attachment.attachment_ids["sdwan-connect"]
  
  peers = {
    "sdwan-appliance-1" = {
      peer_address = "10.0.1.10"
      bgp_asn      = 65001
      subnet_arn   = aws_subnet.sdwan_az1.arn
    }
  }
}
```

## Migration from Root Module

If you were using the original `cloud_wan` module (in this directory), migrate to sub-modules:

**Old (deprecated)**:
```hcl
module "cloud_wan" {
  source                = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan"
  name                  = "my-network"
  transit_gateway_arns  = [aws_ec2_transit_gateway.main.arn]
}
```

**New (recommended)**:
```hcl
module "global_network" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/global_network"
  name   = "my-network"
}

module "core_network" {
  source              = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/core_network"
  name                = "my-core-network"
  global_network_id   = module.global_network.id
  create_base_policy  = true
  base_policy_regions = ["us-east-1"]
}

module "tgw_peering" {
  source          = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/transit_gateway_peering"
  core_network_id = module.core_network.id
  
  peerings = {
    "main-tgw" = {
      transit_gateway_arn = aws_ec2_transit_gateway.main.arn
    }
  }
}
```

_For more examples, see each sub-module's README_

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
| [aws_networkmanager_global_network.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_global_network) | resource |
| [aws_networkmanager_transit_gateway_registration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_transit_gateway_registration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | (Optional) The description of the global network | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the global network | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the device. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_transit_gateway_arns"></a> [transit\_gateway\_arns](#input\_transit\_gateway\_arns) | (Required) List of ARNs of the transit gateways to register with the global network | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_global_network_arn"></a> [global\_network\_arn](#output\_global\_network\_arn) | ARN of the global network |
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

* [Zachary Hill](https://zacharyhill.co)
* [Jake Jones](https://github.com/jakeasarus)

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