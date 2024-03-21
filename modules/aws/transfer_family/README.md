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

<h3 align="center">Transfer Family Module</h3>
  <p align="center">
    module_description
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
The following example creates a new SFTP server using the default settings. Settings include: S3 backend storage, public access, built in users, and SFTP transfer porotocol.
```
module "vendor_sftp" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/transfer_family"

  tags = {
    created_by = "<YOUR NAME>"
    role       = "vendor sftp"
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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bucket"></a> [bucket](#module\_bucket) | ../s3/bucket | n/a |
| <a name="module_transfer_family_iam_role"></a> [transfer\_family\_iam\_role](#module\_transfer\_family\_iam\_role) | ../iam/role | n/a |
| <a name="module_transfer_family_iam_role_policy"></a> [transfer\_family\_iam\_role\_policy](#module\_transfer\_family\_iam\_role\_policy) | ../iam/policy | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_transfer_server.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_server) | resource |
| [aws_transfer_ssh_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_ssh_key) | resource |
| [aws_transfer_user.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_user) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_allocation_ids"></a> [address\_allocation\_ids](#input\_address\_allocation\_ids) | (Optional) A list of address allocation IDs that are required to attach an Elastic IP address to your server's endpoint. This can only be set when 'var.endpoint\_type' is set to 'VPC' | `list(string)` | `[]` | no |
| <a name="input_as2_transports"></a> [as2\_transports](#input\_as2\_transports) | (Optional) The transport method for AS2 messages. Valid values are HTTP. | `list(string)` | `null` | no |
| <a name="input_certificate"></a> [certificate](#input\_certificate) | (Optional) The ARN of the AWS Certificate Manager certificate to use with the server | `string` | `null` | no |
| <a name="input_directory_id"></a> [directory\_id](#input\_directory\_id) | (Optional) The ID of the AWS Directory Service directory that you want to associate with the server | `string` | `null` | no |
| <a name="input_endpoint_type"></a> [endpoint\_type](#input\_endpoint\_type) | (Optional) The type of endpoint that you want your server to use. Valid values are VPC and PUBLIC | `string` | `"PUBLIC"` | no |
| <a name="input_function"></a> [function](#input\_function) | (Optional) The ARN of the AWS Lambda function that is invoked for user authentication | `string` | `null` | no |
| <a name="input_host_key"></a> [host\_key](#input\_host\_key) | (Optional) The RSA, ECDSA, or ED25519 private key. This must be created ahead of time. | `string` | `null` | no |
| <a name="input_identity_provider_type"></a> [identity\_provider\_type](#input\_identity\_provider\_type) | (Optional) The mode of authentication enabled for this service. Valid values are SERVICE\_MANAGED or API\_GATEWAY | `string` | `"SERVICE_MANAGED"` | no |
| <a name="input_invocation_role"></a> [invocation\_role](#input\_invocation\_role) | (Optional) The ARN of the IAM role that controls your authentication with an identity provider\_type through API\_GATEWAY. | `string` | `null` | no |
| <a name="input_logging_role"></a> [logging\_role](#input\_logging\_role) | (Optional) The ARN of the IAM role that allows the service to write your server access logs to a Amazon CloudWatch log group. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the AWS Transfer Family server used to name the resources created. | `string` | n/a | yes |
| <a name="input_passive_ip"></a> [passive\_ip](#input\_passive\_ip) | (Optional) Sets passive mode for FTP and FTPS protocols and the associated IPv4 address to associate. | `string` | `null` | no |
| <a name="input_post_authentication_login_banner"></a> [post\_authentication\_login\_banner](#input\_post\_authentication\_login\_banner) | (Optional) The banner message which is displayed to users after they authenticate to the server. | `string` | `null` | no |
| <a name="input_pre_authentication_login_banner"></a> [pre\_authentication\_login\_banner](#input\_pre\_authentication\_login\_banner) | (Optional) The banner message which is displayed to users before they authenticate to the server. | `string` | `null` | no |
| <a name="input_protocols"></a> [protocols](#input\_protocols) | (Optional) The list of protocol settings that are configured for your server. Valid values are AS2, SFTP, FTP, and FTPS. | `list(string)` | <pre>[<br>  "SFTP"<br>]</pre> | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | (Optional) A list of security group IDs that are attached to the server's endpoint. (Optional) A list of security groups IDs that are available to attach to your server's endpoint. If no security groups are specified, the VPC's default security groups are automatically assigned to your endpoint. This property can only be used when endpoint\_type is set to VPC. | `list(string)` | `[]` | no |
| <a name="input_security_policy_name"></a> [security\_policy\_name](#input\_security\_policy\_name) | (Optional) Specifies the name of the security policy that is attached to the server.  Possible values are TransferSecurityPolicy-2018-11, TransferSecurityPolicy-2020-06, TransferSecurityPolicy-FIPS-2020-06, TransferSecurityPolicy-FIPS-2023-05, TransferSecurityPolicy-2022-03, TransferSecurityPolicy-2023-05, TransferSecurityPolicy-PQ-SSH-Experimental-2023-04, TransferSecurityPolicy-2024-01, and TransferSecurityPolicy-PQ-SSH-FIPS-Experimental-2023-04. Default value is: TransferSecurityPolicy-2024-01. | `string` | `"TransferSecurityPolicy-2024-01"` | no |
| <a name="input_set_stat_option"></a> [set\_stat\_option](#input\_set\_stat\_option) | (Optional) Specifies the behavior of your server endpoint when you use the STAT command. Valid values are: DEFAULT and ENABLE\_NO\_OP. | `string` | `null` | no |
| <a name="input_storage_location"></a> [storage\_location](#input\_storage\_location) | (Optional) The domain of the storage system that is used for file transfers. Valid values are: S3 and EFS. The default is S3. | `string` | `"S3"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | (Optional) A list of subnet IDs that are required to host your server endpoint in your VPC. This property can only be used when endpoint\_type is set to VPC. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Key-value mapping of resource tags | `map(string)` | <pre>{<br>  "terraform": "true"<br>}</pre> | no |
| <a name="input_tls_session_resumption_mode"></a> [tls\_session\_resumption\_mode](#input\_tls\_session\_resumption\_mode) | (Optional) Specifies the mode of the TLS session resumption. Valid values are: DISABLED, ENABLED, and ENFORCED. | `string` | `null` | no |
| <a name="input_url"></a> [url](#input\_url) | (Optional) The URL of the file transfer protocol endpoint that is used to authentication users through an API\_GATEWAY. | `string` | `null` | no |
| <a name="input_users"></a> [users](#input\_users) | (Optional) A map of user names and their configuration | <pre>map(object({<br>    home_directory      = optional(string)            # Cannot be set if home_directory_type is set to "LOGICAL".<br>    home_directory_type = optional(string, "LOGICAL") # Default is "LOGICAL"<br>    policy              = optional(string)            # Set for a custom session policy see https://docs.aws.amazon.com/transfer/latest/userguide/requirements-roles.html#session-policy for more information<br>    public_key          = optional(string)            # The public key portion of an SSH key pair<br>    username            = string<br>  }))</pre> | `{}` | no |
| <a name="input_vpc_endpoint_id"></a> [vpc\_endpoint\_id](#input\_vpc\_endpoint\_id) | (Optional) The ID of the VPC endpoint. This property can only be used when endpoint\_type is set to VPC. | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | (Optional) The ID of the VPC that is used for the transfer server. This property can only be used when endpoint\_type is set to VPC. | `string` | `null` | no |

## Outputs

No outputs.
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