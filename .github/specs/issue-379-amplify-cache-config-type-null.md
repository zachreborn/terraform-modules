# Spec: bug(amplify): cache_config_type validation rejects null, making the documented "disable cache_config" path unreachable
**Issue:** #379
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/amplify/main.tf` gates the `cache_config` block on the value of
`var.cache_config_type`:

```hcl
dynamic "cache_config" {
  for_each = var.cache_config_type != null ? [true] : []
  content {
    type = var.cache_config_type
  }
}
```

The `for_each` condition (`var.cache_config_type != null`) explicitly supports
passing `null` to omit the `cache_config` block entirely. However, the
variable's `validation` block in `variables.tf` (lines 55-58) only accepts the
two literal strings and does not permit `null`:

```hcl
validation {
  condition     = var.cache_config_type == "AMPLIFY_MANAGED" || var.cache_config_type == "AMPLIFY_MANAGED_NO_COOKIES"
  error_message = "Cache config type must be either AMPLIFY_MANAGED or AMPLIFY_MANAGED_NO_COOKIES."
}
```

The variable is nullable (no `nullable = false`), so a caller can supply
`cache_config_type = null`, but variable validation then runs before `main.tf`
evaluates the dynamic block and fails with the error above. The "disable
`cache_config` by passing `null`" code path is therefore unreachable.

This spec covers widening the validation condition to also accept `null`, so the
documented behaviour in `main.tf` becomes reachable. It also covers adding the
module's missing native `tofu test` coverage (the `tests/` directory does not
yet exist), per `AGENTS.md` § Module Design Specifications § 6.

See: https://github.com/zachreborn/terraform-modules/issues/379

## 2. Non-goals
- No change to the default value of `cache_config_type` (stays `"AMPLIFY_MANAGED"`).
- No change to the `main.tf` dynamic `cache_config` block; its `for_each`
  condition already handles `null` correctly.
- No change to the two valid string values or their meaning.
- No change to any other variable, output, resource, or submodule wiring
  (`sns`, `cloudwatch/event`) in the amplify module.
- Not adding `nullable = false` to any variable.

## 3. Affected module path(s)
- `modules/aws/amplify/` (existing)
  - `variables.tf` — widen the `cache_config_type` validation condition.
  - `tests/main.tftest.hcl` — new native test file (directory does not exist yet).
  - `README.md` — `terraform-docs` block may refresh (see § 7).

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Modify only the `cache_config_type` variable's `validation` block. Signature is
otherwise unchanged:

- **`cache_config_type`**
  - type: `string`
  - default: `"AMPLIFY_MANAGED"`
  - description: unchanged.
  - validation condition: widen to allow `null` in addition to the two existing
    literals, e.g. `var.cache_config_type == null || var.cache_config_type == "AMPLIFY_MANAGED" || var.cache_config_type == "AMPLIFY_MANAGED_NO_COOKIES"`.
  - error message: update to note that `null` is also permitted (disables the
    `cache_config` block).

No other variables change.

### `outputs.tf`
No changes. Existing outputs (`app_id`, `app_arn`, `default_domain`,
`sns_topic_arn`, `notification_event_rule_arn`) remain as-is.

### `main.tf`
No changes. The `dynamic "cache_config"` block in `aws_amplify_app.this`
already omits the block when `var.cache_config_type` is `null`. No new
resources, data sources, locals, `count`/`for_each` patterns, lifecycle rules,
or tagging changes are required.

## 5. Breaking-change assessment
- Breaking: **no**
- The change only widens the accepted input domain (adds `null` as a valid
  value). All previously valid inputs (`"AMPLIFY_MANAGED"`,
  `"AMPLIFY_MANAGED_NO_COOKIES"`, and the default) remain valid and behave
  identically. Callers already passing a string are unaffected; callers who want
  to disable `cache_config` can now pass `null` as the code always intended.

## 6. Checkov / tfsec considerations
- New suppressions: **none** — loosening a variable `validation` condition does
  not introduce any security-relevant resource configuration.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
Minimal. The variable name, type, and default do not change, so the Inputs table
is unaffected. If the variable `description` string is edited as part of the
error-message wording clarification, the `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/amplify/README.md` will refresh accordingly. Regenerate docs
locally (pre-commit or `terraform-docs markdown table --output-file README.md
--output-mode inject modules/aws/amplify`) and commit the result; CI verifies
but does not auto-commit. If the description is left unchanged, no README change
is expected.

## 8. Testing
- `tofu -chdir=modules/aws/amplify init -backend=false && tofu -chdir=modules/aws/amplify validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/amplify` (locally; CI runs on schedule)
- Native `tofu test` plan (required — see `AGENTS.md` § Module Design
  Specifications § 6). The module currently ships **no** `tests/` directory, so
  the implementation must create `modules/aws/amplify/tests/main.tftest.hcl`
  (following the `mock_provider` / `run` / `expect_failures` conventions in
  `modules/aws/organizations/tests/` and
  `modules/aws/organizations/account/tests/validation.tftest.hcl`). All cases
  must run offline via `mock_provider "aws" {}` (plus `mock_resource` defaults as
  needed) so `tofu init -backend=false && tofu test` needs no credentials.

  Required `run` blocks:
  - **Valid baseline** — `command = plan` with minimal required inputs
    (`name`, `branches = {}`), relying on the `cache_config_type` default.
    Assert the app is planned (e.g. `length(...) == 1` on `aws_amplify_app.this`)
    and that the `cache_config` block is present (one entry) because the default
    is a non-null string.
  - **`cache_config_type = null` succeeds and omits the block** (the fix under
    test) — `command = plan` with `cache_config_type = null`. Assert the plan
    succeeds and that `aws_amplify_app.this` has **zero** `cache_config` blocks.
    This case must plan successfully (NOT `expect_failures`) once the validation
    is widened.
  - **`cache_config_type = "AMPLIFY_MANAGED_NO_COOKIES"` succeeds** — proves the
    second valid literal still passes and produces one `cache_config` block.
  - **`expect_failures` for the `cache_config_type` validation rule** — pass an
    invalid string (e.g. `"INVALID"`) with `expect_failures = [var.cache_config_type]`,
    proving the rule still rejects values outside the allowed set.
  - **`expect_failures` for the `platform` validation rule** — pass an invalid
    `platform` value with `expect_failures = [var.platform]` (the module's other
    `validation` rule).
  - **Conditional-branch coverage** for the module's `count`/`for_each` toggles:
    - `cache_config` dynamic block: covered by the null vs. non-null cases above
      (both sides of `var.cache_config_type != null`).
    - `branches` `for_each` (aws_amplify_branch / aws_amplify_domain_association):
      one case with `branches = {}` (baseline, zero branches) and one case with a
      populated `branches` map asserting the expected branch/domain-association
      counts.
    - `auto_branch_creation_config` dynamic block: one case with the object set
      (block present) and coverage of the default `null` (block absent).
    - `custom_rules` dynamic block: one case with a non-empty list (rules
      present) and default `null` (absent).
    - Notifications (`enable_notifications`, `create_sns_topic`): one case with
      `enable_notifications = false` (no `amplify_notifications_sns` /
      `amplify_notifications_event` submodules) and one with
      `enable_notifications = true, create_sns_topic = true` (both submodules
      instantiated).
  - **Output assertions** — assert on every meaningful output: `app_id`,
    `app_arn`, `default_domain` (non-null when the app is planned); `sns_topic_arn`
    and `notification_event_rule_arn` are `null` when notifications are disabled
    and non-null when `enable_notifications = true`.
  - **Wiring assertions** (amplify is a composition module per `AGENTS.md` § 2) —
    when `enable_notifications = true` and `create_sns_topic = true`, assert the
    values passed into the `sns` and `cloudwatch/event` child modules connect
    correctly (e.g. the notification rule name/topic policy wiring), mirroring
    the pattern in `modules/aws/organizations/tests/wiring.tftest.hcl`.

  Do not weaken any assertion, delete a `run` block, or convert the
  `cache_config_type = null` case to `expect_failures` to force a pass. Each case
  must exercise real module behaviour; the null case in particular must
  demonstrate a successful plan with no `cache_config` block.

## 9. Open questions
- Should the `cache_config_type` `description` be updated to document that `null`
  disables the `cache_config` block? Recommended for clarity, but optional; it
  is the only reason the `terraform-docs` block would change (§ 7).

## 10. Acceptance criteria
- [ ] `cache_config_type = null` plans successfully and produces no
      `cache_config` block on `aws_amplify_app`.
- [ ] The `validation` block's condition is updated to allow `null` alongside
      the two valid string values (e.g.
      `var.cache_config_type == null || var.cache_config_type == "AMPLIFY_MANAGED" || var.cache_config_type == "AMPLIFY_MANAGED_NO_COOKIES"`).
- [ ] `modules/aws/amplify/tests/main.tftest.hcl` is created and asserts the
      corrected (non-buggy) behaviour, including a successful-plan case for
      `cache_config_type = null` and an `expect_failures` case for an invalid
      string.
- [ ] No breaking changes — previously valid string inputs remain valid.
- [ ] `tofu fmt -recursive` and `tofu -chdir=modules/aws/amplify validate` pass,
      and `tofu -chdir=modules/aws/amplify test` passes offline.
- [ ] `terraform-docs` output for `modules/aws/amplify/README.md` is regenerated
      and committed if the variable description is edited.
