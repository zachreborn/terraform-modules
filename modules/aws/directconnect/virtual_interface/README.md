<!-- Blank module readme template -->
<a name="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<h3 align="center">AWS Direct Connect Virtual Interface Module</h3>

## Usage

Create a private virtual interface for VPC connectivity:

```hcl
module "dx_vif" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/directconnect/virtual_interface"

  vif_type         = "private"
  vif_name         = "my-private-vif"
  dx_connection_id = module.dx_connection.id
  vlan             = 100
  customer_address = "169.254.10.1/30"
  amazon_address   = "169.254.10.2/30"
  virtual_gateway_id = aws_vpn_gateway.example.id

  tags = {
    Environment = "production"
  }
}
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- BEGIN_TF_DOCS -->
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
