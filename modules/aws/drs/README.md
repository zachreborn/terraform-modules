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

<h3 align="center">DRS Module</h3>
  <p align="center">
    This module configures AWS Elastic Disaster Recovery (DRS): the initialization IAM roles the service
    requires, a customer managed KMS key for the replication staging area, and one or more replication
    configuration templates.
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

### Simple Example

```
module "drs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/drs"

  templates = {
    app1 = {
      replication_servers_security_groups_ids = ["sg-0123456789abcdef0"]
      staging_area_subnet_id                  = "subnet-0123456789abcdef0"
    }
  }
}
```

### Fresh Account, Let Terraform Initialize DRS's IAM Roles

DRS rejects replication configuration templates until the account has been initialized (see
[Prerequisites](#prerequisites)), so this is a two-step apply rather than one:

**Step 1 -- create only the IAM roles, instance profiles, and service-linked role:**

```
module "drs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/drs"

  create_service_roles       = true
  create_service_linked_role = true
}
```

Apply this first, then run `aws drs initialize-service` (or visit the DRS console) once for this account and
region.

**Step 2 -- add templates once the account is initialized:**

```
module "drs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/drs"

  create_service_roles       = true
  create_service_linked_role = true

  templates = {
    app1 = {
      replication_servers_security_groups_ids = ["sg-0123456789abcdef0"]
      staging_area_subnet_id                  = "subnet-0123456789abcdef0"
    }
  }
}
```

### Multiple Templates from YAML, Existing KMS Key

```
locals {
  drs_templates = yamldecode(file("${path.module}/drs_templates.yaml"))
}

module "drs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/drs"

  create_kms_key = false
  kms_key_arn    = "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"

  templates = local.drs_templates
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- AWS Elastic Disaster Recovery must be initialized per account, per region before any replication
  configuration template can be created; see
  [Elastic Disaster Recovery initialization and permissions](https://docs.aws.amazon.com/drs/latest/userguide/getting-started-initializing.html).
  This module can create the required IAM roles, instance profiles, and service-linked role
  (`create_service_roles` / `create_service_linked_role`, both `false` by default since most accounts are
  initialized through the console once and reused), but the `aws drs initialize-service` API call itself has
  no Terraform resource and must be run out of band.
- The staging area subnet referenced by each template's `staging_area_subnet_id` needs outbound access on TCP
  443 to the DRS and Amazon S3 endpoints for the target region, and its replication server security groups must
  allow inbound TCP 1500 from every source server that will replicate into that staging area.
- `create_kms_key` and `kms_key_arn` are mutually exclusive; set `create_kms_key = false` before supplying an
  existing `kms_key_arn`.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- By default this module creates a customer managed KMS key (via `../kms`) and injects its ARN into every
  template that does not set its own `ebs_encryption_key_arn`, switching that template's `ebs_encryption` to
  `CUSTOM` automatically. Set `create_kms_key = false` to fall back to AWS-managed (`DEFAULT`) EBS encryption,
  or supply `kms_key_arn` to reuse an existing key.
- `create_service_roles` and `create_service_linked_role` default to `false` at this level (unlike the
  `../initialization` submodule's own defaults of `true`), because the DRS service role names are fixed and
  most consumers of this module are managing an account that was already initialized through the console.
  Flip them on explicitly for a fresh account.
- See `./replication_configuration_template/README.md` and `./initialization/README.md` for the full
  per-attribute documentation of the submodules this module composes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_initialization"></a> [initialization](#module\_initialization) | ./initialization | n/a |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../kms | n/a |
| <a name="module_replication_configuration_template"></a> [replication\_configuration\_template](#module\_replication\_configuration\_template) | ./replication_configuration_template | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.validate_kms_inputs](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_create_initialization"></a> [create\_initialization](#input\_create\_initialization) | (Optional) Whether to manage the Elastic Disaster Recovery initialization submodule (service roles, instance profiles, and the service-linked role) at all. Set this to false when DRS has already been initialized outside of Terraform, such as through the console, and you only want this module to manage replication configuration templates. | `bool` | `true` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | (Optional) Whether to create a customer managed KMS key for encrypting the replication staging area's EBS volumes and snapshots. Mutually exclusive with kms\_key\_arn. | `bool` | `true` | no |
| <a name="input_create_service_linked_role"></a> [create\_service\_linked\_role](#input\_create\_service\_linked\_role) | (Optional) Whether to create the AWSServiceRoleForElasticDisasterRecovery service-linked role. Set this to false in an account where the role already exists, since AWS allows only one service-linked role per service per account. Ignored when create\_initialization is false. | `bool` | `false` | no |
| <a name="input_create_service_roles"></a> [create\_service\_roles](#input\_create\_service\_roles) | (Optional) Whether to create the six Elastic Disaster Recovery service roles and their instance profiles. Set this to false in an account that has already been initialized through the DRS console, since the role names are fixed and would otherwise collide. Ignored when create\_initialization is false. | `bool` | `false` | no |
| <a name="input_initialization_additional_policy_arns"></a> [initialization\_additional\_policy\_arns](#input\_initialization\_additional\_policy\_arns) | (Optional) Extra managed policy ARNs to attach on top of the AWS managed policies the initialization submodule already attaches, keyed by DRS role name. Ignored when create\_initialization is false. | `map(list(string))` | `{}` | no |
| <a name="input_initialization_max_session_duration"></a> [initialization\_max\_session\_duration](#input\_initialization\_max\_session\_duration) | (Optional) Maximum session duration, in seconds, for each Elastic Disaster Recovery service role. Ignored when create\_initialization is false. | `number` | `3600` | no |
| <a name="input_initialization_path"></a> [initialization\_path](#input\_initialization\_path) | (Optional) IAM path applied to the Elastic Disaster Recovery service roles and instance profiles. Ignored when create\_initialization is false. | `string` | `"/service-role/"` | no |
| <a name="input_initialization_permissions_boundary"></a> [initialization\_permissions\_boundary](#input\_initialization\_permissions\_boundary) | (Optional) ARN of the policy used to set the permissions boundary on each Elastic Disaster Recovery service role. Ignored when create\_initialization is false. | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | (Optional) ARN of an existing customer managed KMS key to use instead of creating one. Requires create\_kms\_key to be false. | `string` | `null` | no |
| <a name="input_kms_key_deletion_window_in_days"></a> [kms\_key\_deletion\_window\_in\_days](#input\_kms\_key\_deletion\_window\_in\_days) | (Optional) Deletion window, in days, for the KMS key this module creates. Only used when create\_kms\_key is true. | `number` | `30` | no |
| <a name="input_kms_key_description"></a> [kms\_key\_description](#input\_kms\_key\_description) | (Optional) Description for the KMS key this module creates. Only used when create\_kms\_key is true. | `string` | `"Customer managed key used to encrypt the AWS Elastic Disaster Recovery replication staging area."` | no |
| <a name="input_kms_key_enable_key_rotation"></a> [kms\_key\_enable\_key\_rotation](#input\_kms\_key\_enable\_key\_rotation) | (Optional) Whether automatic key rotation is enabled for the KMS key this module creates. Only used when create\_kms\_key is true. | `bool` | `true` | no |
| <a name="input_kms_key_name_prefix"></a> [kms\_key\_name\_prefix](#input\_kms\_key\_name\_prefix) | (Optional) Alias name prefix for the KMS key this module creates. Only used when create\_kms\_key is true. | `string` | `"drs-staging-area"` | no |
| <a name="input_kms_key_policy"></a> [kms\_key\_policy](#input\_kms\_key\_policy) | (Optional) A valid policy JSON document for the KMS key this module creates. Only used when create\_kms\_key is true. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region in which to manage the Elastic Disaster Recovery resources created by this module, applied to any template entry that does not set its own region. Defaults to the region set in the provider configuration. | `string` | `null` | no |
| <a name="input_service_linked_role_description"></a> [service\_linked\_role\_description](#input\_service\_linked\_role\_description) | (Optional) Description applied to the AWSServiceRoleForElasticDisasterRecovery service-linked role. Ignored when create\_initialization or create\_service\_linked\_role is false. | `string` | `"Service-linked role for AWS Elastic Disaster Recovery."` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags applied to every resource this module creates directly or through composition, merged with each resource's own Name tag. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_templates"></a> [templates](#input\_templates) | (Optional) Map of Elastic Disaster Recovery replication configuration templates to create, keyed by<br/>logical name. When an entry omits `ebs_encryption` / `ebs_encryption_key_arn`, this module fills them<br/>in from the KMS key it creates (or the `kms_key_arn` supplied) unless `create_kms_key` is false and no<br/>`kms_key_arn` is set, in which case the entry falls back to DEFAULT (AWS-managed) EBS encryption. See<br/>./replication\_configuration\_template/variables.tf for the full per-attribute documentation. | <pre>map(object({<br/>    associate_default_security_group = optional(bool, false)<br/>    auto_replicate_new_disks         = optional(bool, true)<br/>    bandwidth_throttling             = optional(number, 0)<br/>    create_public_ip                 = optional(bool, false)<br/>    data_plane_routing               = optional(string, "PRIVATE_IP")<br/>    default_large_staging_disk_type  = optional(string, "GP3")<br/>    ebs_encryption                   = optional(string)<br/>    ebs_encryption_key_arn           = optional(string)<br/>    name                             = optional(string)<br/>    pit_policy = optional(list(object({<br/>      enabled            = optional(bool, true)<br/>      interval           = number<br/>      retention_duration = number<br/>      rule_id            = optional(number)<br/>      units              = string<br/>      })), [<br/>      {<br/>        enabled            = true<br/>        interval           = 10<br/>        retention_duration = 60<br/>        rule_id            = 1<br/>        units              = "MINUTE"<br/>      },<br/>      {<br/>        enabled            = true<br/>        interval           = 1<br/>        retention_duration = 24<br/>        rule_id            = 2<br/>        units              = "HOUR"<br/>      },<br/>      {<br/>        enabled            = true<br/>        interval           = 1<br/>        retention_duration = 3<br/>        rule_id            = 3<br/>        units              = "DAY"<br/>      },<br/>    ])<br/>    region                                  = optional(string)<br/>    replication_server_instance_type        = optional(string, "t3.small")<br/>    replication_servers_security_groups_ids = optional(list(string), [])<br/>    staging_area_subnet_id                  = string<br/>    staging_area_tags                       = optional(map(string))<br/>    tags                                    = optional(map(string))<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      delete = optional(string)<br/>      update = optional(string)<br/>    }))<br/>    use_dedicated_replication_server = optional(bool, false)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_initialization_instance_profile_arns"></a> [initialization\_instance\_profile\_arns](#output\_initialization\_instance\_profile\_arns) | Map of instance profile ARNs for the EC2-assumed Elastic Disaster Recovery roles, keyed by role name. Empty when create\_initialization or create\_service\_roles is false. |
| <a name="output_initialization_role_arns"></a> [initialization\_role\_arns](#output\_initialization\_role\_arns) | Map of Elastic Disaster Recovery service role ARNs, keyed by role name. Empty when create\_initialization or create\_service\_roles is false. |
| <a name="output_initialization_role_names"></a> [initialization\_role\_names](#output\_initialization\_role\_names) | Map of Elastic Disaster Recovery service role names, keyed by role name. Empty when create\_initialization or create\_service\_roles is false. |
| <a name="output_initialization_service_linked_role_arn"></a> [initialization\_service\_linked\_role\_arn](#output\_initialization\_service\_linked\_role\_arn) | ARN of the AWSServiceRoleForElasticDisasterRecovery service-linked role. Null when create\_initialization or create\_service\_linked\_role is false. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the customer managed KMS key encrypting the replication staging area, whether created by this module or supplied via kms\_key\_arn. Null when neither create\_kms\_key nor kms\_key\_arn is set. |
| <a name="output_replication_configuration_template_arns"></a> [replication\_configuration\_template\_arns](#output\_replication\_configuration\_template\_arns) | Map of replication configuration template ARNs, keyed by the logical name used in var.templates. |
| <a name="output_replication_configuration_template_ids"></a> [replication\_configuration\_template\_ids](#output\_replication\_configuration\_template\_ids) | Map of replication configuration template IDs, keyed by the logical name used in var.templates. |
| <a name="output_replication_configuration_templates"></a> [replication\_configuration\_templates](#output\_replication\_configuration\_templates) | Map of the full replication configuration template resources, keyed by the logical name used in var.templates. |
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
