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

<h3 align="center">VPN Route Module</h3>
  <p align="center">
    This module creates a route within a VPN.
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

### Simple Example
This example routes 10.0.0.0/8 on the VPN tunnel. A separate route needs to be set up within the VPC subnet route table, or the VPN Gateway needs to be configured to propagate routes to the VPC subnet.
```
module "vpn_route_10_0_0_0" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/vpn_route"

  vpn_connection_id    = module.hq_vpn.vpn_connection_id
  vpn_route_cidr_block = "10.0.0.0/8"
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
| [aws_wafv2_ip_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_ip_set) | resource |
| [aws_wafv2_web_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_associate_with_resource"></a> [associate\_with\_resource](#input\_associate\_with\_resource) | Resource ARN to associate the WAF with (API Gateway, ALB, etc.) | `string` | `null` | no |
| <a name="input_default_action"></a> [default\_action](#input\_default\_action) | Default action for the WAF ACL | <pre>object({<br/>    allow = optional(bool)<br/>    block = optional(bool)<br/>  })</pre> | <pre>{<br/>  "allow": false,<br/>  "block": true<br/>}</pre> | no |
| <a name="input_description"></a> [description](#input\_description) | n/a | `string` | `"default"` | no |
| <a name="input_ip_sets"></a> [ip\_sets](#input\_ip\_sets) | Map of IP sets to create | <pre>map(object({<br/>    name               = string<br/>    description        = optional(string, "IP set created by WAF module")<br/>    ip_address_version = optional(string, "IPV4")<br/>    addresses          = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"default"` | no |
| <a name="input_rule"></a> [rule](#input\_rule) | Map of rule configuration | <pre>map(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string<br/>    statement = object({<br/>      managed_rule_group_statement = optional(object({<br/>        name           = string<br/>        vendor_name    = string<br/>        priority       = number<br/>        excluded_rules = list(string)<br/>      }))<br/>      not_statement = optional(object({<br/>        ip_set_reference_statement = object({<br/>          arn = string<br/>        })<br/>      }))<br/>      ip_set_reference_statement = optional(object({<br/>        arn = string<br/>      }))<br/>    })<br/>    visibility_config = object({<br/>      cloudwatch_metrics_enabled = bool<br/>      metric_name                = string<br/>      sampled_requests_enabled   = bool<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | n/a | `string` | `"default"` | no |
| <a name="input_visibility_config"></a> [visibility\_config](#input\_visibility\_config) | Visibility configuration for the WAF ACL | <pre>object({<br/>    cloudwatch_metrics_enabled = optional(bool, true)<br/>    metric_name                = optional(string)<br/>    sampled_requests_enabled   = optional(bool, true)<br/>  })</pre> | <pre>{<br/>  "cloudwatch_metrics_enabled": true,<br/>  "metric_name": null,<br/>  "sampled_requests_enabled": true<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_associated_resource_arn"></a> [associated\_resource\_arn](#output\_associated\_resource\_arn) | The ARN of the associated resource (if any) |
| <a name="output_association_id"></a> [association\_id](#output\_association\_id) | The ID of the WAF association (if created) |
| <a name="output_ip_sets"></a> [ip\_sets](#output\_ip\_sets) | Map of created IP sets |
| <a name="output_waf_acl_arn"></a> [waf\_acl\_arn](#output\_waf\_acl\_arn) | The ARN of the WAF WebACL |
| <a name="output_waf_acl_id"></a> [waf\_acl\_id](#output\_waf\_acl\_id) | The ID of the WAF WebACL |
| <a name="output_waf_acl_name"></a> [waf\_acl\_name](#output\_waf\_acl\_name) | The name of the WAF WebACL |
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