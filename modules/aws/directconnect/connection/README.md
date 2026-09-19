<!-- Blank module readme template: Do a search and replace with your text editor for the following: `module_name`, `module_description` -->
<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

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

<h3 align="center">Direct Connect Connection Module</h3>
  <p align="center">
    This module manages an AWS Direct Connect dedicated connection. Dedicated connections provide private, high-bandwidth connectivity between on-premises networks and AWS. See https://aws.amazon.com/directconnect/ for more information.
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

### Import an Existing Dedicated Connection

Dedicated DX connections are provisioned by AWS and cannot be created via Terraform. Import an existing connection and manage its tags and settings going forward. The module sets `prevent_destroy = true` to guard against accidental destruction.

```
module "dx_connection" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/directconnect/connection"

  name      = "My Company_Colocation_abc123"
  bandwidth = "5Gbps"
  location  = "ECPO1"

  tags = {
    terraform   = "true"
    environment = "prod"
    project     = "core_infrastructure"
  }
}

import {
  to = module.dx_connection.aws_dx_connection.this
  id = "dxcon-xxxxxxxx"
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- NOTES -->

## Notes / Design Decisions

- **`prevent_destroy = true` is hardcoded, not a variable.** Dedicated DX connections require physical provisioning by AWS/your carrier and cannot be recreated by Terraform, so this module unconditionally guards the resource against accidental destruction. There is intentionally no variable to toggle this off, because OpenTofu/Terraform's `prevent_destroy` argument must be a literal `true`/`false` — it cannot reference a module input variable. To decommission a circuit: cancel it with AWS/your carrier out-of-band first, then run `terraform state rm module.dx_connection.aws_dx_connection.this` (adjust the address for your module call) before removing the module block from your configuration.
- **MAC Security (MACsec) is opt-in, not on by default.** `request_macsec` defaults to `false` and `encryption_mode` defaults to `"no_encrypt"`. MACsec requires MACsec-capable hardware at both ends and is only available on specific dedicated-connection port speeds (10 Gbps and 100 Gbps) at MACsec-capable locations. Defaulting it on could cause connection requests to fail at locations/ports that don't support it, so callers must explicitly opt in via `request_macsec = true` and an `encryption_mode` once the connection reaches the `Available` state.

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
| <a name="input_bandwidth"></a> [bandwidth](#input\_bandwidth) | (Required) The bandwidth of the connection. Valid values for dedicated connections: 1Gbps, 10Gbps, 100Gbps, 400Gbps. Valid values for hosted connections: 50Mbps, 100Mbps, 200Mbps, 300Mbps, 400Mbps, 500Mbps, 1Gbps, 2Gbps, 5Gbps, 10Gbps, 25Gbps. Case sensitive. | `string` | n/a | yes |
| <a name="input_encryption_mode"></a> [encryption\_mode](#input\_encryption\_mode) | (Optional) The connection MAC Security (MACsec) encryption mode. Only available on dedicated connections. Valid values: no\_encrypt, should\_encrypt, must\_encrypt. | `string` | `"no_encrypt"` | no |
| <a name="input_location"></a> [location](#input\_location) | (Required) The AWS Direct Connect location where the connection is located. Use the locationCode value from describe-locations. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the Direct Connect connection. | `string` | n/a | yes |
| <a name="input_provider_name"></a> [provider\_name](#input\_provider\_name) | (Optional) The name of the service provider (carrier) associated with the connection. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region where this Direct Connect connection is managed. Defaults to the Region set in the provider configuration. | `string` | `null` | no |
| <a name="input_request_macsec"></a> [request\_macsec](#input\_request\_macsec) | (Optional) Whether to request MAC Security (MACsec) on the connection. Only supported on dedicated connections. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the connection. A Name tag is automatically added from var.name. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the Direct Connect connection. |
| <a name="output_aws_device"></a> [aws\_device](#output\_aws\_device) | The Direct Connect endpoint on which the physical connection terminates. |
| <a name="output_has_logical_redundancy"></a> [has\_logical\_redundancy](#output\_has\_logical\_redundancy) | Indicates whether the connection supports a secondary BGP peer in the same address family. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the Direct Connect connection. |
| <a name="output_jumbo_frame_capable"></a> [jumbo\_frame\_capable](#output\_jumbo\_frame\_capable) | Whether jumbo frames are enabled for this connection. |
| <a name="output_macsec_capable"></a> [macsec\_capable](#output\_macsec\_capable) | Whether the connection supports MAC Security (MACsec). |
| <a name="output_owner_account_id"></a> [owner\_account\_id](#output\_owner\_account\_id) | The ID of the AWS account that owns the connection. |
| <a name="output_partner_name"></a> [partner\_name](#output\_partner\_name) | The name of the AWS Direct Connect service provider (carrier) associated with the connection. |
| <a name="output_port_encryption_status"></a> [port\_encryption\_status](#output\_port\_encryption\_status) | The MAC Security (MACsec) port link status of the connection. |
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

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasaurus)

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
