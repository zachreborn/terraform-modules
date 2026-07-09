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

<h3 align="center">AWS WorkSpaces Desktop Module</h3>
  <p align="center">
    This module creates one or more Amazon WorkSpaces desktops (Windows or Linux) with encrypted volumes.
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

### Mixed Windows and Linux Desktops

```
module "workspaces" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/workspaces/workspace"

  workspaces = {
    jdoe = {
      directory_id = module.workspaces_directory.ids["corp"]
      user_name    = "jdoe"
      bundle_name  = "Value with Windows 10 (English)"
    }
    asmith = {
      directory_id = module.workspaces_directory.ids["corp"]
      user_name    = "asmith"
      bundle_name  = "Amazon Linux 2"
    }
  }
}
```

### Explicit Bundle ID and Caller-Supplied KMS Key

```
module "workspaces" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/workspaces/workspace"

  enable_default_kms_key = false

  workspaces = {
    jdoe = {
      directory_id           = module.workspaces_directory.ids["corp"]
      user_name               = "jdoe"
      bundle_id               = "wsb-bh8rsxt14"
      volume_encryption_key  = module.workspaces_kms_key.arn
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- A WorkSpaces directory, e.g. the `ids` output of `modules/aws/workspaces/directory`.
- `modules/aws/workspaces/service_role` (or an equivalent `workspaces_DefaultRole` IAM role) must exist in the account.
- Each `user_name` must already exist in the target directory.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- Windows vs. Linux is determined entirely by the WorkSpaces bundle -- set `bundle_id` directly, or set `bundle_name` (and optionally `bundle_owner`) to resolve it via a `data.aws_workspaces_bundle` lookup. The resource configuration is otherwise identical for both operating systems.
- Root and user volume encryption are enabled by default. When an entry does not supply its own `volume_encryption_key` and `enable_default_kms_key` is `true` (the default), this module composes `modules/aws/kms` to create one shared customer-managed key for every such entry, per this repository's module composition guidance -- it does not declare an inline `aws_kms_key`.
- `running_mode` defaults to `AUTO_STOP` with a 60-minute idle timeout for cost control, per AWS Well-Architected guidance.
- Pooled/non-persistent desktops via `aws_workspaces_pool` are intentionally out of scope for this module -- see `modules/aws/workspaces/directory`'s notes for the rationale.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Scaling to Hundreds or Thousands of Desktops

- **Bundle lookups are deduplicated.** `data.aws_workspaces_bundle.lookup` is keyed by the distinct `(bundle_name, bundle_owner)` pair across every entry, not by each entry's own map key -- thousands of desktops sharing a handful of bundles (e.g. one Windows bundle and one Linux bundle) trigger only one lookup per distinct bundle, not one per desktop.
- **The shared default KMS key is created at most once** per module call regardless of how many entries need it (`enable_default_kms_key`), so it doesn't add per-desktop overhead either.
- **Maintain large `workspaces` maps as generated data, not hand-written HCL.** Group desktops by shared attributes (directory, bundle) and expand a flat list of usernames into the full map with a `for` expression -- see `modules/aws/workspaces/examples/yaml_fleet` for a complete, YAML-driven example of this pattern.
- **Check AWS WorkSpaces service quotas** before provisioning a large fleet -- the default "WorkSpaces per Region" quota is often lower than a large organization's headcount and needs a quota increase request.
- **Tune `-parallelism`** on `tofu apply`/`tofu plan` for very large fleets. WorkSpaces provisioning is slow per-desktop and the WorkSpaces API enforces its own throttling; watch for `ThrottlingException` errors and reduce parallelism if you see them.
- **Shard very large fleets across multiple root modules/states** (e.g. one fleet per department or office) rather than a single multi-thousand-resource apply, to keep plan/apply time and blast radius manageable.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.54.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_default_kms_key"></a> [default\_kms\_key](#module\_default\_kms\_key) | ../../kms | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_workspaces_workspace.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/workspaces_workspace) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.default_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_workspaces_bundle.lookup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/workspaces_bundle) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_directory_id_lookup"></a> [directory\_id\_lookup](#input\_directory\_id\_lookup) | (Optional) Map of WorkSpaces directory IDs keyed by logical name, e.g. the `ids` output of modules/aws/workspaces/directory. Referenced by each workspaces entry's directory\_key. | `map(string)` | `{}` | no |
| <a name="input_enable_default_kms_key"></a> [enable\_default\_kms\_key](#input\_enable\_default\_kms\_key) | (Optional) If true (the default) and an entry in var.workspaces omits volume\_encryption\_key, this module creates one shared AWS KMS customer-managed key (via modules/aws/kms) aliased alias/<kms\_key\_alias> and uses its ARN as that entry's volume\_encryption\_key. Set to false to require every entry to supply its own volume\_encryption\_key, or to rely on the AWS-managed alias/aws/workspaces key by leaving volume\_encryption\_key null. | `bool` | `true` | no |
| <a name="input_kms_key_alias"></a> [kms\_key\_alias](#input\_kms\_key\_alias) | (Optional) Alias suffix (passed as name\_prefix to modules/aws/kms) for the shared default KMS key created when enable\_default\_kms\_key is true and at least one entry needs it. Ignored otherwise. | `string` | `"workspaces"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to every desktop and to the shared default KMS key (if created), merged with each entry's optional per-desktop tags. | `map(string)` | `{}` | no |
| <a name="input_workspaces"></a> [workspaces](#input\_workspaces) | (Optional) Map of WorkSpaces desktops to create, keyed by a caller-chosen logical name (e.g. a username).<br/>Each entry must set user\_name, exactly one of directory\_id or directory\_key, and exactly one of bundle\_id<br/>or bundle\_name to select the WorkSpaces bundle -- this is how a given desktop is provisioned as Windows<br/>vs. Linux, since the bundle determines the operating system. When bundle\_id is unset, it is resolved via<br/>an aws\_workspaces\_bundle data source lookup using bundle\_name/bundle\_owner. When directory\_id is unset,<br/>it is resolved via directory\_key, a key into var.directory\_id\_lookup.<br/>Fields:<br/>  - directory\_id:                   (Optional) ID of the WorkSpaces directory this desktop belongs to,<br/>                                     e.g. the `ids` output of modules/aws/workspaces/directory. Each entry<br/>                                     must set exactly one of directory\_id or directory\_key.<br/>  - directory\_key:                  (Optional) Key into var.directory\_id\_lookup, resolved into a literal<br/>                                     directory\_id. Conflicts with directory\_id.<br/>  - user\_name:                      (Required) Username of the directory user this desktop is assigned<br/>                                     to. Must already exist in the directory.<br/>  - bundle\_id:                      (Optional) ID of the WorkSpaces bundle. Conflicts with bundle\_name.<br/>  - bundle\_name:                    (Optional) Name of the WorkSpaces bundle to look up (e.g. an Amazon<br/>                                     Linux bundle name for a Linux desktop, or a Windows 10/11 bundle name<br/>                                     for a Windows desktop). Conflicts with bundle\_id.<br/>  - bundle\_owner:                   (Optional) Owner of the bundle referenced by bundle\_name. Defaults to<br/>                                     "AMAZON", which resolves an Amazon-provided bundle. Set this to your<br/>                                     own AWS account ID instead to resolve a caller-owned custom bundle.<br/>  - root\_volume\_encryption\_enabled: (Optional) Whether the root volume is encrypted. Defaults to true.<br/>  - user\_volume\_encryption\_enabled: (Optional) Whether the user volume is encrypted. Defaults to true.<br/>  - volume\_encryption\_key:          (Optional) ARN of the KMS key used to encrypt this desktop's volumes.<br/>                                     When unset and var.enable\_default\_kms\_key is true (the default), the<br/>                                     shared KMS key this module creates is used instead.<br/>  - workspace\_properties:           (Optional) Compute/running-mode settings. See nested fields below.<br/>  - tags:                           (Optional) Additional tags for this desktop, merged with var.tags.<br/>workspace\_properties fields:<br/>  - compute\_type\_name:                        (Optional) Defaults to "STANDARD".<br/>  - root\_volume\_size\_gib:                     (Optional) Defaults to 80.<br/>  - running\_mode:                             (Optional) AUTO\_STOP or ALWAYS\_ON. Defaults to "AUTO\_STOP"<br/>                                               for cost control.<br/>  - running\_mode\_auto\_stop\_timeout\_in\_minutes: (Optional) Defaults to 60.<br/>  - user\_volume\_size\_gib:                      (Optional) Defaults to 50. | <pre>map(object({<br/>    directory_id  = optional(string)<br/>    directory_key = optional(string)<br/>    user_name     = string<br/>    bundle_id     = optional(string)<br/>    bundle_name   = optional(string)<br/>    bundle_owner  = optional(string, "AMAZON")<br/><br/>    root_volume_encryption_enabled = optional(bool, true)<br/>    user_volume_encryption_enabled = optional(bool, true)<br/>    volume_encryption_key          = optional(string)<br/><br/>    workspace_properties = optional(object({<br/>      compute_type_name                         = optional(string, "STANDARD")<br/>      root_volume_size_gib                      = optional(number, 80)<br/>      running_mode                              = optional(string, "AUTO_STOP")<br/>      running_mode_auto_stop_timeout_in_minutes = optional(number, 60)<br/>      user_volume_size_gib                      = optional(number, 50)<br/>    }), {})<br/><br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bundle_ids"></a> [bundle\_ids](#output\_bundle\_ids) | Map of the resolved WorkSpaces bundle ID used for each desktop (whichever of bundle\_id or a bundle\_name/bundle\_owner lookup resolved it), keyed by the same keys as var.workspaces. |
| <a name="output_computer_names"></a> [computer\_names](#output\_computer\_names) | Map of WorkSpaces desktop computer names (as seen by the operating system), keyed by the same keys as var.workspaces. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of WorkSpaces desktop IDs, keyed by the same keys as var.workspaces. |
| <a name="output_ip_addresses"></a> [ip\_addresses](#output\_ip\_addresses) | Map of WorkSpaces desktop IP addresses, keyed by the same keys as var.workspaces. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the shared default KMS key created for volume encryption, or null when enable\_default\_kms\_key is false or no entry needed it. |
| <a name="output_states"></a> [states](#output\_states) | Map of WorkSpaces desktop operational states, keyed by the same keys as var.workspaces. |
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
