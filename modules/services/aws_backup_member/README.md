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

<h3 align="center">aws_backup_member</h3>
  <p align="center">
    The static per-account footprint for org-wide tag-based tiered backup: a local staging vault and the IAM role AWS Backup assumes, with cross-account copy + KMS rights into the central backup account.
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

This module deploys the **member-account** half of a tag-based, tiered backup system. It is the
small, static footprint that must pre-exist in **every** account whose resources are protected by
the org `BACKUP_POLICY` (see the companion
[`aws_backup_organization_tiered`](../aws_backup_organization_tiered) module).

It creates exactly two things:

1. **A local staging vault** (`backup-staging`). AWS Backup always writes recovery points locally
   first; the org policy's `copy_actions` then ship them cross-account into the compliance-locked
   central vaults. Staging is disposable — no lock, short retention.
2. **The backup IAM role** (`SunwardAWSBackupRole`) that AWS Backup assumes. It carries the AWS
   managed Backup/Restore + S3 backup/restore policies plus an inline policy granting
   `backup:CopyIntoBackupVault` and KMS encrypt rights **scoped to the central account's** vault and
   key ARNs — the identity half of cross-account copy.

Because the central account grants the whole organization and this module grants the central
account's ARNs, the module is **identical in every account** — only `central_account_id` varies, and
it is constant org-wide. Adding or changing backup tiers never touches this module.

> **Why this matters:** AWS Backup does **not** create or validate the staging vault or the role. If
> they are missing, the org policy still attaches and simply produces **no backup jobs** — a silent
> failure with no `BackupJobFailed` event. Deploy this module to every in-scope account (and wire it
> into the account baseline so new accounts inherit it).

## Prerequisites

- The org-wide **cross-account backup** global setting is enabled (management account).
- The central account's vaults and CMKs exist and grant the organization
  (`aws_backup_organization_tiered`). The cross-account grant is two-sided: central vaults grant the
  org, and this module grants the central account's ARNs.

## Usage

```hcl
module "backup_member" {
  source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup_member?ref=feature/aws_backup_member"

  central_account_id = "992382491121"

  tags = {
    terraform = "true"
    service   = "backups"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

## Notes & Design Decisions

- **Staging uses the AWS-managed key by default.** `staging_kms_key_arn` defaults to null
  (`aws/backup`) because staging points are short-lived; the durable, immutable copy lives in the
  CMK-encrypted central vault. Override it to use a customer-managed key if local policy requires.
- **Inline policy scope.** The cross-account copy policy targets `:<central_account_id>:` vault and
  key ARNs with wildcards rather than enumerating per-tier ARNs, so the module never needs the tier
  list and stays identical across accounts.
- **`force_destroy` defaults to false** to avoid destroying in-flight recovery points, even though
  staging is conceptually disposable.

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_backup_role"></a> [backup\_role](#module\_backup\_role) | ../../aws/iam/role | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_backup_vault.staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_iam_role_policy.cross_account_copy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_backup_role_name"></a> [backup\_role\_name](#input\_backup\_role\_name) | (Optional) Name of the IAM role AWS Backup assumes in this account. Must match the backup\_role\_name referenced by the org BACKUP\_POLICY selections ($account token). | `string` | `"SunwardAWSBackupRole"` | no |
| <a name="input_backup_role_path"></a> [backup\_role\_path](#input\_backup\_role\_path) | (Optional) Path for the backup IAM role. | `string` | `"/"` | no |
| <a name="input_backup_role_permissions_boundary"></a> [backup\_role\_permissions\_boundary](#input\_backup\_role\_permissions\_boundary) | (Optional) ARN of a permissions boundary policy to attach to the backup role. | `string` | `null` | no |
| <a name="input_central_account_id"></a> [central\_account\_id](#input\_central\_account\_id) | (Required) The AWS account ID of the central backup (delegated administrator) account that holds the compliance-locked central vaults and their CMKs. The backup role's inline policy is scoped to this account's vault and key ARNs so recovery points can be copied cross-account. This is the only value that varies between member accounts (and it is constant org-wide). | `string` | n/a | yes |
| <a name="input_managed_policy_arns"></a> [managed\_policy\_arns](#input\_managed\_policy\_arns) | (Optional) AWS managed policy ARNs attached to the backup role. Defaults to the AWS Backup service-role policies for backup, restore, and S3 backup/restore, which together cover all AWS Backup-supported resource types. | `list(string)` | <pre>[<br/>  "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",<br/>  "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",<br/>  "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForS3Backup",<br/>  "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForS3Restore"<br/>]</pre> | no |
| <a name="input_staging_kms_key_arn"></a> [staging\_kms\_key\_arn](#input\_staging\_kms\_key\_arn) | (Optional) ARN of a customer-managed KMS key to encrypt the staging vault. Defaults to null, which uses the AWS-managed AWS Backup key (aws/backup) — acceptable because staging is short-lived and the durable, immutable copy lives in the CMK-encrypted central vault. | `string` | `null` | no |
| <a name="input_staging_vault_force_destroy"></a> [staging\_vault\_force\_destroy](#input\_staging\_vault\_force\_destroy) | (Optional) Allow Terraform to delete the staging vault even if it contains recovery points. Staging is disposable, but this defaults to false to avoid accidental destruction of in-flight recovery points. | `bool` | `false` | no |
| <a name="input_staging_vault_name"></a> [staging\_vault\_name](#input\_staging\_vault\_name) | (Optional) Name of the local, tier-agnostic staging vault. AWS Backup always writes recovery points locally first; this vault must match the staging\_vault\_name configured in the org BACKUP\_POLICY. It is disposable (short retention, no lock). | `string` | `"backup-staging"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to all resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backup_role_arn"></a> [backup\_role\_arn](#output\_backup\_role\_arn) | ARN of the IAM role AWS Backup assumes in this account. |
| <a name="output_backup_role_name"></a> [backup\_role\_name](#output\_backup\_role\_name) | Name of the IAM role AWS Backup assumes in this account. |
| <a name="output_staging_vault_arn"></a> [staging\_vault\_arn](#output\_staging\_vault\_arn) | ARN of the local staging backup vault. |
| <a name="output_staging_vault_name"></a> [staging\_vault\_name](#output\_staging\_vault\_name) | Name of the local staging backup vault. |
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
