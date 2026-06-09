# Spec: Add AWS Budgets module
**Issue:** #226
**Status:** Spec approved — implementation complete in PR #223
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
No programmatic AWS budget enforcement exists today. Accounts can accumulate unexpected charges with no alerting. DEVSECOPS-30 requires creating budgets for the org and all member accounts. The `aws_prod_organization` baseline already uses a `for_each = var.accounts` fan-out pattern (athena, password_policy) to apply per-account configuration; this module follows the same pattern.

## 2. Non-goals
- Does not create budgets in `aws_prod_organization` itself — that caller code is out of scope for this module.
- Does not manage Cost Explorer reports or Cost Anomaly Detection.
- Does not manage SNS topics (caller supplies ARNs).

## 3. Affected module path(s)
- `modules/aws/budgets/budget/` (new)

## 4. Proposed design

### `variables.tf`
| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | required | Budget name |
| `budget_type` | `string` | `"COST"` | COST, USAGE, RI_UTILIZATION, RI_COVERAGE, SAVINGS_PLANS_UTILIZATION, SAVINGS_PLANS_COVERAGE |
| `limit_amount` | `string` | required | Budget limit (e.g. "500") |
| `limit_unit` | `string` | `"USD"` | Currency or unit |
| `time_unit` | `string` | `"MONTHLY"` | DAILY, MONTHLY, QUARTERLY, ANNUALLY |
| `time_period_start` | `string` | `null` | Optional start date YYYY-MM-DD_HH:MM |
| `time_period_end` | `string` | `null` | Optional end date |
| `account_id` | `string` | `null` | AWS account ID — required for cross-account use from management account |
| `notification` | `list(object)` | `[]` | Dynamic notification blocks (threshold, type, comparison, subscribers) |
| `cost_filter` | `list(object)` | `[]` | Dynamic cost filter blocks (name + values) |
| `tags` | `map(string)` | `{}` | Tags |

### `outputs.tf`
- `id` — budget name/id
- `arn` — budget ARN
- `name` — budget name

### `main.tf`
- `aws_budgets_budget.this` — primary resource
- Dynamic `notification` block for threshold alerts (email + SNS)
- Dynamic `cost_filter` block for filtering by LinkedAccount, Service, etc.

## 5. Breaking-change assessment
- Breaking: **no** — new module with no existing callers.

## 6. Checkov / tfsec considerations
- New suppressions: none anticipated.

## 7. terraform-docs impact
New `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/budgets/budget/README.md` — auto-injected by CI `build.yml`.

## 8. Testing
- `terraform -chdir=modules/aws/budgets/budget init -backend=false && terraform -chdir=modules/aws/budgets/budget validate`
- `terraform fmt -check -diff -recursive`

## 9. Open questions
None — implementation complete.

## 10. Acceptance criteria
- `modules/aws/budgets/budget/` contains main.tf, variables.tf, outputs.tf, README.md
- `terraform validate` passes
- Supports per-account budget creation via `account_id`
- Dynamic `notification` block supports email and SNS subscribers
- Dynamic `cost_filter` block supports LinkedAccount, Service filters
