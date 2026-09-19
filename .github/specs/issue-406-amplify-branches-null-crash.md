# Spec: bug(amplify): passing branches = null crashes plan on aws_amplify_domain_association
**Issue:** #406
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix
## 1. Background
The `modules/aws/amplify` module declares `var.branches` as a required
(`type = map(object({...}))`, no `default`) but nullable variable. A caller can
therefore legally pass `branches = null`, and the two resources that key off it
handle that value inconsistently:
- `aws_amplify_branch.this` (`main.tf:142`) uses
  `for_each = var.branches != null ? var.branches : {}` — null-safe, plans with
  zero branches.
- `aws_amplify_domain_association.this` (`main.tf:175`) uses
  `for_each = var.branches` directly — OpenTofu/Terraform rejects a `null`
  `for_each` argument, so the whole plan fails with:
  ```
  Error: Invalid for_each argument
    on main.tf line 175, in resource "aws_amplify_domain_association" "this":
   175:   for_each               = var.branches
  The given "for_each" argument value is unsuitable: the given "for_each" argument value is null.
  ```
The bug was found via Copilot PR review on #385 and reproduced directly with
`tofu test` against the `branches = null` scenario. The module currently has
**no `tests/` directory**, so this fix also introduces the module's first native
test coverage per `AGENTS.md` § Module Design Specifications § 6.
## 2. Non-goals
- No change to the branch/domain-association object schema or any other
  `var.branches` attribute semantics.
- No new Amplify features, notification changes, or resource additions.
- Not fixing the latent logic issue in the nested
  `dynamic "sub_domain"` block (`main.tf:188-194`), which iterates
  `for_each = var.branches` rather than the current branch's sub_domains. That
  is a separate concern tracked outside this issue; this spec only removes the
  `null` crash, and the guarded `for_each` keeps that block from ever evaluating
  against a `null` value.
- No refactor of the SNS/EventBridge notification submodule wiring.
## 3. Affected module path(s)
- `modules/aws/amplify/` (existing) — `variables.tf`, `main.tf`
- `modules/aws/amplify/tests/` (new) — first native `tofu test` suite
- `modules/aws/amplify/README.md` (regenerated `terraform-docs` block only)
## 4. Proposed design
**Signatures only — no full implementations.**
Make `var.branches` null-safe and consistent across both consuming resources.
The recommended approach treats a `null`/omitted input as the empty map so the
module plans cleanly with zero branches and zero domain associations, matching
the existing behavior of `aws_amplify_branch.this`.
### `variables.tf`
Update the existing `branches` variable declaration (no new variables):
- `variable "branches"` — keep `type = map(object({...}))` and every existing
  attribute unchanged. Add `default = {}` and `nullable = false`. This makes the
  variable optional, converts an explicit `branches = null` into the default
  `{}` (so both resources receive a real map), and documents the empty-map
  default in the description. No `validation { ... }` block is added — the
  chosen design accepts `null` gracefully rather than rejecting it.
### `outputs.tf`
No changes. Existing outputs (`app_id`, `app_arn`, `default_domain`,
`sns_topic_arn`, `notification_event_rule_arn`) are unaffected.
### `main.tf`
- `resource "aws_amplify_domain_association" "this"` — change
  `for_each = var.branches` to a null-safe expression consistent with the
  branch resource (e.g. `for_each = var.branches != null ? var.branches : {}`).
  With `nullable = false` + `default = {}` on the variable, `var.branches` is
  already guaranteed non-null; the guarded form is retained for defense in depth
  and parity with `aws_amplify_branch.this`.
- `resource "aws_amplify_branch" "this"` — keep the existing null-safe
  `for_each` (no functional change; may be left as-is for parity).
- No changes to resource attribute wiring, `dynamic` blocks, lifecycle
  ignores, tagging (`tags = var.tags`), or the notification submodules.
## 5. Breaking-change assessment
- Breaking: **no**.
- `var.branches` moves from required to optional (`default = {}`); existing
  callers that pass a map are unaffected. Callers that previously passed
  `branches = null` (which crashed) now plan successfully with zero branches.
- Conventional Commit type `fix:` → PATCH release.
## 6. Checkov / tfsec considerations
- New suppressions: none.
- Existing suppressions affected: none.
## 7. terraform-docs impact
Yes — `modules/aws/amplify/README.md`'s `<!-- BEGIN_TF_DOCS -->` block will
change: the `branches` input row moves from "required" to "optional" and gains a
`{}` default. The implementation PR must regenerate the docs (pre-commit
`terraform_docs` hook or the per-module `terraform-docs` command) and commit the
result so the `Verify - terraform-docs` CI job passes.
## 8. Testing
- `tofu -chdir=modules/aws/amplify init -backend=false && tofu -chdir=modules/aws/amplify validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/amplify` (locally; CI runs on schedule)
- Native `tofu test` plan (required — `AGENTS.md` § Module Design Specifications
  § 6). The module has no tests today, so the implementation must add a
  `modules/aws/amplify/tests/` directory. Every `run` block uses a
  `mock_provider "aws"` (with `mock_resource` defaults for `aws_amplify_app`,
  `aws_amplify_branch`, and `aws_amplify_domain_association`) so `tofu test`
  runs offline with `command = plan`. Required cases:
  - **Valid baseline** — `run "valid_baseline_plans"` with a realistic
    `branches` map (at least one entry with `domain_name`, plus `sub_domains`)
    and `name` set. Asserts the plan succeeds and that
    `length(aws_amplify_domain_association.this) == length(var.branches)` and
    `length(aws_amplify_branch.this) == length(var.branches)`.
  - **`branches = null` regression case** — `run "branches_null_plans_with_zero_resources"`
    passing `branches = null`. This is the core fix: asserts the plan succeeds
    and that both `length(aws_amplify_branch.this) == 0` and
    `length(aws_amplify_domain_association.this) == 0` (no `Invalid for_each`
    crash).
  - **`branches` omitted / `{}` case** — `run "branches_default_empty_plans"`
    leaving `branches` unset (exercises the new `default = {}`). Asserts zero
    branch and zero domain-association instances, confirming the optional
    default.
  - **`expect_failures` per `validation { ... }` rule** — the touched
    `branches` variable adds no `validation` block, so no new `expect_failures`
    case is required for it. To satisfy § 6 coverage for the module's existing
    validations, add:
    - `run "invalid_platform_rejected"` with `platform = "INVALID"` and
      `expect_failures = [var.platform]`.
    - `run "invalid_cache_config_type_rejected"` with
      `cache_config_type = "INVALID"` and
      `expect_failures = [var.cache_config_type]`.
  - **Conditional / `for_each` branch coverage** — beyond the branch/domain
    `for_each` cases above (zero vs. non-zero), add a
    `run "notifications_enabled_creates_submodules"` with
    `enable_notifications = true` and `create_sns_topic = true` asserting
    `length(module.amplify_notifications_sns) == 1` and
    `length(module.amplify_notifications_event) == 1`, plus a default-disabled
    case asserting both are length 0 (covers the
    `count = ... ? 1 : 0` branches and the `enable_certificate` /
    `sub_domains` dynamic toggles inside the domain association).
  - **Output assertions** — assert on every meaningful output: `output.app_id`,
    `output.app_arn`, and `output.default_domain` are non-null in the baseline;
    `output.sns_topic_arn` and `output.notification_event_rule_arn` are `null`
    when notifications are disabled and non-null when enabled.
  - **Wiring assertions** — the module composes the `../sns` and
    `../cloudwatch/event` submodules. Add assertions proving the parent passes
    values through correctly (e.g. the EventBridge rule name derived from
    `var.name` feeds the SNS topic policy / event target), following the
    `modules/aws/organizations/tests/wiring.tftest.hcl` pattern.
  Do not weaken any assertion, skip a `run` block, or mock away the behavior
  under test to force a pass — every case must exercise real module behavior,
  and the `branches = null` case must fail before the fix and pass after it.
## 9. Open questions
- Design choice confirmation: this spec recommends the **null-tolerant**
  approach (`default = {}` + `nullable = false`, treating `null` as `{}`) rather
  than the **reject-with-validation** alternative the issue also allows. Both
  satisfy the acceptance criteria; reviewers should confirm the null-tolerant
  choice, which matches the existing `aws_amplify_branch.this` behavior and makes
  `branches` optional.
## 10. Acceptance criteria
- [ ] `branches = null` plans successfully with zero branches and zero domain
  associations (matching `aws_amplify_branch.this`'s existing null-safe
  behavior), with no `Invalid for_each argument` error.
- [ ] `aws_amplify_domain_association.this` no longer consumes `var.branches`
  as a bare, potentially-`null` `for_each` argument.
- [ ] `modules/aws/amplify/tests/` native `tofu test` suite is added and asserts
  the corrected `branches = null` behavior (a case that fails before the fix and
  passes after), plus the baseline, validation, conditional-branch, output, and
  wiring cases described in § 8.
- [ ] `tofu fmt`, `tofu test`, and `terraform-docs` all pass in CI (README
  regenerated and committed).
