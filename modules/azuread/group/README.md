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

<h3 align="center">Azure AD Group Module</h3>
  <p align="center">
    This module creates and manages Azure AD group resources.
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

```
module group_simple_example {
  source           = "github.com/zachreborn/terraform-modules//modules/azuread/group"
  display_name     = "example"
  owners           = [admin.objectid]
  security_enabled = true
}
```

### Microsoft 365 Group Example

```
module group_365_example {
  source           = "github.com/zachreborn/terraform-modules//modules/azuread/group"
  display_name     = "example"
  mail_enabled     = true
  mail_nickname    = "ExampleGroup"
  owners           = [admin.objectid]
  security_enabled = true
  types            = ["Unified"]
}
```

### Dynamic Membership Group Example

This configures an Azure AD security group which utilizes dynamic membership rules to manage group membership.

```
module group_app_terraform {
  source           = "github.com/zachreborn/terraform-modules//modules/azuread/group"
  display_name     = "app_terraform"
  owners           = [admin.objectid]
  security_enabled = true
  types            = ["DynamicMembership"]

  dynamic_membership = {
    enabled = true
    rule    = "user.department -eq \"DevOps\""
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
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | >= 2.36.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | >= 2.36.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_group.this](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_subscribe_new_members"></a> [auto\_subscribe\_new\_members](#input\_auto\_subscribe\_new\_members) | (Optional) Indicates whether new members added to the group will be auto-subscribed to receive email notifications. Can only be set for Unified groups. | `bool` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional) A description for the group. | `string` | `null` | no |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | (Required) The display name for the group. | `string` | n/a | yes |
| <a name="input_dynamic_membership"></a> [dynamic\_membership](#input\_dynamic\_membership) | (Optional) A dynamic membership block. Cannot be used with the members property. | <pre>object({<br/>    enabled = bool<br/>    rule    = string<br/>  })</pre> | `null` | no |
| <a name="input_external_senders_allowed"></a> [external\_senders\_allowed](#input\_external\_senders\_allowed) | (Optional) Indicates whether external senders can send messages to the group. Can only be set for Unified groups. | `bool` | `null` | no |
| <a name="input_hide_from_address_lists"></a> [hide\_from\_address\_lists](#input\_hide\_from\_address\_lists) | (Optional) Indicates whether the group is displayed in certain parts of the Outlook user interface: in the Address Book, in address lists for selecting message recipients, and in the Browse Groups dialog for searching groups. Can only be set for Unified groups. | `bool` | `null` | no |
| <a name="input_hide_from_outlook_clients"></a> [hide\_from\_outlook\_clients](#input\_hide\_from\_outlook\_clients) | (Optional) Indicates whether the group is displayed in Outlook clients, such as Outlook for Windows and Outlook on the web. Can only be set for Unified groups. | `bool` | `null` | no |
| <a name="input_mail_enabled"></a> [mail\_enabled](#input\_mail\_enabled) | (Optional) Whether the group is a mail enabled, with a shared group mailbox. At least one of mail\_enabled or security\_enabled must be specified. Only Microsoft 365 groups can be mail enabled (see the types property). | `bool` | `null` | no |
| <a name="input_mail_nickname"></a> [mail\_nickname](#input\_mail\_nickname) | (Optional) The mail alias for the group, unique in the organisation. Required for mail-enabled groups. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_members"></a> [members](#input\_members) | (Optional) A list of members who should be present in this group. Supported object types are Users, Groups or Service Principals. Cannot be used with the dynamic\_membership block. | `list(string)` | `null` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | (Optional) A set of object IDs of principals that will be granted ownership of the group. Supported object types are users or service principals. By default, the principal being used to execute Terraform is assigned as the sole owner. Groups cannot be created with no owners or have all their owners removed. | `list(string)` | `null` | no |
| <a name="input_prevent_duplicate_names"></a> [prevent\_duplicate\_names](#input\_prevent\_duplicate\_names) | (Optional) If true, will return an error if an existing group is found with the same name. Defaults to false. | `bool` | `null` | no |
| <a name="input_provisioning_options"></a> [provisioning\_options](#input\_provisioning\_options) | (Optional) A list of provisioning options for a Microsoft 365 group. The only supported value is Team. See official documentation for details. Changing this forces a new resource to be created. | `list(string)` | `null` | no |
| <a name="input_security_enabled"></a> [security\_enabled](#input\_security\_enabled) | (Optional) Whether the group is a security group for controlling access to in-app resources. At least one of security\_enabled or mail\_enabled must be specified. A Microsoft 365 group can be security enabled and mail enabled (see the types property). | `bool` | `null` | no |
| <a name="input_types"></a> [types](#input\_types) | (Optional) A list of group types to configure for the group. Supported values are DynamicMembership, which denotes a group with dynamic membership, and Unified, which specifies a Microsoft 365 group. Required when mail\_enabled is true. Changing this forces a new resource to be created. | `list(string)` | `null` | no |
| <a name="input_visibility"></a> [visibility](#input\_visibility) | (Optional) The group join policy and group content visibility. Possible values are Private, Public, or Hiddenmembership. Only Microsoft 365 groups can have Hiddenmembership visibility and this value must be set when the group is created. By default, security groups will receive Private visibility and Microsoft 365 groups will receive Public visibility. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mail"></a> [mail](#output\_mail) | The SMTP address for the group. |
| <a name="output_object_id"></a> [object\_id](#output\_object\_id) | The object ID of the Azure AD group. |
| <a name="output_proxy_addresses"></a> [proxy\_addresses](#output\_proxy\_addresses) | The proxy addresses for the group. |
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
