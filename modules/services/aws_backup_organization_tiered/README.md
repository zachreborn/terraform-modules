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

<h3 align="center">aws_backup_organization_tiered</h3>
  <p align="center">
    Tag-based, tiered AWS Backup for an entire AWS Organization: one BACKUP_POLICY derived from a tier map, plus compliance-locked central vaults for cross-account, logically air-gapped copies.
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
    <li><a href="#about">About</a></li>
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#notes--design-decisions">Notes & Design Decisions</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

## About

This module deploys the **central** half of a tag-based, tiered backup system for an AWS
Organization. It is meant to run in the AWS Backup **delegated administrator** account.

Tag any resource in any member account with `backup-tier = <tier>` and the correct schedule,
retention, and immutability apply automatically, org-wide, with zero per-resource configuration.

It produces two things from a single `backup_tiers` map (the source of truth):

1. **One AWS Organizations `BACKUP_POLICY`** carrying every tier dimension (cadence, retention,
   cold transition, cross-account/cross-region copy). AWS Organizations propagates it to every
   member account in the attached workload OUs — including accounts added later — with no
   per-account redeploy. Each rule lands the recovery point in a local `backup-staging` vault, then
   `copy_actions` ship it cross-account into the central vault(s).
2. **A set of compliance-lockable central vaults** (`central-vault-<tier>`) in the central account,
   one per tier in `prod_region` plus one in `dr_region` for `copy_to_dr` tiers. Each has a
   per-region customer-managed KMS key, a resource policy granting the organization
   `backup:CopyIntoBackupVault`, a KMS key policy granting org backup roles encrypt rights, and an
   optional **COMPLIANCE-mode Vault Lock**. The result is immutable, logically air-gapped copies
   living in one account, isolated from any source account's blast radius.

The per-account static footprint (the `backup-staging` vault + the `SunwardAWSBackupRole`) is **not**
created here — it is created in every member account by the companion
[`aws_backup_member`](../aws_backup_member) module.

## Prerequisites

- The caller runs in the AWS Backup **delegated administrator** account, registered via AWS
  Organizations (`aws_organizations_delegated_administrator` for `backup.amazonaws.com`) with a
  delegated resource policy permitting it to create/update/attach `BACKUP_POLICY`.
- `BACKUP_POLICY` is enabled in the organization's `enabled_policy_types` (management account).
- The organization-wide **cross-account backup** global setting is enabled
  (`isCrossAccountBackupEnabled = true`, set from the management account).
- Every member account that will carry tagged resources has the companion `aws_backup_member`
  module deployed (the `backup-staging` vault + `SunwardAWSBackupRole`). AWS does **not** create or
  validate these — a missing baseline is a silent backup failure.

## Usage

### Sunward four-tier example

```hcl
module "tiered_backup" {
  source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup_organization_tiered?ref=feature/aws_backup_organization_tiered"

  providers = {
    aws.prod_region = aws.aws_prod_region
    aws.dr_region   = aws.aws_dr_region
  }

  central_account_id = "992382491121"
  prod_region        = "us-west-2"
  dr_region          = "us-east-2"
  target_ou_ids      = [module.dev_ou.id, module.test_ou.id]

  # Validate against reversible vaults first, then flip to true to commit immutability.
  enable_vault_lock   = false
  changeable_for_days = 3

  backup_tiers = {
    "1" = {
      description = "Mission Critical"
      copy_to_dr  = true
      rules = [
        { name = "daily", schedule = "cron(0 6 ? * * *)", local_delete_after_days = 14, central_delete_after_days = 30 },
        { name = "monthly", schedule = "cron(0 7 1 * ? *)", local_delete_after_days = 14, central_delete_after_days = 730, central_cold_after_days = 30 },
        { name = "yearly", schedule = "cron(0 8 1 1 ? *)", local_delete_after_days = 14, central_delete_after_days = 2555, central_cold_after_days = 90 },
      ]
    }
    "4" = {
      description = "Non-Production"
      copy_to_dr  = false
      rules = [
        { name = "daily", schedule = "cron(0 6 ? * * *)", local_delete_after_days = 7, central_delete_after_days = 30 },
      ]
    }
  }

  tags = {
    terraform = "true"
    service   = "backups"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

## Notes & Design Decisions

- **Single source of truth.** All cadence/retention/copy behavior lives in `backup_tiers`. Add a
  tier → add a key; change a dimension → edit one place. None of this data reaches member accounts;
  it lives in the org policy.
- **Staging vs central.** The local `backup-staging` vault (member-side) is disposable: short
  retention, no lock. The central vaults hold the full retention and the immutability. AWS Backup
  always writes locally first, so the staging vault and role must pre-exist in every member account.
- **Vault Lock is parameterized and irreversible.** `enable_vault_lock` defaults to `false` so the
  cross-account copy + KMS wiring can be validated against reversible vaults. COMPLIANCE mode cannot
  be undone after the `changeable_for_days` grace window expires — flip it on deliberately.
- **Policy tokens.** `$account` is substituted by AWS Organizations per member account (used for the
  selection's `iam_role_arn`). The central account is a **literal** in the copy-destination ARNs.
- **Window/lifecycle keys** follow the AWS Organizations backup-policy syntax
  (`start_backup_window_minutes`, `complete_backup_window_minutes`, `move_to_cold_storage_after_days`,
  `delete_after_days`); every leaf value is a string wrapped in `{"@@assign": ...}`.
- **Cold storage on cross-account copies.** AWS Backup historically restricts cold-tier transitions
  for cross-account copies. Cold transitions are therefore declared per-rule and nullable
  (`central_cold_after_days`); validate that the copy lands as expected in the test phase before
  enabling cold transitions broadly. Cold tier is Glacier-class only (no Deep Archive in AWS Backup
  lifecycle), and `central_delete_after_days >= central_cold_after_days + 90` is enforced.
- **Continuous / PITR is local-only.** Rules with `continuous = true` emit no `copy_actions`
  (cross-account PITR copy is not supported); they protect the local staging vault only.
- **Attach to workload OUs, not the org root**, so the management account is excluded.

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
| <a name="provider_aws.dr_region"></a> [aws.dr\_region](#provider\_aws.dr\_region) | >= 6.0.0 |
| <a name="provider_aws.prod_region"></a> [aws.prod\_region](#provider\_aws.prod\_region) | >= 6.0.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_central_kms_dr"></a> [central\_kms\_dr](#module\_central\_kms\_dr) | ../../aws/kms | n/a |
| <a name="module_central_kms_prod"></a> [central\_kms\_prod](#module\_central\_kms\_prod) | ../../aws/kms | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_backup_framework.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_framework) | resource |
| [aws_backup_report_plan.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_report_plan) | resource |
| [aws_backup_vault.central_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault.central_prod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_lock_configuration.central_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_lock_configuration) | resource |
| [aws_backup_vault_lock_configuration.central_prod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_lock_configuration) | resource |
| [aws_backup_vault_policy.central_dr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_policy) | resource |
| [aws_backup_vault_policy.central_prod](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_policy) | resource |
| [aws_organizations_policy.tiered_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.tiered_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_audit_report_s3_bucket_name"></a> [audit\_report\_s3\_bucket\_name](#input\_audit\_report\_s3\_bucket\_name) | (Optional) Name of an existing S3 bucket to deliver Audit Manager report plan output to. Required when enable\_audit\_manager = true. | `string` | `null` | no |
| <a name="input_backup_role_name"></a> [backup\_role\_name](#input\_backup\_role\_name) | (Optional) Name of the IAM role AWS Backup assumes in each member account. Must match the role created by the aws\_backup\_member module. Referenced in selections via the $account policy token. | `string` | `"SunwardAWSBackupRole"` | no |
| <a name="input_backup_tiers"></a> [backup\_tiers](#input\_backup\_tiers) | (Required) The single source of truth for the tiered backup model. A map keyed by tier<br/>identifier (the value written to the `backup-tier` tag, e.g. "1".."4" or "xs".."xl"). Each<br/>tier declares its central copy/DR behavior, the Vault Lock retention floor for its central<br/>vaults, and an ordered list of backup rules. The module derives the org BACKUP\_POLICY and the<br/>central vault set entirely from this map: add a tier by adding a key, change a dimension by<br/>editing one place. Tier keys are arbitrary strings and become the `backup-tier` tag value.<br/><br/>Per-rule fields:<br/>  name                      - rule name (unique within the tier).<br/>  schedule                  - cron() expression. AWS Backup scheduled-snapshot floor is 1 hour.<br/>  continuous                - enable continuous backup / PITR (supported services only). PITR is<br/>                              local-staging only; copy\_actions are not emitted for continuous rules.<br/>  central\_copy              - copy the recovery point cross-account into the central vault(s).<br/>  start\_window\_minutes      - backup start window.<br/>  completion\_window\_minutes - backup completion window.<br/>  local\_delete\_after\_days   - staging (local) copy lifetime. Staging is disposable; keep short.<br/>  central\_delete\_after\_days - immutable central copy retention.<br/>  central\_cold\_after\_days   - Glacier-class transition for the central copy (null = none). AWS<br/>                              requires central\_delete\_after\_days >= central\_cold\_after\_days + 90. | <pre>map(object({<br/>    description              = string<br/>    copy_to_dr               = bool<br/>    vault_min_retention_days = optional(number, 30)<br/>    rules = list(object({<br/>      name                      = string<br/>      schedule                  = string<br/>      continuous                = optional(bool, false)<br/>      central_copy              = optional(bool, true)<br/>      start_window_minutes      = optional(number, 60)<br/>      completion_window_minutes = optional(number, 1440)<br/>      local_delete_after_days   = number<br/>      central_delete_after_days = number<br/>      central_cold_after_days   = optional(number, null)<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_central_account_id"></a> [central\_account\_id](#input\_central\_account\_id) | (Required) The AWS account ID of the central backup (delegated administrator) account that holds the compliance-locked central vaults. Used as the literal account in copy-destination ARNs and as the KMS key administrator principal. | `string` | n/a | yes |
| <a name="input_central_vault_prefix"></a> [central\_vault\_prefix](#input\_central\_vault\_prefix) | (Optional) Name prefix for the central vaults. The tier key is appended (e.g. central-vault-1). The same vault name is used in both prod\_region and dr\_region; the region is carried in the ARN. | `string` | `"central-vault-"` | no |
| <a name="input_changeable_for_days"></a> [changeable\_for\_days](#input\_changeable\_for\_days) | (Optional) Grace window, in days, during which a COMPLIANCE-mode Vault Lock can still be deleted. After this window the lock is permanent. AWS minimum is 3. Only applies when enable\_vault\_lock = true. | `number` | `3` | no |
| <a name="input_dr_region"></a> [dr\_region](#input\_dr\_region) | (Optional) The disaster-recovery region. Central vaults are created here for tiers with copy\_to\_dr = true, and rules in those tiers gain a second cross-region copy\_action targeting this region. | `string` | `"us-east-2"` | no |
| <a name="input_enable_audit_manager"></a> [enable\_audit\_manager](#input\_enable\_audit\_manager) | (Optional) Create an AWS Backup Audit Manager framework and report plan in the central account to codify the tier rules and produce org-wide compliance reporting. | `bool` | `false` | no |
| <a name="input_enable_vault_lock"></a> [enable\_vault\_lock](#input\_enable\_vault\_lock) | (Optional) Apply AWS Backup Vault Lock in COMPLIANCE mode to the central vaults. Compliance mode is IRREVERSIBLE once the changeable\_for\_days grace window expires. Leave false to validate the cross-account copy + KMS wiring against reversible vaults first, then flip to true to commit immutability. | `bool` | `false` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | (Optional) Duration in days before a destroyed central KMS key is deleted. Must be between 7 and 30. | `number` | `30` | no |
| <a name="input_kms_enable_key_rotation"></a> [kms\_enable\_key\_rotation](#input\_kms\_enable\_key\_rotation) | (Optional) Enable automatic annual rotation of the central KMS keys. | `bool` | `true` | no |
| <a name="input_policy_name"></a> [policy\_name](#input\_policy\_name) | (Optional) Name of the AWS Organizations BACKUP\_POLICY. Also used as the per-tier plan-name prefix. | `string` | `"sunward-tiered-backup"` | no |
| <a name="input_policy_regions"></a> [policy\_regions](#input\_policy\_regions) | (Optional) The regions the BACKUP\_POLICY plans deploy to within each member account. Defaults to the prod\_region only; cross-region protection is delivered by the central us-east-2 copy\_action, not by running the plan in the DR region. | `list(string)` | `null` | no |
| <a name="input_prod_region"></a> [prod\_region](#input\_prod\_region) | (Optional) The primary region in which the BACKUP\_POLICY plans run in member accounts and in which the always-on central vaults are created. | `string` | `"us-west-2"` | no |
| <a name="input_staging_vault_name"></a> [staging\_vault\_name](#input\_staging\_vault\_name) | (Optional) Name of the tier-agnostic local staging vault that must pre-exist in every member account (created by the aws\_backup\_member module). Recovery points land here first, then copy\_actions ship them to the central vault(s). | `string` | `"backup-staging"` | no |
| <a name="input_tag_key"></a> [tag\_key](#input\_tag\_key) | (Optional) The resource tag key that steers a resource into a tier. Its value must equal one of the backup\_tiers keys. | `string` | `"backup-tier"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to all resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_target_ou_ids"></a> [target\_ou\_ids](#input\_target\_ou\_ids) | (Required) Organizational Unit IDs to attach the BACKUP\_POLICY to. Attach to workload OUs, never the org root, so the management account is excluded. New accounts placed in these OUs inherit the policy automatically. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_attached_ou_ids"></a> [attached\_ou\_ids](#output\_attached\_ou\_ids) | The Organizational Unit IDs the BACKUP\_POLICY is attached to. |
| <a name="output_audit_framework_arn"></a> [audit\_framework\_arn](#output\_audit\_framework\_arn) | ARN of the AWS Backup Audit Manager framework, if created. |
| <a name="output_audit_report_plan_arn"></a> [audit\_report\_plan\_arn](#output\_audit\_report\_plan\_arn) | ARN of the AWS Backup Audit Manager report plan, if created. |
| <a name="output_backup_policy_arn"></a> [backup\_policy\_arn](#output\_backup\_policy\_arn) | The ARN of the AWS Organizations BACKUP\_POLICY. |
| <a name="output_backup_policy_id"></a> [backup\_policy\_id](#output\_backup\_policy\_id) | The ID of the AWS Organizations BACKUP\_POLICY. |
| <a name="output_backup_policy_json"></a> [backup\_policy\_json](#output\_backup\_policy\_json) | The rendered BACKUP\_POLICY JSON document. Useful for review and for validating the generated policy before attachment. |
| <a name="output_central_kms_key_arns_dr"></a> [central\_kms\_key\_arns\_dr](#output\_central\_kms\_key\_arns\_dr) | Map of tier key to central KMS key ARN in the dr\_region (copy\_to\_dr tiers only). |
| <a name="output_central_kms_key_arns_prod"></a> [central\_kms\_key\_arns\_prod](#output\_central\_kms\_key\_arns\_prod) | Map of tier key to central KMS key ARN in the prod\_region. |
| <a name="output_central_vault_arns_dr"></a> [central\_vault\_arns\_dr](#output\_central\_vault\_arns\_dr) | Map of tier key to central vault ARN in the dr\_region (copy\_to\_dr tiers only). |
| <a name="output_central_vault_arns_prod"></a> [central\_vault\_arns\_prod](#output\_central\_vault\_arns\_prod) | Map of tier key to central vault ARN in the prod\_region. |
| <a name="output_central_vault_names"></a> [central\_vault\_names](#output\_central\_vault\_names) | Map of tier key to central vault name (identical across regions). |
| <a name="output_vault_lock_enabled"></a> [vault\_lock\_enabled](#output\_vault\_lock\_enabled) | Whether COMPLIANCE-mode Vault Lock is applied to the central vaults. |
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
