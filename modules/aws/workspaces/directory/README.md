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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">AWS WorkSpaces Directory Module</h3>
  <p align="center">
    This module registers one or more Amazon WorkSpaces directories, supporting Active Directory, external SAML 2.0, and certificate-based identity providers, plus POOLS directories for pooled/non-persistent desktops.
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
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
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

### Personal Directory Backed by an Existing AD Directory

```
module "workspaces_directory" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/workspaces/directory"

  directories = {
    corp = {
      directory_id = module.simple_ad.id
      subnet_ids   = [aws_subnet.a.id, aws_subnet.b.id]
    }
  }
}
```

### Personal Directory with an External SAML Identity Provider

```
module "workspaces_directory" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/workspaces/directory"

  directories = {
    corp = {
      directory_id = module.ad_connector.id
      subnet_ids   = [aws_subnet.a.id, aws_subnet.b.id]

      saml_properties = {
        status          = "ENABLED"
        user_access_url = "https://sso.example.com/"
      }
    }
  }
}
```

### POOLS Directory with a Customer-Managed Identity Provider

```
module "workspaces_directory" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/workspaces/directory"

  directories = {
    pool = {
      workspace_type                   = "POOLS"
      subnet_ids                       = [aws_subnet.a.id, aws_subnet.b.id]
      workspace_directory_name         = "pool-directory"
      workspace_directory_description  = "WorkSpaces Pools directory"
      user_identity_type               = "CUSTOMER_MANAGED"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- For `PERSONAL` directories: an existing AWS Directory Service directory, e.g. from `modules/aws/directory_service_simple_ad`, `modules/aws/directory_service_ad_connector`, or `modules/aws/directory_service_microsoftad`.
- `modules/aws/workspaces/service_role` (or an equivalent `workspaces_DefaultRole` IAM role) must exist in the account before WorkSpaces desktops can be provisioned against a directory registered by this module.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- This module only registers a directory with the WorkSpaces service (`aws_workspaces_directory`) -- it never creates the underlying AWS Directory Service directory, so the same directory-provisioning modules already in this repository can be reused regardless of identity-provider choice.
- Identity providers supported per entry: native Active Directory (via `directory_id`), external SAML 2.0 (`saml_properties`, e.g. Okta, Entra ID, an IAM Identity Center SAML application, or ADFS), and certificate-based authentication layered on SAML (`certificate_based_auth_properties`). `POOLS` directories set `user_identity_type` to `CUSTOMER_MANAGED` or `AWS_DIRECTORY_SERVICE` -- `AWS_IAM_IDENTITY_CENTER` is deliberately not supported, since `RegisterWorkspaceDirectory` requires an `IdcInstanceArn` for that identity type that the `aws_workspaces_directory` resource does not expose.
- Secure-by-default `self_service_permissions`, `workspace_access_properties`, and `workspace_creation_properties` follow AWS Well-Architected End User Computing Lens guidance (deny the web/zero-client device types, disable direct internet access, disable local administrator rights) -- override any field per entry as needed.
- Provisioning pooled/non-persistent desktops via `aws_workspaces_pool` (available in `hashicorp/aws` >= 6.54.0) is an intentional scoping decision for this module family, not a provider limitation: a pool manages a fleet-level capacity/timeout lifecycle rather than per-user `aws_workspaces_workspace` desktops, so it warrants its own dedicated child module (e.g. a future `modules/aws/workspaces/pool`) rather than being folded into this one. This module already supports registering a `POOLS`-type directory today, so it is ready to pair with that future child module.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.55.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_workspaces_directory.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/workspaces_directory) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_directories"></a> [directories](#input\_directories) | (Optional) Map of WorkSpaces directories to register, keyed by a caller-chosen logical name.<br/>This module does not create the underlying AWS Directory Service directory -- point directory\_id at a<br/>directory created by modules/aws/directory\_service\_simple\_ad, modules/aws/directory\_service\_ad\_connector,<br/>or modules/aws/directory\_service\_microsoftad (or an externally-managed one) for PERSONAL directories.<br/>Fields:<br/>  - directory\_id:                     (Required when workspace\_type = PERSONAL) ID of an existing AWS<br/>                                       Directory Service directory. Must be null when workspace\_type =<br/>                                       POOLS, since AWS generates the directory ID automatically in that<br/>                                       case.<br/>  - workspace\_type:                   (Optional) PERSONAL or POOLS. Defaults to "PERSONAL".<br/>  - subnet\_ids:                       (Optional) Subnet IDs (2, across different AZs) where this<br/>                                       directory resides.<br/>  - ip\_group\_ids:                     (Optional) IDs of WorkSpaces IP access control groups to associate,<br/>                                       e.g. the `ids` output of modules/aws/workspaces/ip\_group. Defaults<br/>                                       to [].<br/>  - ip\_group\_keys:                    (Optional) Keys into var.ip\_group\_id\_lookup, resolved into literal<br/>                                       IP group IDs and merged with ip\_group\_ids above. Defaults to [].<br/>  - region:                           (Optional) Region where this directory is managed. Defaults to the<br/>                                       Region set in the provider configuration.<br/>  - tenancy:                          (Optional) DEDICATED or SHARED.<br/>  - workspace\_directory\_name:         (Required when workspace\_type = POOLS) Name of the directory.<br/>  - workspace\_directory\_description:  (Required when workspace\_type = POOLS) Description of the directory.<br/>  - user\_identity\_type:               (Required when workspace\_type = POOLS) One of CUSTOMER\_MANAGED or<br/>                                       AWS\_DIRECTORY\_SERVICE. AWS\_IAM\_IDENTITY\_CENTER is not supported by<br/>                                       this module: RegisterWorkspaceDirectory requires an IdcInstanceArn<br/>                                       for that identity type, but the aws\_workspaces\_directory resource<br/>                                       does not expose an idc\_instance\_arn argument (as of<br/>                                       hashicorp/aws 6.54.0).<br/>  - active\_directory\_config:          (Optional, POOLS only -- rejected for PERSONAL) Active Directory<br/>                                       domain join settings. Fields: domain\_name (Required),<br/>                                       service\_account\_secret\_arn (Required, ARN of a Secrets Manager<br/>                                       secret holding the domain-join service account credentials).<br/>  - certificate\_based\_auth\_properties: (Optional) Certificate-based authentication (CBA) via an ACM<br/>                                       Private CA, layered on top of saml\_properties for smart-card /<br/>                                       passwordless authentication. Fields: certificate\_authority\_arn<br/>                                       (Optional; required when status = "ENABLED"), status (Optional,<br/>                                       defaults to "DISABLED"). Enabling CBA also requires saml\_properties<br/>                                       to be enabled.<br/>  - saml\_properties:                  (Optional) External SAML 2.0 identity provider integration (e.g.<br/>                                       Okta, Entra ID, an IAM Identity Center SAML application, or ADFS).<br/>                                       Fields: relay\_state\_parameter\_name (Optional, defaults to<br/>                                       "RelayState"), status (Optional, defaults to "DISABLED"),<br/>                                       user\_access\_url (Optional; required when status = "ENABLED").<br/>  - self\_service\_permissions:         (Optional, PERSONAL only -- ignored/omitted for POOLS directories)<br/>                                       Secure-by-default: only restart\_workspace is enabled; every other<br/>                                       self-service action is disabled unless explicitly turned on.<br/>  - workspace\_access\_properties:      (Optional) Secure-by-default: denies the web browser and zero<br/>                                       client device types to shrink egress channels, allows native OS<br/>                                       clients (Windows, macOS, Linux, iOS, Android, ChromeOS).<br/>  - workspace\_creation\_properties:    (Optional) Secure-by-default: enable\_internet\_access = false<br/>                                       (desktops rely on VPC routing instead of a direct internet path),<br/>                                       enable\_maintenance\_mode = true, user\_enabled\_as\_local\_administrator<br/>                                       = false. For workspace\_type = POOLS entries, enable\_maintenance\_mode<br/>                                       and user\_enabled\_as\_local\_administrator are always forced to false<br/>                                       regardless of this setting, since AWS rejects both when set for a<br/>                                       POOLS directory; default\_ou may only be set when<br/>                                       active\_directory\_config is also set.<br/>  - tags:                             (Optional) Additional tags for this directory, merged with var.tags. | <pre>map(object({<br/>    directory_id                    = optional(string)<br/>    workspace_type                  = optional(string, "PERSONAL")<br/>    subnet_ids                      = optional(list(string))<br/>    ip_group_ids                    = optional(list(string), [])<br/>    ip_group_keys                   = optional(list(string), [])<br/>    region                          = optional(string)<br/>    tenancy                         = optional(string)<br/>    workspace_directory_name        = optional(string)<br/>    workspace_directory_description = optional(string)<br/>    user_identity_type              = optional(string)<br/><br/>    active_directory_config = optional(object({<br/>      domain_name                = string<br/>      service_account_secret_arn = string<br/>    }))<br/><br/>    certificate_based_auth_properties = optional(object({<br/>      certificate_authority_arn = optional(string)<br/>      status                    = optional(string, "DISABLED")<br/>    }))<br/><br/>    saml_properties = optional(object({<br/>      relay_state_parameter_name = optional(string, "RelayState")<br/>      status                     = optional(string, "DISABLED")<br/>      user_access_url            = optional(string)<br/>    }))<br/><br/>    self_service_permissions = optional(object({<br/>      change_compute_type  = optional(bool, false)<br/>      increase_volume_size = optional(bool, false)<br/>      rebuild_workspace    = optional(bool, false)<br/>      restart_workspace    = optional(bool, true)<br/>      switch_running_mode  = optional(bool, false)<br/>    }), {})<br/><br/>    workspace_access_properties = optional(object({<br/>      device_type_android    = optional(string, "ALLOW")<br/>      device_type_chromeos   = optional(string, "ALLOW")<br/>      device_type_ios        = optional(string, "ALLOW")<br/>      device_type_linux      = optional(string, "ALLOW")<br/>      device_type_osx        = optional(string, "ALLOW")<br/>      device_type_web        = optional(string, "DENY")<br/>      device_type_windows    = optional(string, "ALLOW")<br/>      device_type_zeroclient = optional(string, "DENY")<br/>    }), {})<br/><br/>    workspace_creation_properties = optional(object({<br/>      custom_security_group_id            = optional(string)<br/>      default_ou                          = optional(string)<br/>      enable_internet_access              = optional(bool, false)<br/>      enable_maintenance_mode             = optional(bool, true)<br/>      user_enabled_as_local_administrator = optional(bool, false)<br/>    }), {})<br/><br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_ip_group_id_lookup"></a> [ip\_group\_id\_lookup](#input\_ip\_group\_id\_lookup) | (Optional) Map of WorkSpaces IP access control group IDs keyed by logical name, e.g. the `ids` output of modules/aws/workspaces/ip\_group. Referenced by each directories entry's ip\_group\_keys. | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to every directory, merged with each entry's optional per-directory tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_aliases"></a> [aliases](#output\_aliases) | Map of WorkSpaces directory aliases, keyed by the same keys as var.directories. |
| <a name="output_customer_user_names"></a> [customer\_user\_names](#output\_customer\_user\_names) | Map of service account user names, keyed by the same keys as var.directories. |
| <a name="output_directory_names"></a> [directory\_names](#output\_directory\_names) | Map of directory names, keyed by the same keys as var.directories. |
| <a name="output_directory_types"></a> [directory\_types](#output\_directory\_types) | Map of directory types, keyed by the same keys as var.directories. |
| <a name="output_dns_ip_addresses"></a> [dns\_ip\_addresses](#output\_dns\_ip\_addresses) | Map of the list of DNS server IP addresses for each directory, keyed by the same keys as var.directories. |
| <a name="output_iam_role_ids"></a> [iam\_role\_ids](#output\_iam\_role\_ids) | Map of the IAM role identifiers Amazon WorkSpaces uses to call other AWS services on each directory's behalf, keyed by the same keys as var.directories. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of WorkSpaces directory IDs, keyed by the same keys as var.directories. For PERSONAL directories this equals the underlying directory\_id; for POOLS directories this is the ID AWS generated automatically. |
| <a name="output_registration_codes"></a> [registration\_codes](#output\_registration\_codes) | Map of directory registration codes (entered by users in the WorkSpaces client to connect), keyed by the same keys as var.directories. |
| <a name="output_workspace_security_group_ids"></a> [workspace\_security\_group\_ids](#output\_workspace\_security\_group\_ids) | Map of the security group IDs assigned to new WorkSpaces desktops in each directory, keyed by the same keys as var.directories. |
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
- [Brad Engberg](https://github.com/bradms98)

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
