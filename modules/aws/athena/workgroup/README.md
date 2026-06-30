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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_athena_workgroup.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/athena_workgroup) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bytes_scanned_cutoff_per_query"></a> [bytes\_scanned\_cutoff\_per\_query](#input\_bytes\_scanned\_cutoff\_per\_query) | (Optional) Integer for the upper data usage limit (cutoff) for the amount of bytes a single query in a workgroup is allowed to scan. Must be at least 10485760 (10 MB). A value of null disables the cutoff. | `number` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional) Description of the workgroup. | `string` | `null` | no |
| <a name="input_enable_minimum_encryption_configuration"></a> [enable\_minimum\_encryption\_configuration](#input\_enable\_minimum\_encryption\_configuration) | (Optional) Boolean indicating whether a minimum level of encryption is enforced for the workgroup for query and calculation results written to Amazon S3. Defaults to false. | `bool` | `false` | no |
| <a name="input_encryption_option"></a> [encryption\_option](#input\_encryption\_option) | (Optional) Indicates whether Amazon S3 server-side encryption with Amazon S3-managed keys (SSE\_S3), server-side encryption with KMS-managed keys (SSE\_KMS), or client-side encryption with KMS-managed keys (CSE\_KMS) is used. If null, no encryption configuration is applied. | `string` | `null` | no |
| <a name="input_enforce_workgroup_configuration"></a> [enforce\_workgroup\_configuration](#input\_enforce\_workgroup\_configuration) | (Optional) Boolean whether the settings for the workgroup, which include limits on the amount of data each query or the entire workgroup can process and the encryption configuration, are overridden by the client-side settings. Defaults to true. | `bool` | `true` | no |
| <a name="input_execution_role"></a> [execution\_role](#input\_execution\_role) | (Optional) Role used to access user resources in notebook sessions and IAM Identity Center enabled workgroups. Required for IAM Identity Center enabled workgroups. | `string` | `null` | no |
| <a name="input_expected_bucket_owner"></a> [expected\_bucket\_owner](#input\_expected\_bucket\_owner) | (Optional) AWS account ID expected to own the S3 bucket where query results are stored. Used to prevent data exfiltration. | `string` | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | (Optional) Option to delete the workgroup and its contents even if the workgroup contains any named queries. Defaults to false. | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | (Optional) For SSE\_KMS and CSE\_KMS, the ARN of the KMS key used to encrypt query results. Required when encryption\_option is SSE\_KMS or CSE\_KMS. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Name of the workgroup. | `string` | n/a | yes |
| <a name="input_output_location"></a> [output\_location](#input\_output\_location) | (Optional) The location in Amazon S3 where your query results are stored, such as s3://path/to/query/bucket/. If null, no default output location is set. | `string` | `null` | no |
| <a name="input_publish_cloudwatch_metrics_enabled"></a> [publish\_cloudwatch\_metrics\_enabled](#input\_publish\_cloudwatch\_metrics\_enabled) | (Optional) Boolean whether Amazon CloudWatch metrics are enabled for the workgroup. Defaults to true. | `bool` | `true` | no |
| <a name="input_requester_pays_enabled"></a> [requester\_pays\_enabled](#input\_requester\_pays\_enabled) | (Optional) If true, allows workgroup members to reference Amazon S3 Requester Pays buckets in queries. Defaults to false. | `bool` | `false` | no |
| <a name="input_s3_acl_option"></a> [s3\_acl\_option](#input\_s3\_acl\_option) | (Optional) Amazon S3 canned ACL to set on stored query results. Valid value is BUCKET\_OWNER\_FULL\_CONTROL. If null, no ACL configuration is applied. | `string` | `null` | no |
| <a name="input_selected_engine_version"></a> [selected\_engine\_version](#input\_selected\_engine\_version) | (Optional) Requested Athena engine version. Defaults to AUTO if not set. See https://docs.aws.amazon.com/athena/latest/ug/engine-versions.html. | `string` | `null` | no |
| <a name="input_state"></a> [state](#input\_state) | (Optional) State of the workgroup. Valid values are ENABLED or DISABLED. Defaults to ENABLED. | `string` | `"ENABLED"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the Athena workgroup. |
| <a name="output_id"></a> [id](#output\_id) | The name of the Athena workgroup, which serves as its ID. |
<!-- END_TF_DOCS -->
<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasaurus)
- [Brad Engberg](https://github.com/bradms98)
