# S3 Access Log Bucket Module

This module creates a centralized S3 bucket configured as the **destination** for S3 server access logs. It wraps the `s3/bucket` module and enforces the constraints required by the AWS S3 log delivery service:

- **SSE-S3 (AES256)** encryption — the S3 log delivery service does not support SSE-KMS on target buckets.
- **`BucketOwnerPreferred`** ownership controls — required for the `log-delivery-write` ACL grant.
- **`log-delivery-write`** ACL — grants the AWS S3 log delivery group write permissions.
- All public access blocked.
- SSL enforcement with an explicit allow for `logging.s3.amazonaws.com`.

Source buckets should use the existing `s3/bucket` module with `enable_s3_bucket_logging = true` and `logging_target_bucket = <this bucket name>` to direct their logs here.

## Usage

```hcl
module "s3_access_logs" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/s3/access_log_bucket"

  bucket = "my-org-s3-access-logs"

  lifecycle_rules = [
    {
      id     = "expire-logs"
      status = "Enabled"
      expiration = {
        days = 365
      }
    }
  ]

  tags = {
    created_by  = "terraform"
    environment = "prod"
    terraform   = "true"
  }
}
```

To point a source bucket at this log bucket:

```hcl
module "my_bucket" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/s3/bucket"

  bucket                   = "my-application-bucket"
  enable_s3_bucket_logging = true
  logging_target_bucket    = module.s3_access_logs.bucket_id
  logging_target_prefix    = "my-application-bucket/"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| this | ../bucket | n/a |

## Resources

| Name | Type |
|------|------|
| aws_iam_policy_document.log_delivery | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| bucket | Fixed name for the centralized S3 access log bucket. | `string` | n/a | yes |
| bucket_force_destroy | When true, all objects are deleted from the bucket on destroy. | `bool` | `false` | no |
| enable_versioning | Enable versioning on the access log bucket. | `bool` | `false` | no |
| lifecycle_rules | List of lifecycle rule configuration maps. Set to null to disable. | `any` | `null` | no |
| tags | A mapping of tags to assign to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | Name (ID) of the S3 access log bucket |
| bucket_arn | ARN of the S3 access log bucket |
| bucket_region | Region of the S3 access log bucket |

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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_this"></a> [this](#module\_this) | ../bucket | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy_document.log_delivery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket"></a> [bucket](#input\_bucket) | (Required) Fixed name for the centralized S3 access log bucket. Used as a fixed name (not prefix) to support import capability. Must be lowercase, 3–63 characters. | `string` | n/a | yes |
| <a name="input_bucket_force_destroy"></a> [bucket\_force\_destroy](#input\_bucket\_force\_destroy) | (Optional) When true, all objects (including locked objects) are deleted from the bucket when the bucket is destroyed so that the bucket can be destroyed without error. Defaults to false. | `bool` | `false` | no |
| <a name="input_enable_versioning"></a> [enable\_versioning](#input\_enable\_versioning) | (Optional) Enable versioning on the access log bucket. When enabled, multiple versions of objects are retained. Defaults to false. | `bool` | `false` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | (Optional) Configuration of object lifecycle management. Can have several rules as a list of maps where each map is the lifecycle rule configuration. Set to null to disable lifecycle rules. | `any` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the bucket. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 access log bucket |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name (ID) of the S3 access log bucket |
| <a name="output_bucket_region"></a> [bucket\_region](#output\_bucket\_region) | Region of the S3 access log bucket |
<!-- END_TF_DOCS -->

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasarus)
- [Brad Engberg](https://github.com/bradms98)
