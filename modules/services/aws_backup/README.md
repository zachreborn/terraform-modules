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

<h3 align="center">AWS Backup Module</h3>
  <p align="center">
    Service module which builds out a comprehensive AWS Backup solution with encrypted backup vaults, backup plans, and organization-level backup policies. Includes separate hourly, daily, and monthly backup retention policies with disaster recovery capabilities. Features vault lock configuration for compliance and immutable backups.
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

### Simple Backup Setup

This example creates a basic AWS Backup setup with all default settings, including hourly, daily, and monthly backup vaults with disaster recovery replication.

```hcl
module "aws_backup" {
    source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup"
    
    providers = {
        aws.prod_region = aws.us-east-1
        aws.dr_region   = aws.us-west-2
    }
    
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "backup_infrastructure"
    }
}
```

### Organization Backup Policy

This example enables AWS Backup at the organization level with centralized backup policies across all accounts.

```hcl
module "aws_backup" {
    source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup"
    
    providers = {
        aws.prod_region = aws.us-east-1
        aws.dr_region   = aws.us-west-2
    }
    
    enable_organization_backup = true
    
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "org_backup_infrastructure"
    }
}
```

### Custom Backup Schedules and Retention

This example customizes backup schedules and retention periods for different backup types.

```hcl
module "aws_backup" {
    source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup"
    
    providers = {
        aws.prod_region = aws.us-east-1
        aws.dr_region   = aws.us-west-2
    }
    
    hourly_backup_schedule    = "cron(30 * * * ? *)"  # Every hour at 30 minutes
    hourly_backup_retention   = 7                      # 7 days
    daily_backup_schedule     = "cron(0 6 * * ? *)"   # Daily at 6 AM
    daily_backup_retention    = 60                     # 60 days
    monthly_backup_schedule   = "cron(0 8 1 * ? *)"   # Monthly on 1st at 8 AM
    monthly_backup_retention  = 2555                   # 7 years
    dr_backup_retention       = 14                     # 14 days in DR region
    
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "backup_infrastructure"
    }
}
```

### Custom Vault Names and KMS Configuration

This example shows how to customize vault names and KMS key configuration.

```hcl
module "aws_backup" {
    source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup"
    
    providers = {
        aws.prod_region = aws.us-east-1
        aws.dr_region   = aws.us-west-2
    }
    
    vault_prod_hourly_name       = "my-company-hourly-backups"
    vault_prod_daily_name        = "my-company-daily-backups"
    vault_prod_monthly_name      = "my-company-monthly-backups"
    vault_disaster_recovery_name = "my-company-dr-backups"
    
    key_description             = "My Company backup encryption key"
    key_deletion_window_in_days = 7
    key_enable_key_rotation     = true
    
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "backup_infrastructure"
        company     = "my-company"
    }
}
```

### Vault Lock Compliance Mode

This example configures vault lock for compliance requirements with immutable backups.

```hcl
module "aws_backup" {
    source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup"
    
    providers = {
        aws.prod_region = aws.us-east-1
        aws.dr_region   = aws.us-west-2
    }
    
    changeable_for_days = 1  # Vault lock becomes immutable after 1 day
    
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "compliance_backups"
        compliance  = "true"
    }
}
```

### Backup Plans Only (Using Existing Vaults)

This example uses the organization_policies submodule to create backup plans while using existing backup vaults.

```hcl
module "aws_backup_plans" {
    source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup/organization_policies"
    
    providers = {
        aws.prod_region = aws.us-east-1
        aws.dr_region   = aws.us-west-2
    }
    
    backup_plan_name     = "my-backup-plan"
    ec2_backup_plan_name = "my-ec2-backup-plan"
    
    tags = {
        terraform   = "true"
        created_by  = "Zachary Hill"
        environment = "prod"
        project     = "backup_plans"
    }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_organization_policies"></a> [organization\_policies](#module\_organization\_policies) | ./organization_policies | n/a |
| <a name="module_vaults"></a> [vaults](#module\_vaults) | ./vaults | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backup_plan_completion_window"></a> [backup\_plan\_completion\_window](#input\_backup\_plan\_completion\_window) | (Optional) The amount of time in minutes AWS Backup attempts a backup before canceling the job and returning an error. Default is set to 24 hours. | `number` | `1440` | no |
| <a name="input_backup_plan_name"></a> [backup\_plan\_name](#input\_backup\_plan\_name) | (Required) The display name of a backup plan. | `string` | `"prod_backups"` | no |
| <a name="input_backup_plan_start_window"></a> [backup\_plan\_start\_window](#input\_backup\_plan\_start\_window) | (Optional) The amount of time in minutes before beginning a backup. | `number` | `60` | no |
| <a name="input_changeable_for_days"></a> [changeable\_for\_days](#input\_changeable\_for\_days) | (Optional) The number of days after which the vault lock configuration is no longer changeable. Setting this variable will utilize vault lock compliance mode. Omit the variable if you wish to create the vault lock in governance mode. Defaults to 3 days. | `number` | `3` | no |
| <a name="input_daily_backup_retention"></a> [daily\_backup\_retention](#input\_daily\_backup\_retention) | (Required) The daily backup plan retention in days. By default this is 30 days | `number` | `30` | no |
| <a name="input_daily_backup_schedule"></a> [daily\_backup\_schedule](#input\_daily\_backup\_schedule) | (Required) The daily backup plan schedule in cron format. By default this is set to run every day at 7:20 AM UTC. | `string` | `"cron(20 7 * * ? *)"` | no |
| <a name="input_dr_backup_retention"></a> [dr\_backup\_retention](#input\_dr\_backup\_retention) | (Required) The dr backup plan retention in days. By default this is 7 days. | `number` | `7` | no |
| <a name="input_ec2_backup_plan_name"></a> [ec2\_backup\_plan\_name](#input\_ec2\_backup\_plan\_name) | (Required) The display name of a backup plan. | `string` | `"ec2_prod_backups"` | no |
| <a name="input_enable_organization_backup"></a> [enable\_organization\_backup](#input\_enable\_organization\_backup) | (Optional) A boolean to enable or disable the AWS Backup Organization functionality. If set to 'true' this transitions from a single backup plan to organization plan policies. Defaults to false. | `bool` | `false` | no |
| <a name="input_hourly_backup_retention"></a> [hourly\_backup\_retention](#input\_hourly\_backup\_retention) | (Required) The hourly backup plan retention in days. By default this is 3 days. | `number` | `3` | no |
| <a name="input_hourly_backup_schedule"></a> [hourly\_backup\_schedule](#input\_hourly\_backup\_schedule) | (Required) The hourly backup plan schedule in cron format. By default this is set to run every hour at 20 minutes past the hour. | `string` | `"cron(20 * * * ? *)"` | no |
| <a name="input_key_bypass_policy_lockout_safety_check"></a> [key\_bypass\_policy\_lockout\_safety\_check](#input\_key\_bypass\_policy\_lockout\_safety\_check) | (Optional) Specifies whether to disable the policy lockout check performed when creating or updating the key's policy. Setting this value to true increases the risk that the CMK becomes unmanageable. For more information, refer to the scenario in the Default Key Policy section in the AWS Key Management Service Developer Guide. Defaults to false. | `bool` | `false` | no |
| <a name="input_key_customer_master_key_spec"></a> [key\_customer\_master\_key\_spec](#input\_key\_customer\_master\_key\_spec) | (Optional) Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values: SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1. Defaults to SYMMETRIC_DEFAULT. For help with choosing a key spec, see the AWS KMS Developer Guide. | `string` | `"SYMMETRIC_DEFAULT"` | no |
| <a name="input_key_deletion_window_in_days"></a> [key\_deletion\_window\_in\_days](#input\_key\_deletion\_window\_in\_days) | (Optional) Duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days. Defaults to 30 days. | `number` | `30` | no |
| <a name="input_key_description"></a> [key\_description](#input\_key\_description) | (Optional) The description of the key as viewed in AWS console. | `string` | `"AWS backups kms key used to encrypt backups"` | no |
| <a name="input_key_enable_key_rotation"></a> [key\_enable\_key\_rotation](#input\_key\_enable\_key\_rotation) | (Optional) Specifies whether key rotation is enabled. Defaults to false. | `bool` | `true` | no |
| <a name="input_key_is_enabled"></a> [key\_is\_enabled](#input\_key\_is\_enabled) | (Optional) Specifies whether the key is enabled. Defaults to true. | `string` | `true` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | (Optional) The display name of the alias. The name must start with the word 'alias' followed by a forward slash | `string` | `"alias/aws_backup_key"` | no |
| <a name="input_key_policy"></a> [key\_policy](#input\_key\_policy) | (Optional) A valid policy JSON document. Although this is a key policy, not an IAM policy, an aws_iam_policy_document, in the form that designates a principal, can be used. For more information about building policy documents with Terraform, see the AWS IAM Policy Document Guide. | `string` | `null` | no |
| <a name="input_key_usage"></a> [key\_usage](#input\_key\_usage) | (Optional) Specifies the intended use of the key. Defaults to ENCRYPT_DECRYPT, and only symmetric encryption and decryption are supported. | `string` | `"ENCRYPT_DECRYPT"` | no |
| <a name="input_monthly_backup_retention"></a> [monthly\_backup\_retention](#input\_monthly\_backup\_retention) | (Required) The daily backup plan retention in days. By default this is 365 days. | `number` | `365` | no |
| <a name="input_monthly_backup_schedule"></a> [monthly\_backup\_schedule](#input\_monthly\_backup\_schedule) | (Required) The monthly backup plan schedule in cron format. By default this is set to run on the first day of every month at 9:20 AM UTC. | `string` | `"cron(20 9 1 * ? *)"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the object. | `map(any)` | <pre>{<br>  "aws_backup": "true",<br>  "created_by": "<YOUR_NAME>",<br>  "environment": "prod",<br>  "priority": "critical",<br>  "service": "backups",<br>  "terraform": "true"<br>}</pre> | no |
| <a name="input_vault_disaster_recovery_name"></a> [vault\_disaster\_recovery\_name](#input\_vault\_disaster\_recovery\_name) | value | `string` | `"vault_disaster_recovery"` | no |
| <a name="input_vault_prod_daily_name"></a> [vault\_prod\_daily\_name](#input\_vault\_prod\_daily\_name) | value | `string` | `"vault_prod_daily"` | no |
| <a name="input_vault_prod_hourly_name"></a> [vault\_prod\_hourly\_name](#input\_vault\_prod\_hourly\_name) | value | `string` | `"vault_prod_hourly"` | no |
| <a name="input_vault_prod_monthly_name"></a> [vault\_prod\_monthly\_name](#input\_vault\_prod\_monthly\_name) | value | `string` | `"vault_prod_monthly"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backup_plan_arn"></a> [backup\_plan\_arn](#output\_backup\_plan\_arn) | The ARN of the backup plan |
| <a name="output_backup_plan_id"></a> [backup\_plan\_id](#output\_backup\_plan\_id) | The ID of the backup plan |
| <a name="output_backup_plan_version"></a> [backup\_plan\_version](#output\_backup\_plan\_version) | The version of the backup plan |
| <a name="output_backup_vault_arn"></a> [backup\_vault\_arn](#output\_backup\_vault\_arn) | The ARN of the backup vault |
| <a name="output_backup_vault_id"></a> [backup\_vault\_id](#output\_backup\_vault\_id) | The ID of the backup vault |
| <a name="output_backup_vault_recovery_points"></a> [backup\_vault\_recovery\_points](#output\_backup\_vault\_recovery\_points) | The number of recovery points in the backup vault |
| <a name="output_ec2_backup_plan_arn"></a> [ec2\_backup\_plan\_arn](#output\_ec2\_backup\_plan\_arn) | The ARN of the EC2 backup plan |
| <a name="output_ec2_backup_plan_id"></a> [ec2\_backup\_plan\_id](#output\_ec2\_backup\_plan\_id) | The ID of the EC2 backup plan |
| <a name="output_ec2_backup_plan_version"></a> [ec2\_backup\_plan\_version](#output\_ec2\_backup\_plan\_version) | The version of the EC2 backup plan |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the KMS key used for backup encryption |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The ID of the KMS key used for backup encryption |
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