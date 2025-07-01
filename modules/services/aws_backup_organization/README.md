# AWS Backup Organization Module

This module provides organization-wide AWS Backup management for multi-account environments. It deploys backup vaults across all organization accounts while managing policies centrally from the backup management account.

## Key Features

- **Organization-wide backup policies** managed centrally
- **Distributed vault deployment** across all member accounts
- **Cross-account backup copying** to disaster recovery regions
- **Automated vault lifecycle management** with Lambda functions
- **Comprehensive monitoring** and alerting
- **Tag-based resource selection** for flexible backup targeting
- **EventBridge integration** for automatic deployment to new accounts

## Architecture Overview

This module implements a hybrid approach to AWS Backup in Organizations:

1. **Central Policy Management**: Backup policies created from management/delegated admin account
2. **Distributed Vault Storage**: Backup vaults created in each member account
3. **Cross-Region Replication**: Daily backups automatically copied to DR regions
4. **Lambda-Based Deployment**: Deploys vaults via cross-account roles with fallback options
5. **Event-Driven Updates**: Automatically deploys to new organization accounts

## Requirements

- AWS Organizations must be enabled
- Must be deployed from organization management account or delegated backup admin account
- Member accounts need cross-account role (OrganizationAccountAccessRole, AWSControlTowerExecution, or BackupAdministratorRole)
- AWS Backup enabled as trusted service in organization
- CloudTrail enabled for EventBridge organization change detection

## Usage

### Basic Example

```hcl
module "organization_backup" {
  source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup_organization"

  aws_prod_region = "us-west-2"
  aws_dr_region   = "us-east-2"

  tags = {
    environment = "prod"
    created_by  = "terraform"
    service     = "backups"
  }
}
```

### Delegated Admin Example

```hcl
module "organization_backup" {
  source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup_organization"

  aws_prod_region = "us-west-2"
  aws_dr_region   = "us-east-2"

  # For delegated admin accounts
  cross_account_role_name = "BackupAdministratorRole"

  tags = {
    environment = "prod"
    created_by  = "Jake Jones"
    service     = "backups"
    priority    = "critical"
  }
}
```

## How It Works

### Lambda Execution Frequency
- **Initial Deployment**: Runs once during Terraform apply
- **New Accounts**: Automatically triggered via EventBridge when new accounts join organization
- **Manual Trigger**: Can be invoked manually via AWS Console/CLI

### Vault Deployment Logic
- **Production Region**: Creates hourly, daily, and monthly vaults in each account
- **DR Region**: Creates only disaster recovery vault in each account
- **Delegated Admin Account**: Skipped (vaults managed separately)

## Resource Tagging for Backups

```hcl
resource "aws_instance" "example" {
  # ... other configuration ...

  tags = {
    backup = "true"  # Include in backups
  }
}
```

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

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_global_settings.organization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_global_settings) | resource |
| [aws_cloudwatch_event_rule.organization_changes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.vault_deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_metric_alarm.backup_failures](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_role.cross_account_backup_deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vault_deployment_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cross_account_backup_deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.vault_deployment_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.backup_org_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.vault_deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_invocation.deploy_vaults](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_invocation) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_organizations_policy.backup_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) | resource |
| [aws_organizations_policy_attachment.backup_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_sns_topic.backup_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_accounts.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_accounts) | data source |
| [aws_organizations_organization.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_dr_region"></a> [aws\_dr\_region](#input\_aws\_dr\_region) | AWS disaster recovery region where DR backup vaults will be created | `string` | `"us-east-2"` | no |
| <a name="input_aws_prod_region"></a> [aws\_prod\_region](#input\_aws\_prod\_region) | AWS production region where primary backup vaults will be created | `string` | `"us-west-2"` | no |
| <a name="input_backup_plan_completion_window"></a> [backup\_plan\_completion\_window](#input\_backup\_plan\_completion\_window) | (Optional) The amount of time in minutes AWS Backup attempts a backup before canceling the job and returning an error | `number` | `1440` | no |
| <a name="input_backup_plan_name"></a> [backup\_plan\_name](#input\_backup\_plan\_name) | (Required) The display name of the organization backup plan | `string` | `"organization_backup_plan"` | no |
| <a name="input_backup_plan_start_window"></a> [backup\_plan\_start\_window](#input\_backup\_plan\_start\_window) | (Optional) The amount of time in minutes before beginning a backup | `number` | `60` | no |
| <a name="input_backup_tag_key"></a> [backup\_tag\_key](#input\_backup\_tag\_key) | (Optional) Tag key used to identify resources for backup | `string` | `"backup"` | no |
| <a name="input_backup_tag_value"></a> [backup\_tag\_value](#input\_backup\_tag\_value) | (Optional) Tag value used to identify resources for backup | `string` | `"true"` | no |
| <a name="input_changeable_for_days"></a> [changeable\_for\_days](#input\_changeable\_for\_days) | (Optional) The number of days after which the vault lock configuration is no longer changeable | `number` | `3` | no |
| <a name="input_cross_account_role_name"></a> [cross\_account\_role\_name](#input\_cross\_account\_role\_name) | (Optional) Name of the cross-account role for backup vault deployment | `string` | `"OrganizationAccountAccessRole"` | no |
| <a name="input_daily_backup_retention"></a> [daily\_backup\_retention](#input\_daily\_backup\_retention) | (Required) The daily backup plan retention in days | `number` | `30` | no |
| <a name="input_daily_backup_schedule"></a> [daily\_backup\_schedule](#input\_daily\_backup\_schedule) | (Required) The daily backup plan schedule in cron format | `string` | `"cron(20 7 * * ? *)"` | no |
| <a name="input_dr_backup_retention"></a> [dr\_backup\_retention](#input\_dr\_backup\_retention) | (Required) The disaster recovery backup plan retention in days | `number` | `7` | no |
| <a name="input_enable_backup_notifications"></a> [enable\_backup\_notifications](#input\_enable\_backup\_notifications) | (Optional) Enable SNS notifications for backup job status | `bool` | `true` | no |
| <a name="input_excluded_account_ids"></a> [excluded\_account\_ids](#input\_excluded\_account\_ids) | (Optional) List of account IDs to exclude from backup policy deployment | `list(string)` | `[]` | no |
| <a name="input_hourly_backup_retention"></a> [hourly\_backup\_retention](#input\_hourly\_backup\_retention) | (Required) The hourly backup plan retention in days | `number` | `3` | no |
| <a name="input_hourly_backup_schedule"></a> [hourly\_backup\_schedule](#input\_hourly\_backup\_schedule) | (Required) The hourly backup plan schedule in cron format | `string` | `"cron(20 * * * ? *)"` | no |
| <a name="input_key_deletion_window_in_days"></a> [key\_deletion\_window\_in\_days](#input\_key\_deletion\_window\_in\_days) | (Optional) Duration in days after which the key is deleted after destruction of the resource | `number` | `30` | no |
| <a name="input_key_description"></a> [key\_description](#input\_key\_description) | (Optional) The description of the KMS key as viewed in AWS console | `string` | `"AWS backups kms key used to encrypt backups"` | no |
| <a name="input_key_enable_key_rotation"></a> [key\_enable\_key\_rotation](#input\_key\_enable\_key\_rotation) | (Optional) Specifies whether key rotation is enabled | `bool` | `true` | no |
| <a name="input_monthly_backup_retention"></a> [monthly\_backup\_retention](#input\_monthly\_backup\_retention) | (Required) The monthly backup plan retention in days | `number` | `365` | no |
| <a name="input_monthly_backup_schedule"></a> [monthly\_backup\_schedule](#input\_monthly\_backup\_schedule) | (Required) The monthly backup plan schedule in cron format | `string` | `"cron(20 9 1 * ? *)"` | no |
| <a name="input_notification_email"></a> [notification\_email](#input\_notification\_email) | (Optional) Email address for backup notifications | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to all resources | `map(any)` | <pre>{<br/>  "aws_backup": "true",<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "priority": "critical",<br/>  "service": "backups",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_target_organizational_units"></a> [target\_organizational\_units](#input\_target\_organizational\_units) | (Optional) List of organizational unit IDs to target for backup policy. If empty, applies to root | `list(string)` | `[]` | no |
| <a name="input_vault_disaster_recovery_name"></a> [vault\_disaster\_recovery\_name](#input\_vault\_disaster\_recovery\_name) | Name for disaster recovery backup vault | `string` | `"vault_disaster_recovery"` | no |
| <a name="input_vault_prod_daily_name"></a> [vault\_prod\_daily\_name](#input\_vault\_prod\_daily\_name) | Name for production daily backup vault | `string` | `"vault_prod_daily"` | no |
| <a name="input_vault_prod_hourly_name"></a> [vault\_prod\_hourly\_name](#input\_vault\_prod\_hourly\_name) | Name for production hourly backup vault | `string` | `"vault_prod_hourly"` | no |
| <a name="input_vault_prod_monthly_name"></a> [vault\_prod\_monthly\_name](#input\_vault\_prod\_monthly\_name) | Name for production monthly backup vault | `string` | `"vault_prod_monthly"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_active_accounts"></a> [active\_accounts](#output\_active\_accounts) | List of active accounts in the organization |
| <a name="output_backup_configuration"></a> [backup\_configuration](#output\_backup\_configuration) | Summary of backup configuration |
| <a name="output_backup_failure_alarm_arn"></a> [backup\_failure\_alarm\_arn](#output\_backup\_failure\_alarm\_arn) | ARN of the CloudWatch alarm for backup failures |
| <a name="output_backup_notifications_topic_arn"></a> [backup\_notifications\_topic\_arn](#output\_backup\_notifications\_topic\_arn) | ARN of the SNS topic for backup notifications |
| <a name="output_backup_policy_arn"></a> [backup\_policy\_arn](#output\_backup\_policy\_arn) | The ARN of the organization backup policy |
| <a name="output_backup_policy_id"></a> [backup\_policy\_id](#output\_backup\_policy\_id) | The ID of the organization backup policy |
| <a name="output_cross_account_deployment_role_arn"></a> [cross\_account\_deployment\_role\_arn](#output\_cross\_account\_deployment\_role\_arn) | ARN of the cross-account deployment role |
| <a name="output_deployment_results"></a> [deployment\_results](#output\_deployment\_results) | Results from the vault deployment Lambda function |
| <a name="output_lambda_execution_role_arn"></a> [lambda\_execution\_role\_arn](#output\_lambda\_execution\_role\_arn) | ARN of the Lambda execution role |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | The ID of the AWS Organization |
| <a name="output_organization_root_id"></a> [organization\_root\_id](#output\_organization\_root\_id) | The root ID of the AWS Organization |
| <a name="output_total_active_accounts"></a> [total\_active\_accounts](#output\_total\_active\_accounts) | Total number of active accounts in the organization |
| <a name="output_vault_arn_template"></a> [vault\_arn\_template](#output\_vault\_arn\_template) | Template for vault ARNs across accounts |
| <a name="output_vault_deployment_function_arn"></a> [vault\_deployment\_function\_arn](#output\_vault\_deployment\_function\_arn) | ARN of the Lambda function used for vault deployment |
| <a name="output_vault_deployment_function_name"></a> [vault\_deployment\_function\_name](#output\_vault\_deployment\_function\_name) | Name of the Lambda function used for vault deployment |
<!-- END_TF_DOCS -->