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

<h3 align="center">AWS Direct Connect Connection Module</h3>
  <p align="center">
    A Terraform module for creating and managing AWS Direct Connect connections with optional MACsec encryption.
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

## Usage

### Dedicated 10 Gbps Connection with MACsec

Create a dedicated Direct Connect connection at a supported location with MACsec encryption. The `location` argument must be a Direct Connect location code (from `aws dx describe-locations`, e.g. `EqDC2` for Equinix Ashburn DC2), not an AWS region.

```hcl
module "dx_connection" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/directconnect/connection"

  connection_name = "my-dx-connection"
  location        = "EqDC2" # Direct Connect locationCode, e.g. Equinix Ashburn DC2
  bandwidth       = "10Gbps"
  request_macsec  = true

  tags = {
    Environment = "production"
    Team        = "network"
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
| [aws_dx_connection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dx_connection) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bandwidth"></a> [bandwidth](#input\_bandwidth) | (Required) The bandwidth of the connection. Valid values for dedicated connections: 1Gbps, 10Gbps, 100Gbps. Valid values for hosted connections: 50Mbps, 100Mbps, 200Mbps, 300Mbps, 400Mbps, 500Mbps, 1Gbps, 2Gbps, 5Gbps, 10Gbps. | `string` | n/a | yes |
| <a name="input_connection_name"></a> [connection\_name](#input\_connection\_name) | (Required) The name of the connection. | `string` | n/a | yes |
| <a name="input_encryption_mode"></a> [encryption\_mode](#input\_encryption\_mode) | (Optional) The MACsec encryption mode for the connection. Valid values are must\_encrypt, should\_encrypt, or no\_encrypt. Only applicable when request\_macsec is true; defaults to AWS's standard behavior when unset. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | (Required) The AWS Direct Connect location where the connection is located. See DescribeLocations for the list of AWS Direct Connect locations. Use locationCode. | `string` | n/a | yes |
| <a name="input_provider_name"></a> [provider\_name](#input\_provider\_name) | (Optional) The name of the service provider associated with the connection. | `string` | `null` | no |
| <a name="input_request_macsec"></a> [request\_macsec](#input\_request\_macsec) | (Optional) Request MACsec encryption on the connection. MACsec is available only on dedicated connections. Defaults to false. | `bool` | `false` | no |
| <a name="input_skip_destroy"></a> [skip\_destroy](#input\_skip\_destroy) | (Optional) Set to true to prevent Terraform from deleting the connection if there are virtual interfaces. The connection may only be deleted when empty. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the connection. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the Direct Connect connection. |
| <a name="output_aws_device"></a> [aws\_device](#output\_aws\_device) | The Direct Connect endpoint on which the physical connection terminates. |
| <a name="output_bandwidth"></a> [bandwidth](#output\_bandwidth) | The bandwidth of the Direct Connect connection. |
| <a name="output_encryption_mode"></a> [encryption\_mode](#output\_encryption\_mode) | The MACsec encryption mode of the connection. |
| <a name="output_has_logical_redundancy"></a> [has\_logical\_redundancy](#output\_has\_logical\_redundancy) | Indicates whether the connection has logical redundancy. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the Direct Connect connection. |
| <a name="output_jumbo_frame_capable"></a> [jumbo\_frame\_capable](#output\_jumbo\_frame\_capable) | Boolean value indicating whether jumbo frames (9000 MTU) are supported. |
| <a name="output_location"></a> [location](#output\_location) | The location of the Direct Connect connection. |
| <a name="output_macsec_capable"></a> [macsec\_capable](#output\_macsec\_capable) | Boolean value indicating whether the connection supports MACsec. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Direct Connect connection. |
| <a name="output_owner_account_id"></a> [owner\_account\_id](#output\_owner\_account\_id) | The ID of the AWS account that owns the connection. |
| <a name="output_partner_name"></a> [partner\_name](#output\_partner\_name) | The name of the AWS Direct Connect service provider associated with the connection. |
| <a name="output_port_encryption_status"></a> [port\_encryption\_status](#output\_port\_encryption\_status) | The MACsec port link status of the connection. |
| <a name="output_provider_name"></a> [provider\_name](#output\_provider\_name) | The name of the service provider associated with the connection. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | A map of tags assigned to the resource, including those inherited from the provider default\_tags configuration block. |
| <a name="output_vlan_id"></a> [vlan\_id](#output\_vlan\_id) | The VLAN ID of the connection. |
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
