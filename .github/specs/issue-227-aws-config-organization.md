# Spec: Add AWS Config organization module
**Issue:** #227
**Status:** Spec approved — implementation complete in PR #225
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
AWS Config is not enabled across the organization. No centralized resource inventory or compliance recording exists. DEVSECOPS-32 requires enabling Config org-wide with read/reporting scope — recording resource configurations and delivering them to S3 — but without enforcement rules that could disrupt existing infrastructure. The module mirrors the `guardduty/organization` and `security_hub/organization` dual-provider pattern already in use.

## 2. Non-goals
- Does not create enforcement/remediation rules (read/reporting only).
- Does not manage per-account Config recorders outside the delegated admin account.
- Does not manage Config aggregators (future work).
- Does not manage the IAM role for Config (caller supplies `recorder_role_arn`).

## 3. Affected module path(s)
- `modules/aws/config/organization/` (new)

## 4. Proposed design

### `variables.tf`
| Name | Type | Default | Description |
|---|---|---|---|
| `admin_account_id` | `string` | required | Delegated admin account ID |
| `recorder_name` | `string` | `"default"` | Fixed name for import capability |
| `recorder_role_arn` | `string` | required | IAM role ARN for Config recorder |
| `create_s3_bucket` | `bool` | `true` | Create S3 delivery bucket |
| `s3_bucket_name` | `string` | `null` | Existing bucket name when create_s3_bucket=false |
| `s3_key_prefix` | `string` | `null` | Key prefix for Config delivery in bucket |
| `sns_topic_arn` | `string` | `null` | Optional SNS topic for notifications |
| `delivery_frequency` | `string` | `"TwentyFour_Hours"` | One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours |
| `include_global_resource_types` | `bool` | `true` | Record global resources (IAM, etc.) |
| `enable_conformance_packs` | `bool` | `false` | Enable org conformance packs |
| `conformance_packs` | `list(object)` | `[]` | List of conformance pack definitions |
| `tags` | `map(string)` | `{}` | Tags |

### `outputs.tf`
- `recorder_name` — configuration recorder name
- `delivery_channel_name` — delivery channel name
- `s3_bucket_id` — delivery bucket ID (null when using existing)
- `s3_bucket_arn` — delivery bucket ARN
- `delegated_admin_id` — delegated administrator resource ID

### `main.tf`
- Provider aliases: `aws.organization_management_account`, `aws.organization_config_account`
- `aws_organizations_delegated_administrator.this` (management provider)
- `aws_s3_bucket.config` (config_account provider, count-gated)
- `aws_config_configuration_recorder.this` (config_account provider)
- `aws_config_delivery_channel.this` (config_account provider, depends on recorder)
- `aws_config_configuration_recorder_status.this` (config_account provider)
- `aws_config_organization_conformance_pack.this` (config_account provider, for_each-gated)

## 5. Breaking-change assessment
- Breaking: **no** — new module with no existing callers.

## 6. Checkov / tfsec considerations
- S3 delivery bucket created with SSE-KMS, versioning, and public access blocked.
- New suppressions: none anticipated if bucket uses managed KMS key.

## 7. terraform-docs impact
New `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/config/organization/README.md` — auto-injected by CI `build.yml`.

## 8. Testing
- `terraform -chdir=modules/aws/config/organization init -backend=false && terraform -chdir=modules/aws/config/organization validate`
- Expected: "Provider configuration not present" warning (identical to guardduty/organization behavior for configuration_aliases).
- `terraform fmt -check -diff -recursive`

## 9. Open questions
None — implementation complete.

## 10. Acceptance criteria
- `modules/aws/config/organization/` contains main.tf, variables.tf, outputs.tf, README.md
- Dual-provider pattern matching guardduty/organization
- Registers delegated administrator for `config.amazonaws.com`
- Creates recorder, recorder status, and delivery channel
- S3 bucket creation optional; accepts existing bucket name
- Conformance packs disabled by default, togglable
