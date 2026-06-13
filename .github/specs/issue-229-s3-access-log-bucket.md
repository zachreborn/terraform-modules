# Spec: Add centralized S3 access log bucket sub-module
**Issue:** #229
**Status:** Spec approved — implementation complete in PR #222
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
S3 access logs have no standardized centralized destination. Each bucket requires manual log configuration and there is no standard landing zone for org-wide S3 audit logs. DEVSECOPS-37 requires configuring S3 access logs to a centralized location. The existing `s3/bucket` module already supports the source-side `enable_s3_bucket_logging` variable; this sub-module provides the destination bucket with the correct hardened configuration that the S3 log delivery service requires.

## 2. Non-goals
- Does not configure logging on source buckets (that remains the `s3/bucket` module's concern via `enable_s3_bucket_logging`).
- Does not support SSE-KMS encryption — the S3 log delivery service cannot write to SSE-KMS encrypted destinations.
- Does not expose ACL or ownership as variables — both are fixed by the S3 log delivery service's requirements.
- Does not manage bucket replication.

## 3. Affected module path(s)
- `modules/aws/s3/access_log_bucket/` (new sub-module under existing `s3/` family)

## 4. Proposed design

### `variables.tf`
| Name | Type | Default | Description |
|---|---|---|---|
| `bucket` | `string` | required | Fixed bucket name for import capability |
| `bucket_force_destroy` | `bool` | `false` | Destroy bucket even if not empty |
| `enable_versioning` | `bool` | `false` | Enable bucket versioning |
| `lifecycle_rules` | `any` | `null` | Nullable lifecycle rules list (same structure as s3/bucket) |
| `tags` | `map(string)` | `{}` | Tags |

### `outputs.tf`
- `bucket_id` — bucket name
- `bucket_arn` — bucket ARN
- `bucket_domain_name` — bucket domain name
- `bucket_regional_domain_name` — bucket regional domain name

### `main.tf`
- `aws_s3_bucket.this` — primary bucket (fixed name)
- `aws_s3_bucket_ownership_controls.this` — `BucketOwnerPreferred` (hardcoded — required for log-delivery-write ACL)
- `aws_s3_bucket_acl.this` — `log-delivery-write` (hardcoded — required for S3 log delivery service)
- `aws_s3_bucket_server_side_encryption_configuration.this` — AES256 (hardcoded — SSE-KMS unsupported by log delivery service)
- `aws_s3_bucket_public_access_block.this` — all 4 flags true (hardcoded)
- `aws_s3_bucket_versioning.this` — count-gated by `var.enable_versioning`
- `aws_s3_bucket_lifecycle_configuration.this` — count-gated, dynamic rule block matching s3/bucket pattern
- `aws_s3_bucket_policy.this` — always applied; two statements: DenyInsecureTransport + AllowS3LogDelivery

## 5. Breaking-change assessment
- Breaking: **no** — new sub-module with no existing callers.

## 6. Checkov / tfsec considerations
- Checkov may flag that the bucket ACL is `log-delivery-write` rather than `private` — suppress with rationale (required for S3 log delivery service).
- New suppressions: one anticipated on `aws_s3_bucket_acl` if Checkov flags non-private ACL.

## 7. terraform-docs impact
New `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/s3/access_log_bucket/README.md` — auto-injected by CI `build.yml`.

## 8. Testing
- `terraform -chdir=modules/aws/s3/access_log_bucket init -backend=false && terraform -chdir=modules/aws/s3/access_log_bucket validate`
- `terraform fmt -check -diff -recursive`

## 9. Open questions
None — implementation complete.

## 10. Acceptance criteria
- `modules/aws/s3/access_log_bucket/` contains main.tf, variables.tf, outputs.tf, README.md
- SSE-S3 (AES256) encryption hardcoded — no KMS option
- `BucketOwnerPreferred` + `log-delivery-write` ACL hardcoded
- All 4 public access block flags hardcoded to true
- Bucket policy includes DenyInsecureTransport + AllowS3LogDelivery statements
- `terraform validate` passes
