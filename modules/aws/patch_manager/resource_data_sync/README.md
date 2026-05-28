# patch_manager/resource_data_sync

Creates an AWS Systems Manager Resource Data Sync that aggregates SSM inventory and patch compliance data to an S3 bucket. Supports a centralized org-wide pattern where one account owns the destination bucket and all other accounts sync into it.

## Usage

### Central account (creates bucket)

```hcl
data "aws_organizations_organization" "current" {}

module "ssm_data_sync_central" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/patch_manager/resource_data_sync?ref=vX.Y.Z"

  name          = "org-ssm-sync"
  create_bucket = true
  org_id        = data.aws_organizations_organization.current.id
  prefix        = "ssm-data"
  retention_days = 365

  tags = {
    environment = "prod"
    terraform   = "true"
  }
}
```

### Member accounts (target central bucket)

```hcl
module "ssm_data_sync" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/patch_manager/resource_data_sync?ref=vX.Y.Z"

  name          = "org-ssm-sync"
  create_bucket = false
  bucket_name   = "org-ssm-sync-<management-account-id>"
  bucket_region = "us-west-1"
  prefix        = "ssm-data"
}
```

## Notes

- When `create_bucket = true` and `org_id` is set, the bucket policy restricts SSM writes to sources within your organization using `aws:SourceOrgID`.
- The `prefix` value must match between the central bucket policy and all member account sync configs.
- Data is queryable via Athena using the AWS Glue catalog once synced.
- `sync_format = "JsonSerDe"` (default) is recommended for Athena compatibility.
