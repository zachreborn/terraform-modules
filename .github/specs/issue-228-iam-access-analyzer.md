# Spec: Add IAM Access Analyzer sub-module
**Issue:** #228
**Status:** Spec approved — implementation complete in PR #224
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
No programmatic detection of externally-shared IAM resources (S3 buckets, IAM roles, KMS keys, Lambda functions, etc.) exists across the organization. DEVSECOPS-36 requires enabling IAM Access Analyzer for external access detection at the organization level. The module follows the `guardduty/organization` / `security_hub/organization` dual-provider pattern.

## 2. Non-goals
- Does not manage analyzer findings or archive rule automation (those are operational, not infrastructure).
- Does not manage per-account analyzers (organization-level covers all accounts).
- Does not manage SNS notifications for findings.

## 3. Affected module path(s)
- `modules/aws/iam/access_analyzer/` (new sub-module under existing `iam/` family)

## 4. Proposed design

### `variables.tf`
| Name | Type | Default | Description |
|---|---|---|---|
| `analyzer_name` | `string` | required | Name of the analyzer |
| `analyzer_type` | `string` | `"ORGANIZATION"` | ACCOUNT, ACCOUNT_UNUSED_ACCESS, ORGANIZATION, ORGANIZATION_UNUSED_ACCESS |
| `admin_account_id` | `string` | required | Delegated admin/security account ID |
| `register_delegated_admin` | `bool` | `true` | Set false if already registered |
| `archive_rules` | `list(object)` | `[]` | Dynamic archive rule blocks |
| `tags` | `map(string)` | `{}` | Tags |

### `outputs.tf`
- `analyzer_id` — analyzer resource ID
- `analyzer_arn` — analyzer ARN
- `analyzer_name` — analyzer name
- `delegated_admin_id` — delegated admin resource ID (null when registration skipped)

### `main.tf`
- Provider aliases: `aws.organization_management_account`, `aws.organization_security_account`
- `aws_organizations_delegated_administrator.this` (management provider, `count = var.register_delegated_admin ? 1 : 0`)
- `aws_accessanalyzer_analyzer.this` (security_account provider)
- Dynamic `archive_rule` block with nested `filter` dynamic block

## 5. Breaking-change assessment
- Breaking: **no** — new sub-module with no existing callers.

## 6. Checkov / tfsec considerations
- New suppressions: none anticipated.

## 7. terraform-docs impact
New `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/iam/access_analyzer/README.md` — auto-injected by CI `build.yml`.

## 8. Testing
- `terraform -chdir=modules/aws/iam/access_analyzer init -backend=false && terraform -chdir=modules/aws/iam/access_analyzer validate`
- Expected: "Provider configuration not present" warning (identical to guardduty/organization behavior for configuration_aliases).
- `terraform fmt -check -diff -recursive`

## 9. Open questions
None — implementation complete.

## 10. Acceptance criteria
- `modules/aws/iam/access_analyzer/` contains main.tf, variables.tf, outputs.tf, README.md
- Dual-provider pattern matching guardduty/organization
- Registers delegated administrator for `access-analyzer.amazonaws.com` (count-gated)
- Supports all 4 analyzer types including ORGANIZATION_UNUSED_ACCESS
- Archive rules supported via dynamic block
