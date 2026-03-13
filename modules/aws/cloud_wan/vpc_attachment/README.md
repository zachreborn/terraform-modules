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

<h3 align="center">Cloud WAN VPC Attachment</h3>
  <p align="center">
    This module creates AWS Cloud WAN VPC attachments. VPC attachments serve as the transport layer for connect attachments in Cloud WAN.
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

### Single VPC Attachment

```hcl
module "vpc_attachment" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/vpc_attachment"

  core_network_id = module.core_network.id

  vpc_attachments = {
    "transport-vpc-us-east-1" = {
      vpc_arn                = aws_vpc.transport.arn
      subnet_arns            = [
        aws_subnet.transport_az1.arn,
        aws_subnet.transport_az2.arn
      ]
      appliance_mode_support = false
      ipv6_support           = false
    }
  }

  tags = {
    environment = "production"
    segment     = "sdwan"  # Used by core network policy for segment association
  }
}
```

### Multiple VPC Attachments

```hcl
module "vpc_attachments" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/vpc_attachment"

  core_network_id = module.core_network.id

  vpc_attachments = {
    "sdwan-vpc-us-east-1" = {
      vpc_arn     = aws_vpc.sdwan_east.arn
      subnet_arns = [
        aws_subnet.sdwan_east_az1.arn,
        aws_subnet.sdwan_east_az2.arn
      ]
      appliance_mode_support = true
      ipv6_support           = false
    }
    "sdwan-vpc-us-west-2" = {
      vpc_arn     = aws_vpc.sdwan_west.arn
      subnet_arns = [
        aws_subnet.sdwan_west_az1.arn,
        aws_subnet.sdwan_west_az2.arn
      ]
      appliance_mode_support = true
      ipv6_support           = false
    }
  }

  tags = {
    environment = "production"
    segment     = "sdwan"
  }
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.34.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_networkmanager_vpc_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_vpc_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_core_network_id"></a> [core\_network\_id](#input\_core\_network\_id) | (Required) The ID of the core network for the VPC attachment. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the resource. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_vpc_attachments"></a> [vpc\_attachments](#input\_vpc\_attachments) | (Required) Map of VPC attachments to create. The key is the attachment name. | <pre>map(object({<br/>    vpc_arn                = string<br/>    subnet_arns            = list(string)<br/>    appliance_mode_support = optional(bool, false)<br/>    ipv6_support           = optional(bool, false)<br/>    routing_policy_label   = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_attachment_arns"></a> [attachment\_arns](#output\_attachment\_arns) | Map of VPC attachment ARNs |
| <a name="output_attachment_ids"></a> [attachment\_ids](#output\_attachment\_ids) | Map of VPC attachment IDs |
| <a name="output_attachment_states"></a> [attachment\_states](#output\_attachment\_states) | Map of VPC attachment states |
| <a name="output_edge_locations"></a> [edge\_locations](#output\_edge\_locations) | Map of VPC attachment edge locations |
| <a name="output_segment_names"></a> [segment\_names](#output\_segment\_names) | Map of VPC attachment segment names |
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
