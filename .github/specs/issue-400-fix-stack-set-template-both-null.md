# Spec: bug(cloudformation/stack_set): providing both template_body+template_url silently nulls out both
**Issue:** #400
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/cloudformation/stack_set/main.tf` (lines 39–40) contains a pair of mutually-defeating ternaries:

```hcl
template_body = var.template_url == null ? var.template_body : null
template_url  = var.template_body == null ? var.template_url : null
```

When a caller supplies **both** `template_body` and `template_url`, each expression independently inspects the *other* variable for nullness and sets itself to null. The result is that **both** attributes are null in the resulting `aws_cloudformation_stack_set` configuration. Because `template_body` is `Optional+Computed` in the AWS provider schema, a real `apply` would create or update the stack set with no template source — a silently misconfigured resource.

The same bug exists in `modules/aws/cloudformation/stack` (tracked by #377) for both `policy_body`/`policy_url` and `template_body`/`template_url`. This spec covers the `stack_set` fix only; #377 covers `stack`.

Related issue: #377. Found via Copilot PR review on #385.

## 2. Non-goals
- This spec does **not** cover `modules/aws/cloudformation/stack` (#377 tracks that).
- This spec does **not** add new variables, outputs, or AWS resource types to the module.
- This spec does **not** change the fix approach for `operation_preferences` or any other attribute in the module.
- This spec does **not** address `modules/aws/cloudformation/stack_set_instance` or any other sibling module.

## 3. Affected module path(s)
- `modules/aws/cloudformation/stack_set/` (existing — bug fix)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes to variable signatures. The existing `var.template_body` and `var.template_url` declarations are correct (both `string`, `default = null`). The existing `validation` block on `var.template_url` (HTTPS URL check) is retained unchanged.

A new `validation` block is added to `var.template_body` to enforce mutual exclusivity at plan time:

| Variable | Type | Default | Change |
|---|---|---|---|
| `template_body` | `string` | `null` | Add `validation` block: fails when both `template_body` and `template_url` are non-null |
| `template_url` | `string` | `null` | No change |

**New validation block on `var.template_body`:**
```
variable "template_body" {
  description = "..."
  type        = string
  default     = null
  validation {
    condition     = !(var.template_body != null && var.template_url != null)
    error_message = "Only one of template_body or template_url may be set, not both."
  }
}
```

> **Note:** OpenTofu 1.9+ and Terraform 1.9+ support cross-variable references within `validation` blocks, making this pattern valid. The module already requires `>= 1.0.0` but the repository's standard toolchain is OpenTofu v1.6.x+; confirm the target OpenTofu version supports cross-variable validation. If cross-variable validation is unavailable, the alternative is a `lifecycle { precondition { ... } }` block inside `aws_cloudformation_stack_set.this` (see `main.tf` section below).

### `outputs.tf`
No changes. Existing outputs (`arn`, `name`, `id`) are unaffected.

### `main.tf`
The two broken ternary lines are replaced with direct variable pass-through. The provider's own "ConflictsWith" enforcement is the final backstop, but the new `validation` block (or `precondition`) catches the conflict before the provider is reached.

**`aws_cloudformation_stack_set.this` attribute changes:**

| Before | After |
|---|---|
| `template_body = var.template_url == null ? var.template_body : null` | `template_body = var.template_body` |
| `template_url  = var.template_body == null ? var.template_url : null` | `template_url  = var.template_url` |

**Alternative — `lifecycle.precondition` (if cross-variable `validation` is unavailable):**
Add a `precondition` block inside the `lifecycle` stanza of `aws_cloudformation_stack_set.this`:
```
lifecycle {
  precondition {
    condition     = !(var.template_body != null && var.template_url != null)
    error_message = "Only one of template_body or template_url may be set, not both."
  }
  ignore_changes = [administration_role_arn]
}
```

The existing `lifecycle { ignore_changes = [administration_role_arn] }` block is preserved regardless of which approach is chosen.

No other resource blocks (`aws_cloudformation_stack_set_instance.this`), `dynamic` blocks, or `operation_preferences` logic are modified.

## 5. Breaking-change assessment
- **Breaking: no.**
- Callers who supply only `template_body` **or** only `template_url` observe identical behavior.
- Callers who supply **both** were already getting a silently misconfigured resource (both nulled out); they will now get a clear validation error at plan time and must remove one of the two values. This is a correctness fix, not a behavioral regression.

## 6. Checkov / tfsec considerations
- **New suppressions:** none. The fix removes broken logic and adds a guard; it does not introduce any security-relevant deviations.
- **Existing suppressions affected:** none.

## 7. terraform-docs impact
Yes. The `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/cloudformation/stack_set/README.md` will be regenerated because the `validation` block added to `var.template_body` changes the variable's documented constraints. The implementer must run `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/cloudformation/stack_set` (or `pre-commit run --all-files`) and commit the result so the `Verify - terraform-docs` CI job passes.

## 8. Testing
- `tofu -chdir=modules/aws/cloudformation/stack_set init -backend=false && tofu -chdir=modules/aws/cloudformation/stack_set validate`
- `tofu fmt -check -diff -recursive modules/aws/cloudformation/stack_set`
- `checkov -d modules/aws/cloudformation/stack_set` (no new suppressions expected)
- Native `tofu test` plan — add `modules/aws/cloudformation/stack_set/tests/main.tftest.hcl` (file does not currently exist):

**`mock_provider` setup:**
```hcl
mock_provider "aws" {
  mock_resource "aws_cloudformation_stack_set" {
    defaults = {
      id   = "mock-stack-set"
      arn  = "arn:aws:cloudformation:us-east-1:123456789012:stackset/mock-stack-set:mock-id"
      name = "mock-stack-set"
    }
  }
  mock_resource "aws_cloudformation_stack_set_instance" {
    defaults = {
      id = "mock-stack-set-instance"
    }
  }
}
```

**Required `run` blocks:**

1. **`plan_succeeds_with_template_body_only`** — valid-baseline: supply `template_body` only; assert `aws_cloudformation_stack_set.this.template_body` is non-null, `template_url` is null, and outputs (`name`, `arn`, `id`) are non-null.

2. **`plan_succeeds_with_template_url_only`** — valid-baseline for the other branch: supply `template_url` only (valid HTTPS URL); assert `aws_cloudformation_stack_set.this.template_url` is non-null, `template_body` is null, and outputs are non-null.

3. **`rejects_both_template_body_and_template_url`** — `expect_failures` case for the new mutual-exclusivity validation: supply both `template_body` and `template_url`; assert `expect_failures = [var.template_body]` (or `[aws_cloudformation_stack_set.this]` if implemented as a `precondition`).

4. **`rejects_template_url_invalid_scheme`** — `expect_failures` case for the existing `var.template_url` validation (non-HTTPS URL); assert `expect_failures = [var.template_url]`.

5. **`rejects_invalid_call_as`** — `expect_failures` case for `var.call_as` validation; assert `expect_failures = [var.call_as]`.

6. **`rejects_invalid_capabilities`** — `expect_failures` case for `var.capabilities` validation; assert `expect_failures = [var.capabilities]`.

7. **`rejects_invalid_permission_model`** — `expect_failures` case for `var.permission_model` validation; assert `expect_failures = [var.permission_model]`.

8. **`rejects_invalid_region_concurrency_type`** — `expect_failures` case for `var.region_concurrency_type` validation; assert `expect_failures = [var.region_concurrency_type]`.

9. **`rejects_invalid_account_filter_type`** — `expect_failures` case for `var.account_filter_type` validation; assert `expect_failures = [var.account_filter_type]`.

10. **`auto_deployment_disabled`** — branch case for `enable_auto_deployment = false`: assert that no `auto_deployment` block attributes appear in the resource (i.e., dynamic block for `auto_deployment` produces zero instances).

11. **`managed_execution_enabled`** — branch case for `enable_managed_execution = true`: assert the `managed_execution` block is present in the planned resource.

All `run` blocks use `command = plan` and rely on `mock_provider "aws"` so they run fully offline without real credentials or a backend.

No wiring tests are required (this module does not call any child modules).

## 9. Open questions
- **Cross-variable validation availability**: Confirm that the target OpenTofu version (≥ 1.9 required for cross-variable `validation` references) is in use in CI. If not, use the `lifecycle { precondition { ... } }` approach instead and adjust the `expect_failures` target from `var.template_body` to `aws_cloudformation_stack_set.this` in the test.
- **`stack` module (#377)**: Should this PR also fix the identical bug in `modules/aws/cloudformation/stack`? The issue body suggests considering both together. Unless the maintainer directs otherwise, this implementation will stay scoped to `stack_set` only, as the spec states.

## 10. Acceptance criteria
- Providing both `template_body` and `template_url` results in a clear plan-time validation error (not silent nulling of both values).
- Providing only `template_body` causes `aws_cloudformation_stack_set.this.template_body` to be set to the supplied value and `template_url` to be null.
- Providing only `template_url` causes `aws_cloudformation_stack_set.this.template_url` to be set to the supplied value and `template_body` to be null.
- `modules/aws/cloudformation/stack_set/tests/main.tftest.hcl` is added and all `run` blocks pass via `tofu -chdir=modules/aws/cloudformation/stack_set test` (offline, using `mock_provider`).
- `tofu fmt -check -diff -recursive` passes with no formatting changes.
- `Verify - terraform-docs` CI job passes (README regenerated and committed).
