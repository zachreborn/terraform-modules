# Athena Workgroup Module

Manages an AWS Athena workgroup, including result configuration and encryption settings. Designed to support both creating new workgroups and importing pre-existing ones such as the default `primary` workgroup.

## Usage

### New workgroup with SSE_S3 encryption enforced

```hcl
module "athena_primary" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/athena/workgroup?ref=vX.X.X"

  name                            = "primary"
  description                     = "Default Athena workgroup with enforced SSE_S3 encryption"
  enforce_workgroup_configuration = true
  encryption_option               = "SSE_S3"

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

### Workgroup with KMS encryption and S3 output location

```hcl
module "athena_analytics" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/athena/workgroup?ref=vX.X.X"

  name                            = "analytics"
  description                     = "Analytics workgroup with KMS encryption"
  enforce_workgroup_configuration = true
  output_location                 = "s3://my-athena-results/analytics/"
  encryption_option               = "SSE_KMS"
  kms_key_arn                     = "arn:aws:kms:us-east-1:123456789012:key/abc123"

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

## Importing pre-existing workgroups

The default `primary` workgroup exists in every AWS account and cannot be created by Terraform — it must be imported:

```hcl
import {
  to = module.athena_primary.aws_athena_workgroup.this
  id = "primary"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 6.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the workgroup | `string` | n/a | yes |
| description | Description of the workgroup | `string` | `null` | no |
| state | State of the workgroup. ENABLED or DISABLED | `string` | `"ENABLED"` | no |
| force_destroy | Delete workgroup contents on destroy | `bool` | `false` | no |
| tags | Map of tags to assign to the resource | `map(string)` | `{}` | no |
| bytes_scanned_cutoff_per_query | Per-query data scan limit in bytes (min 10485760). Null disables the cutoff | `number` | `null` | no |
| enforce_workgroup_configuration | Prevent clients from overriding workgroup settings | `bool` | `true` | no |
| publish_cloudwatch_metrics_enabled | Enable CloudWatch metrics for the workgroup | `bool` | `true` | no |
| output_location | S3 URI for query results (e.g. s3://bucket/prefix/) | `string` | `null` | no |
| encryption_option | Encryption type: SSE_S3, SSE_KMS, or CSE_KMS. Null disables encryption config | `string` | `null` | no |
| kms_key_arn | KMS key ARN for SSE_KMS or CSE_KMS encryption | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Name/ID of the Athena workgroup |
| arn | ARN of the Athena workgroup |
