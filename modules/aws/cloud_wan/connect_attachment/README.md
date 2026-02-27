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
| [aws_networkmanager_connect_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_connect_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_connect_attachments"></a> [connect\_attachments](#input\_connect\_attachments) | (Required) Map of connect attachments to create. The key is the attachment name. | <pre>map(object({<br/>    transport_attachment_id = string<br/>    edge_location           = string<br/>    protocol                = string<br/>    proposed_segment_change = optional(object({<br/>      attachment_policy_rule_number = optional(number)<br/>      segment_name                  = optional(string)<br/>      tags                          = optional(map(string))<br/>    }))<br/>    proposed_network_function_group_change = optional(object({<br/>      attachment_policy_rule_number = optional(number)<br/>      network_function_group_name   = optional(string)<br/>      tags                          = optional(map(string))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_core_network_id"></a> [core\_network\_id](#input\_core\_network\_id) | (Required) The ID of the core network for the connect attachment. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the resource. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_attachment_arns"></a> [attachment\_arns](#output\_attachment\_arns) | Map of connect attachment ARNs |
| <a name="output_attachment_ids"></a> [attachment\_ids](#output\_attachment\_ids) | Map of connect attachment IDs |
| <a name="output_attachment_states"></a> [attachment\_states](#output\_attachment\_states) | Map of connect attachment states |
| <a name="output_attachment_types"></a> [attachment\_types](#output\_attachment\_types) | Map of connect attachment types |
| <a name="output_core_network_arns"></a> [core\_network\_arns](#output\_core\_network\_arns) | Map of core network ARNs for each connect attachment |
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
