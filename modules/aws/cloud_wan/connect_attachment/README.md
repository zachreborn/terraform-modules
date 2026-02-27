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

<h3 align="center">Cloud WAN Connect Attachment</h3>
  <p align="center">
    This module creates AWS Cloud WAN Connect attachments for SD-WAN integration. Supports both tunnel-less (NO_ENCAP) and GRE protocols.
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

### Tunnel-less Connect Attachment (NO_ENCAP)

Tunnel-less connect eliminates the need for GRE or IPsec tunnels, providing better performance and simpler configuration for SD-WAN deployments.

```hcl
module "connect_attachment" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/connect_attachment"

  core_network_id = module.core_network.id

  connect_attachments = {
    "sdwan-connect-us-east-1" = {
      transport_attachment_id = module.vpc_attachment.attachment_ids["transport-vpc-us-east-1"]
      edge_location           = "us-east-1"
      protocol                = "NO_ENCAP"  # Tunnel-less for high-performance SD-WAN
    }
  }

  tags = {
    environment = "production"
    segment     = "sdwan"
  }
}
```

### GRE Tunnel Connect Attachment

For scenarios where GRE encapsulation is required:

```hcl
module "connect_attachment" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/connect_attachment"

  core_network_id = module.core_network.id

  connect_attachments = {
    "sdwan-connect-gre" = {
      transport_attachment_id = module.vpc_attachment.attachment_ids["transport-vpc"]
      edge_location           = "us-west-2"
      protocol                = "GRE"  # GRE tunnels
    }
  }

  tags = {
    environment = "production"
  }
}
```

### Multiple Connect Attachments Across Regions

```hcl
module "connect_attachments" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/connect_attachment"

  core_network_id = module.core_network.id

  connect_attachments = {
    "sdwan-east-tunnelless" = {
      transport_attachment_id = module.vpc_attachment.attachment_ids["sdwan-vpc-us-east-1"]
      edge_location           = "us-east-1"
      protocol                = "NO_ENCAP"
    }
    "sdwan-west-tunnelless" = {
      transport_attachment_id = module.vpc_attachment.attachment_ids["sdwan-vpc-us-west-2"]
      edge_location           = "us-west-2"
      protocol                = "NO_ENCAP"
    }
  }

  tags = {
    environment = "production"
    segment     = "sdwan"
  }
}
```

## Important Notes

### Tunnel-less Connect (NO_ENCAP)
- **Performance**: Up to 100 Gbps per Availability Zone (no tunneling overhead)
- **Use Case**: Ideal for high-bandwidth SD-WAN deployments
- **Requirements**: 
  - VPC attachment must be created first (transport attachment)
  - Transport VPC and Connect attachment must be in same segment
  - BGP peering configured via connect_peer module

### GRE Protocol
- **Performance**: Up to 5 Gbps per tunnel
- **Use Case**: Traditional SD-WAN deployments requiring GRE
- **Requirements**: inside_cidr_blocks must be specified in connect_peer

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
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
