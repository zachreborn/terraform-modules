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

<h3 align="center">DRS Replication Configuration Template Module</h3>
  <p align="center">
    This module manages one or more AWS Elastic Disaster Recovery (DRS) replication configuration templates.
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
module "drs_templates" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/drs/replication_configuration_template"

  templates = {
    app1 = {
      replication_servers_security_groups_ids = ["sg-0123456789abcdef0"]
      staging_area_subnet_id                  = "subnet-0123456789abcdef0"
    }
  }
}
```

### Multiple Templates from YAML

```
locals {
  drs_templates = yamldecode(file("${path.module}/drs_templates.yaml"))
}

module "drs_templates" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/drs/replication_configuration_template"

  templates = local.drs_templates
}
```

```yaml
# drs_templates.yaml
app1:
  staging_area_subnet_id: subnet-0123456789abcdef0
  replication_servers_security_groups_ids:
    - sg-0123456789abcdef0
app2:
  staging_area_subnet_id: subnet-0fedcba9876543210
  replication_servers_security_groups_ids:
    - sg-0fedcba9876543210
  bandwidth_throttling: 100
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- AWS Elastic Disaster Recovery must be initialized in the target account and region before this resource can be
  created; see [Elastic Disaster Recovery initialization and permissions](https://docs.aws.amazon.com/drs/latest/userguide/getting-started-initializing.html).
  The `../initialization` submodule (or the root `modules/aws/drs` wrapper) manages the IAM roles that
  initialization requires, but the final `aws drs initialize-service` call (or a first visit to the DRS console)
  is not a Terraform-manageable action and must be run out of band, once per account per region.
- The staging area subnet referenced by `staging_area_subnet_id` needs outbound access on TCP 443 to the DRS and
  Amazon S3 endpoints for the target region, and the security groups in `replication_servers_security_groups_ids`
  must allow inbound TCP 1500 from every source server that will replicate into this staging area.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `pit_policy` defaults to the exact three point-in-time snapshot rules AWS mandates. A `validation` block
  rejects any attempt to change rule 1 or rule 2; only rule 3's `retention_duration` may be customized, per
  [the resource's documented constraint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/drs_replication_configuration_template).
- The provider's `ebs_encryption_key_arn` argument is documented as Required on the Terraform Registry page, but
  the provider's own schema marks it Optional. This module follows the schema: omit it to use `DEFAULT` (AWS
  managed) encryption, or set it (which this module then resolves `ebs_encryption` to `CUSTOM` for automatically)
  to use a customer managed KMS key.
- `associate_default_security_group` defaults to `false` and a validation requires at least one entry in
  `replication_servers_security_groups_ids` unless it is set to `true`, so replication servers are never left
  without an explicit security group boundary.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
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
| [aws_drs_replication_configuration_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/drs_replication_configuration_template) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags merged with a Name tag and applied to each template and its staging area resources. Always merged in, even when an entry sets its own tags / staging\_area\_tags; entry-specific keys take precedence on conflict. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_templates"></a> [templates](#input\_templates) | (Optional) Map of Elastic Disaster Recovery replication configuration templates to create, keyed by<br/>logical name. The key is used as the Name tag on both the template and its staging area resources<br/>unless `name` is set on the entry. Supply this map inline or from a YAML file via `yamldecode()` to<br/>manage many templates from a single module block.<br/><br/>Attributes per entry:<br/>  * `associate_default_security_group` - (Optional) Whether to associate the default Elastic Disaster Recovery security group with the template. Defaults to false so replication servers sit behind an explicit security group.<br/>  * `auto_replicate_new_disks` - (Optional) Whether the AWS replication agent automatically replicates newly added disks. Defaults to true so disks added after enrollment are not silently left unprotected.<br/>  * `bandwidth_throttling` - (Optional) Outbound data transfer rate limit for the source server, in Mbps. Defaults to 0 (unthrottled).<br/>  * `create_public_ip` - (Optional) Whether to create a public IP for the recovery instance by default. Defaults to false.<br/>  * `data_plane_routing` - (Optional) Data plane routing mechanism used for replication. Valid values are PUBLIC\_IP and PRIVATE\_IP. Defaults to PRIVATE\_IP.<br/>  * `default_large_staging_disk_type` - (Optional) Staging disk EBS volume type used during replication. Valid values are GP2, GP3, ST1, and AUTO. Defaults to GP3.<br/>  * `ebs_encryption` - (Optional) Type of EBS encryption used during replication. Valid values are DEFAULT, CUSTOM, and NONE (per the DRS API; the Terraform Registry page for this resource omits NONE, but the provider schema and AWS API both accept it). When omitted this resolves to CUSTOM if `ebs_encryption_key_arn` is set and DEFAULT otherwise.<br/>  * `ebs_encryption_key_arn` - (Optional) ARN of the customer managed KMS key used to encrypt the staging area during replication. Required when `ebs_encryption` is CUSTOM, and rejected when `ebs_encryption` is explicitly DEFAULT or NONE.<br/>  * `name` - (Optional) Overrides the map key when building the default Name tag.<br/>  * `pit_policy` - (Optional) Point in time (PIT) snapshot policy rules. Defaults to the three rules AWS mandates. All three rules must stay enabled; only rule 3's `retention_duration` may be changed, and only within 1-365 days.<br/>  * `region` - (Optional) Region in which to manage this template. Defaults to the region set in the provider configuration.<br/>  * `replication_server_instance_type` - (Optional) Instance type used for the replication server. Defaults to t3.small.<br/>  * `replication_servers_security_groups_ids` - (Optional) Security group IDs used by the replication server. Required to be non-empty unless `associate_default_security_group` is true.<br/>  * `staging_area_subnet_id` - (Required) Subnet used by the replication staging area.<br/>  * `staging_area_tags` - (Optional) Tags applied to every resource created in the replication staging area, always merged with a Name tag and the module's `tags`; entry-specific keys take precedence on conflict.<br/>  * `tags` - (Optional) Tags applied to the replication configuration template itself, always merged with a Name tag and the module's `tags`; entry-specific keys take precedence on conflict.<br/>  * `timeouts` - (Optional) Overrides for the resource create, update, and delete timeouts. Each defaults to 20m in the provider.<br/>  * `use_dedicated_replication_server` - (Optional) Whether to use a dedicated replication server in the staging area. Defaults to false. | <pre>map(object({<br/>    associate_default_security_group = optional(bool, false)<br/>    auto_replicate_new_disks         = optional(bool, true)<br/>    bandwidth_throttling             = optional(number, 0)<br/>    create_public_ip                 = optional(bool, false)<br/>    data_plane_routing               = optional(string, "PRIVATE_IP")<br/>    default_large_staging_disk_type  = optional(string, "GP3")<br/>    ebs_encryption                   = optional(string)<br/>    ebs_encryption_key_arn           = optional(string)<br/>    name                             = optional(string)<br/>    pit_policy = optional(list(object({<br/>      enabled            = optional(bool, true)<br/>      interval           = number<br/>      retention_duration = number<br/>      rule_id            = optional(number)<br/>      units              = string<br/>      })), [<br/>      {<br/>        enabled            = true<br/>        interval           = 10<br/>        retention_duration = 60<br/>        rule_id            = 1<br/>        units              = "MINUTE"<br/>      },<br/>      {<br/>        enabled            = true<br/>        interval           = 1<br/>        retention_duration = 24<br/>        rule_id            = 2<br/>        units              = "HOUR"<br/>      },<br/>      {<br/>        enabled            = true<br/>        interval           = 1<br/>        retention_duration = 3<br/>        rule_id            = 3<br/>        units              = "DAY"<br/>      },<br/>    ])<br/>    region                                  = optional(string)<br/>    replication_server_instance_type        = optional(string, "t3.small")<br/>    replication_servers_security_groups_ids = optional(list(string), [])<br/>    staging_area_subnet_id                  = string<br/>    staging_area_tags                       = optional(map(string))<br/>    tags                                    = optional(map(string))<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      delete = optional(string)<br/>      update = optional(string)<br/>    }))<br/>    use_dedicated_replication_server = optional(bool, false)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arns"></a> [arns](#output\_arns) | Map of replication configuration template ARNs, keyed by the logical name used in var.templates. |
| <a name="output_ebs_encryption"></a> [ebs\_encryption](#output\_ebs\_encryption) | Map of the resolved EBS encryption mode (DEFAULT, CUSTOM, or NONE) for each template, keyed by the logical name used in var.templates. |
| <a name="output_ebs_encryption_key_arns"></a> [ebs\_encryption\_key\_arns](#output\_ebs\_encryption\_key\_arns) | Map of the KMS key ARN encrypting each template's staging area, keyed by the logical name used in var.templates. Null for templates using DEFAULT or NONE encryption. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of replication configuration template IDs, keyed by the logical name used in var.templates. |
| <a name="output_staging_area_subnet_ids"></a> [staging\_area\_subnet\_ids](#output\_staging\_area\_subnet\_ids) | Map of the staging area subnet ID used by each template, keyed by the logical name used in var.templates. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | Map of the full tag set applied to each template, including provider default\_tags, keyed by the logical name used in var.templates. |
| <a name="output_templates"></a> [templates](#output\_templates) | Map of the full replication configuration template resources, keyed by the logical name used in var.templates. |
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
