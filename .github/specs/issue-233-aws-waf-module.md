# Spec: Add AWS WAFv2 module
**Issue:** #233
**Status:** Spec approved — implementation complete in PR #144
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
No reusable WAFv2 module exists in the library. DEVSECOPS-4 requires a WAF module to protect ALBs, API Gateways, AppSync APIs, and Cognito user pools. PR #144 (`dev_waf` branch) contains a complete implementation that has been waiting for the spec/issue pipeline to catch up.

## 2. Non-goals
- Does not manage WAFv2 logging configuration (future work).
- Does not manage WAFv2 regex pattern sets.
- Does not manage CloudFront distributions (caller must set provider to us-east-1 when scope = CLOUDFRONT).
- Does not manage AWS Shield Advanced.

## 3. Affected module path(s)
- `modules/aws/waf/` (new)

## 4. Proposed design

### `variables.tf`
| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | required | Web ACL name |
| `scope` | `string` | `"REGIONAL"` | REGIONAL or CLOUDFRONT |
| `default_action` | `string` | `"block"` | allow or block — validated string (not object); defaults to block for secure posture |
| `description` | `string` | `null` | Web ACL description |
| `ip_sets` | `map(object)` | `{}` | Map of IP set definitions (name → addresses, ip_address_version) |
| `rule` | `list(any)` | `[]` | List of rule objects; supports managed_rule_group_statement and ip_set_reference_statement |
| `associate_with_resource` | `string` | `null` | Optional ARN to associate Web ACL with (ALB, API GW, etc.) |
| `visibility_config` | `object` | required | cloudwatch_metrics_enabled, metric_name (optional, falls back to name), sampled_requests_enabled |
| `tags` | `map(string)` | `{}` | Tags |

### `outputs.tf`
- `waf_acl_arn` — Web ACL ARN
- `waf_acl_id` — Web ACL ID
- `waf_acl_name` — Web ACL name
- `ip_sets` — map of IP set objects (id, arn per set)
- `association_id` — resource association ID (null when not associated)
- `associated_resource_arn` — associated resource ARN (null when not associated)

### `main.tf`
- Data sources: `aws_caller_identity.current`, `aws_region.current`
- Locals: `visibility_metric_name` via `coalesce(var.visibility_config.metric_name, var.name)`
- `aws_wafv2_ip_set.this` — `for_each` over `var.ip_sets`
- `aws_wafv2_web_acl.this` — primary resource; dynamic `default_action` block (allow/block); dynamic `rule` block with nested dynamic `action`/`override_action` and statement blocks
- `aws_wafv2_web_acl_association.this` — `count = var.associate_with_resource != null ? 1 : 0`
- Rules use `rule_action_override` (not deprecated `excluded_rules`) for managed rule groups
- Tags via `merge(tomap({ Name = var.name }), var.tags)`

## 5. Breaking-change assessment
- Breaking: **no** — new module with no existing callers.

## 6. Checkov / tfsec considerations
- New suppressions: none anticipated. WAFv2 resources do not commonly trigger Checkov suppressions.

## 7. terraform-docs impact
New `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/waf/README.md` — auto-injected by CI `build.yml`.

## 8. Testing
- `terraform -chdir=modules/aws/waf init -backend=false && terraform -chdir=modules/aws/waf validate`
- `terraform fmt -check -diff -recursive`

## 9. Open questions
None — implementation complete in PR #144.

## 10. Acceptance criteria
- `modules/aws/waf/` contains main.tf, variables.tf, outputs.tf, README.md
- `default_action` is a validated string (allow/block), not an object
- Rules support both `action` (IP set / regex) and `override_action` (managed rule groups)
- `managed_rule_group_statement` uses `rule_action_override` (not deprecated `excluded_rules`)
- `scope` defaults to REGIONAL with validation
- IP sets created via `for_each` over a map
- Optional resource association count-gated
- `terraform validate` passes
