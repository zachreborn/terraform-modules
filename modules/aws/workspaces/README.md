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

<h3 align="center">AWS WorkSpaces Module</h3>
  <p align="center">
    This module composes the modules/aws/workspaces child modules into a best-practices Amazon WorkSpaces deployment supporting multiple identity providers and Windows/Linux desktops.
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
    <li><a href="#scaling-to-hundreds-or-thousands-of-desktops">Scaling to Hundreds or Thousands of Desktops</a></li>
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

This is a parent module that composes the independently-usable child modules in this directory
(`service_role`, `directory`, `ip_group`, `connection_alias`, `workspace`) -- the same parent/child pattern
used by `modules/aws/organizations`. Call the child modules directly instead if you only need one piece
(e.g. just `modules/aws/workspaces/workspace` to add desktops to an already-registered directory).

### End-to-End Example: IP Group + Directory + Mixed OS Desktops

```
module "workspaces" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/workspaces"

  ip_groups = {
    corporate_offices = {
      rules = [
        { source = "10.0.2.0/24", description = "HQ" },
      ]
    }
  }

  directories = {
    corp = {
      directory_id    = aws_directory_service_directory.corp.id
      subnet_ids      = [aws_subnet.a.id, aws_subnet.b.id]
      ip_group_keys   = ["corporate_offices"]
    }
  }

  workspaces = {
    jdoe = {
      directory_key = "corp"
      user_name     = "jdoe"
      bundle_name   = "Value with Windows 10 (English)"
    }
    asmith = {
      directory_key = "corp"
      user_name     = "asmith"
      bundle_name   = "Ubuntu 22.04"
    }
  }

  tags = {
    team = "it"
  }
}
```

### Attaching Desktops to an Already-Existing Directory

```
module "workspaces" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/workspaces"

  enable_service_role = false # workspaces_DefaultRole already exists in this account

  workspaces = {
    jdoe = {
      directory_id = "d-1234567890" # externally-managed directory, referenced literally
      user_name    = "jdoe"
      bundle_name  = "Ubuntu 22.04"
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- For `PERSONAL` directories: an existing AWS Directory Service directory, e.g. from `modules/aws/directory_service_simple_ad`, `modules/aws/directory_service_ad_connector`, or `modules/aws/directory_service_microsoftad`.
- Each `user_name` referenced by `var.workspaces` must already exist in its target directory.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- Mirrors `modules/aws/organizations`'s parent/child structure: every child module in this directory is independently sourceable, and this parent module only adds composition, cross-child wiring, and opinionated bool toggles on top.
- Cross-child wiring mirrors the `parent_id`/`parent_key` pattern used by `modules/aws/organizations/account`: `directories` entries may set `ip_group_keys` (resolved against `var.ip_groups`), and `workspaces` entries may set `directory_key` (resolved against `var.directories`), instead of requiring literal IDs for resources created in the same module call.
- `enable_service_role`, `service_role_name`, and `enable_self_service_access` control the `service_role` child module. `enable_default_kms_key` and `kms_key_alias_prefix` are forwarded to the `workspace` child module.
- Identity providers, secure-by-default directory/desktop settings, and the `aws_workspaces_pool` scoping decision are documented in the `directory` and `workspace` child modules' own READMEs.
- A caller managing a large desktop fleet can maintain `directories`/`ip_groups`/`connection_aliases`/`workspaces` as YAML and decode it with `yamldecode(file(...))` before passing it to this module -- these are plain `map(object(...))` variables, so no special YAML support is needed in the module itself, consistent with every other module in this repository. See `modules/aws/workspaces/examples/yaml_fleet` for a complete, runnable example.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Scaling to Hundreds or Thousands of Desktops

`modules/aws/workspaces/examples/yaml_fleet` demonstrates a pattern that keeps a large fleet's YAML small: group desktops by shared attributes (directory, bundle) and list only usernames per group, then expand that into the full `workspaces` map with a `for` expression -- adding the 1,000th user only means adding a line to a list, never more HCL. The `workspace` child module also deduplicates bundle lookups and shares one default KMS key across the whole fleet regardless of size (see its README's "Scaling to Hundreds or Thousands of Desktops" section for the mechanics, plus service-quota and `-parallelism` guidance for very large applies).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_connection_aliases"></a> [connection\_aliases](#module\_connection\_aliases) | ./connection_alias | n/a |
| <a name="module_directories"></a> [directories](#module\_directories) | ./directory | n/a |
| <a name="module_ip_groups"></a> [ip\_groups](#module\_ip\_groups) | ./ip_group | n/a |
| <a name="module_service_role"></a> [service\_role](#module\_service\_role) | ./service_role | n/a |
| <a name="module_workspaces"></a> [workspaces](#module\_workspaces) | ./workspace | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_connection_aliases"></a> [connection\_aliases](#input\_connection\_aliases) | (Optional) Map of WorkSpaces connection aliases (cross-Region redirection FQDNs) to create, keyed by a caller-chosen logical name. Identical shape to modules/aws/workspaces/connection\_alias's own connection\_aliases variable. | <pre>map(object({<br/>    connection_string = string<br/>    region            = optional(string)<br/>    tags              = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_directories"></a> [directories](#input\_directories) | (Optional) Map of WorkSpaces directories to register, identical shape to modules/aws/workspaces/directory's<br/>own directories variable, including ip\_group\_keys: a list of keys into var.ip\_groups, resolved through<br/>this module's own wiring (ip\_group\_id\_lookup, wired to the ip\_groups submodule's ids output) into literal<br/>IP group IDs and merged with any literal ip\_group\_ids also supplied -- this lets a single tofu apply of<br/>this module create IP groups and a directory that references them together. An invalid key is rejected<br/>immediately by this variable's own validation below, and defensively by the directory submodule's own<br/>precondition; see that module's README for the full field reference. | <pre>map(object({<br/>    directory_id                    = optional(string)<br/>    workspace_type                  = optional(string, "PERSONAL")<br/>    subnet_ids                      = optional(list(string))<br/>    ip_group_ids                    = optional(list(string), [])<br/>    ip_group_keys                   = optional(list(string), [])<br/>    region                          = optional(string)<br/>    tenancy                         = optional(string)<br/>    workspace_directory_name        = optional(string)<br/>    workspace_directory_description = optional(string)<br/>    user_identity_type              = optional(string)<br/><br/>    active_directory_config = optional(object({<br/>      domain_name                = string<br/>      service_account_secret_arn = string<br/>    }))<br/><br/>    certificate_based_auth_properties = optional(object({<br/>      certificate_authority_arn = optional(string)<br/>      status                    = optional(string, "DISABLED")<br/>    }))<br/><br/>    saml_properties = optional(object({<br/>      relay_state_parameter_name = optional(string, "RelayState")<br/>      status                     = optional(string, "DISABLED")<br/>      user_access_url            = optional(string)<br/>    }))<br/><br/>    self_service_permissions = optional(object({<br/>      change_compute_type  = optional(bool, false)<br/>      increase_volume_size = optional(bool, false)<br/>      rebuild_workspace    = optional(bool, false)<br/>      restart_workspace    = optional(bool, true)<br/>      switch_running_mode  = optional(bool, false)<br/>    }), {})<br/><br/>    workspace_access_properties = optional(object({<br/>      device_type_android    = optional(string, "ALLOW")<br/>      device_type_chromeos   = optional(string, "ALLOW")<br/>      device_type_ios        = optional(string, "ALLOW")<br/>      device_type_linux      = optional(string, "ALLOW")<br/>      device_type_osx        = optional(string, "ALLOW")<br/>      device_type_web        = optional(string, "DENY")<br/>      device_type_windows    = optional(string, "ALLOW")<br/>      device_type_zeroclient = optional(string, "DENY")<br/>    }), {})<br/><br/>    workspace_creation_properties = optional(object({<br/>      custom_security_group_id            = optional(string)<br/>      default_ou                          = optional(string)<br/>      enable_internet_access              = optional(bool, false)<br/>      enable_maintenance_mode             = optional(bool, true)<br/>      user_enabled_as_local_administrator = optional(bool, false)<br/>    }), {})<br/><br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_default_kms_key"></a> [enable\_default\_kms\_key](#input\_enable\_default\_kms\_key) | (Optional) If true (the default), passed through to the workspace submodule so it creates one shared AWS KMS customer-managed key for every workspaces entry that omits volume\_encryption\_key. Set to false to require every entry to supply its own volume\_encryption\_key, or to rely on the AWS-managed alias/aws/workspaces key by leaving volume\_encryption\_key null. | `bool` | `true` | no |
| <a name="input_enable_self_service_access"></a> [enable\_self\_service\_access](#input\_enable\_self\_service\_access) | (Optional) If true (the default), additionally attaches the AmazonWorkSpacesSelfServiceAccess managed policy to the service role created when enable\_service\_role is true. Passed through to the service\_role submodule, whose own default matches this one -- see that module's variable for the rationale (directories default restart\_workspace = true, so the role needs this policy for that to actually work). | `bool` | `true` | no |
| <a name="input_enable_service_role"></a> [enable\_service\_role](#input\_enable\_service\_role) | (Optional) If true (the default), creates the account-wide workspaces\_DefaultRole IAM role via the service\_role submodule. Set to false when the role already exists (e.g. created by a prior call to this module in another region) -- WorkSpaces desktops still require the role to exist somewhere in the account. | `bool` | `true` | no |
| <a name="input_ip_groups"></a> [ip\_groups](#input\_ip\_groups) | (Optional) Map of WorkSpaces IP access control groups to create, keyed by a caller-chosen logical name. Identical shape to modules/aws/workspaces/ip\_group's own ip\_groups variable. Referenced by var.directories entries via ip\_group\_keys. | <pre>map(object({<br/>    name        = optional(string)<br/>    description = optional(string)<br/>    region      = optional(string)<br/>    rules = optional(list(object({<br/>      source      = string<br/>      description = optional(string)<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_kms_key_alias_prefix"></a> [kms\_key\_alias\_prefix](#input\_kms\_key\_alias\_prefix) | (Optional) Passed through to the workspace submodule's kms\_key\_alias\_prefix field. Ignored when enable\_default\_kms\_key is false or no entry needs the shared key. See that submodule's variable for the exact alias-naming behavior (a generated suffix is appended to this prefix). | `string` | `"workspaces"` | no |
| <a name="input_service_role_name"></a> [service\_role\_name](#input\_service\_role\_name) | (Optional) Name of the IAM role created when enable\_service\_role is true. Passed through to the service\_role submodule's name field. | `string` | `"workspaces_DefaultRole"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags applied to every resource created by this module (the service role, IP groups, directories, connection aliases, desktops, and the shared default KMS key), merged with each entry's optional per-resource tags. | `map(string)` | `{}` | no |
| <a name="input_workspaces"></a> [workspaces](#input\_workspaces) | (Optional) Map of WorkSpaces desktops to create, identical shape to modules/aws/workspaces/workspace's<br/>own workspaces variable, including directory\_key: a key into var.directories, resolved through this<br/>module's own wiring (directory\_id\_lookup, wired to the directories submodule's ids output) into a<br/>literal directory ID -- this lets a single tofu apply of this module create a directory and the desktops<br/>that attach to it together. Entries that instead target an already-existing, externally-managed directory<br/>should keep using the literal directory\_id field. An invalid directory\_key is rejected immediately by<br/>this variable's own validation below, and defensively by the workspace submodule's own precondition;<br/>see that module's README for the full field reference. | <pre>map(object({<br/>    directory_id  = optional(string)<br/>    directory_key = optional(string)<br/>    user_name     = string<br/>    bundle_id     = optional(string)<br/>    bundle_name   = optional(string)<br/>    bundle_owner  = optional(string, "AMAZON")<br/><br/>    root_volume_encryption_enabled = optional(bool, true)<br/>    user_volume_encryption_enabled = optional(bool, true)<br/>    volume_encryption_key          = optional(string)<br/>    region                         = optional(string)<br/><br/>    workspace_properties = optional(object({<br/>      compute_type_name                         = optional(string, "STANDARD")<br/>      root_volume_size_gib                      = optional(number, 80)<br/>      running_mode                              = optional(string, "AUTO_STOP")<br/>      running_mode_auto_stop_timeout_in_minutes = optional(number, 60)<br/>      user_volume_size_gib                      = optional(number, 50)<br/>    }), {})<br/><br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_connection_alias_ids"></a> [connection\_alias\_ids](#output\_connection\_alias\_ids) | Map of WorkSpaces connection alias IDs, keyed by the same keys as var.connection\_aliases. |
| <a name="output_directory_aliases"></a> [directory\_aliases](#output\_directory\_aliases) | Map of WorkSpaces directory aliases, keyed by the same keys as var.directories. |
| <a name="output_directory_dns_ip_addresses"></a> [directory\_dns\_ip\_addresses](#output\_directory\_dns\_ip\_addresses) | Map of the list of DNS server IP addresses for each directory, keyed by the same keys as var.directories. |
| <a name="output_directory_ids"></a> [directory\_ids](#output\_directory\_ids) | Map of WorkSpaces directory IDs, keyed by the same keys as var.directories. |
| <a name="output_directory_registration_codes"></a> [directory\_registration\_codes](#output\_directory\_registration\_codes) | Map of directory registration codes (entered by users in the WorkSpaces client to connect), keyed by the same keys as var.directories. |
| <a name="output_directory_workspace_security_group_ids"></a> [directory\_workspace\_security\_group\_ids](#output\_directory\_workspace\_security\_group\_ids) | Map of the security group IDs assigned to new WorkSpaces desktops in each directory, keyed by the same keys as var.directories. |
| <a name="output_ip_group_ids"></a> [ip\_group\_ids](#output\_ip\_group\_ids) | Map of WorkSpaces IP access control group IDs, keyed by the same keys as var.ip\_groups. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the shared default KMS key created for volume encryption, or null when enable\_default\_kms\_key is false or no entry needed it. |
| <a name="output_service_role_arn"></a> [service\_role\_arn](#output\_service\_role\_arn) | ARN of the workspaces\_DefaultRole IAM role, or null when enable\_service\_role is false. |
| <a name="output_service_role_name"></a> [service\_role\_name](#output\_service\_role\_name) | Name of the workspaces\_DefaultRole IAM role, or null when enable\_service\_role is false. |
| <a name="output_workspace_computer_names"></a> [workspace\_computer\_names](#output\_workspace\_computer\_names) | Map of WorkSpaces desktop computer names (as seen by the operating system), keyed by the same keys as var.workspaces. |
| <a name="output_workspace_ids"></a> [workspace\_ids](#output\_workspace\_ids) | Map of WorkSpaces desktop IDs, keyed by the same keys as var.workspaces. |
| <a name="output_workspace_ip_addresses"></a> [workspace\_ip\_addresses](#output\_workspace\_ip\_addresses) | Map of WorkSpaces desktop IP addresses, keyed by the same keys as var.workspaces. |
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
