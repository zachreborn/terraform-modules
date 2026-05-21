# S3 Access Log Bucket Module

This module creates a centralized S3 bucket configured as the **destination** for S3 server access logs. It enforces the constraints required by the AWS S3 log delivery service:

- **SSE-S3 (AES256)** encryption — the S3 log delivery service does not support SSE-KMS on target buckets.
- **`BucketOwnerPreferred`** ownership controls — required for the `log-delivery-write` ACL grant.
- **`log-delivery-write`** ACL — grants the AWS S3 log delivery group write permissions.
- All public access blocked.
- SSL-only bucket policy with an explicit allow for `logging.s3.amazonaws.com`.

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

## Resources

| Name | Type |
|------|------|
| aws_s3_bucket.this | resource |
| aws_s3_bucket_ownership_controls.this | resource |
| aws_s3_bucket_acl.this | resource |
| aws_s3_bucket_server_side_encryption_configuration.this | resource |
| aws_s3_bucket_public_access_block.this | resource |
| aws_s3_bucket_lifecycle_configuration.this | resource |
| aws_s3_bucket_versioning.this | resource |
| aws_s3_bucket_policy.this | resource |
| aws_iam_policy_document.this | data source |

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
| bucket_domain_name | Bucket domain name (`<bucket>.s3.amazonaws.com`) |
| bucket_regional_domain_name | Region-specific bucket domain name (`<bucket>.s3.<region>.amazonaws.com`) |
