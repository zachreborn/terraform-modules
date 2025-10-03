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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Route53 Registered Domain</h3>
  <p align="center">
    This module manages the registration of a domain with Route53. This module does not create a registar, but per Terraform will manage the registration of a domain already transfered or registered with Route53.
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

This example will manage a registered domain with Route53. The domain will be registered with the provided contact information. The domain will be registered with the provided name servers. The domain will be locked from transfer. The domain will be set to auto renew.

```hcl
module "registered_domains" {
  source             = "github.com/zachreborn/terraform-modules//modules/aws/route53/registered_domain"
  admin_contact      = var.my_contact_info
  registrant_contact = var.my_contact_info
  tech_contact       = var.my_contact_info
  domains = {
    "example.com" = {
      auto_renew    = true
      name_servers  = module.example_com.name_servers
      transfer_lock = true
    },
    "example.org" = {
      auto_renew    = true
      name_servers  = [
        "ns-123.awsdns-12.org",
        "ns-456.awsdns-34.org"
        "ns-123.awsdns-56.org",
      ]
      transfer_lock = true
    }
  }

  tags = {
    terraform   = "true"
    created_by  = "John Doe"
    environment = "prod"
    role        = "external dns"
  }
}

variable "my_contact_info" {
  description = "Domain name registration contact information."
  default = {
    address_line_1    = "123 Broadway Ave"
    address_line_2    = ""
    city              = "Duluth"
    contact_type      = "Company"
    country_code      = "US"
    email             = "me@example.org"
    extra_params      = {}
    fax               = ""
    first_name        = "John"
    last_name         = "Doe"
    organization_name = "Example"
    phone_number      = "+1.5551234567"
    state             = "MN"
    zip_code          = "11111"
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route53domains_registered_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53domains_registered_domain) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_contact"></a> [admin\_contact](#input\_admin\_contact) | The admin contact information for the domain. | <pre>object({<br/>    address_line_1    = string<br/>    address_line_2    = string<br/>    city              = string<br/>    contact_type      = string<br/>    country_code      = string<br/>    email             = string<br/>    extra_params      = map(any)<br/>    fax               = string<br/>    first_name        = string<br/>    last_name         = string<br/>    organization_name = string<br/>    phone_number      = string<br/>    state             = string<br/>    zip_code          = string<br/>  })</pre> | n/a | yes |
| <a name="input_admin_privacy"></a> [admin\_privacy](#input\_admin\_privacy) | Whether to enable admin privacy protection. Default is true. | `bool` | `true` | no |
| <a name="input_domains"></a> [domains](#input\_domains) | A map of domains to register with Route53. | <pre>map(object({<br/>    auto_renew    = bool<br/>    name_servers  = list(string)<br/>    transfer_lock = bool<br/>  }))</pre> | n/a | yes |
| <a name="input_registrant_contact"></a> [registrant\_contact](#input\_registrant\_contact) | The registrant contact information for the domain. | <pre>object({<br/>    address_line_1    = string<br/>    address_line_2    = string<br/>    city              = string<br/>    contact_type      = string<br/>    country_code      = string<br/>    email             = string<br/>    extra_params      = map(any)<br/>    fax               = string<br/>    first_name        = string<br/>    last_name         = string<br/>    organization_name = string<br/>    phone_number      = string<br/>    state             = string<br/>    zip_code          = string<br/>  })</pre> | n/a | yes |
| <a name="input_registrant_privacy"></a> [registrant\_privacy](#input\_registrant\_privacy) | Whether to enable registrant privacy protection. Default is true. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_tech_contact"></a> [tech\_contact](#input\_tech\_contact) | The tech contact information for the domain. | <pre>object({<br/>    address_line_1    = string<br/>    address_line_2    = string<br/>    city              = string<br/>    contact_type      = string<br/>    country_code      = string<br/>    email             = string<br/>    extra_params      = map(any)<br/>    fax               = string<br/>    first_name        = string<br/>    last_name         = string<br/>    organization_name = string<br/>    phone_number      = string<br/>    state             = string<br/>    zip_code          = string<br/>  })</pre> | n/a | yes |
| <a name="input_tech_privacy"></a> [tech\_privacy](#input\_tech\_privacy) | Whether to enable tech privacy protection. Default is true. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_creation_dates"></a> [creation\_dates](#output\_creation\_dates) | The creation date of the domain. |
| <a name="output_expiration_dates"></a> [expiration\_dates](#output\_expiration\_dates) | The expiration date of the domain. |
| <a name="output_updated_dates"></a> [updated\_dates](#output\_updated\_dates) | The last updated date of the domain. |
| <a name="output_whois_servers"></a> [whois\_servers](#output\_whois\_servers) | The whois server of the domain. |
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
