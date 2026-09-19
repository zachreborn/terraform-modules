# Spec: bug(lambda): timeout variable description says defaults to 3 seconds but actual default is 180
**Issue:** #403
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix
## 1. Background
`modules/aws/lambda/variables.tf` declares the `timeout` variable with an
inconsistent contract:
```hcl
variable "timeout" {
  description = "(Optional) The amount of time your Lambda Function has to run in seconds. Defaults to 3. See Limits"
  default     = 180
}
```
The description advertises a default of `3` seconds (matching the AWS API's own
default when `timeout` is omitted), but the HCL `default` is actually `180`. A
caller who trusts the description — or relies on AWS's documented Lambda default
— is surprised when `tofu plan` shows `aws_lambda_function.lambda_function.timeout`
planned as `180`. The auto-generated README table (`modules/aws/lambda/README.md`
line 123) carries the same misleading "Defaults to 3" text next to a `180`
default column.
This was flagged during native-test authoring in #383 (a Copilot PR review
comment) and deferred because that PR is test-only and does not touch module
`.tf` logic.
**Chosen direction:** align the *description* to the real `180` default rather
than changing the `default` value. `180` is the intended, production-realistic
value (`3` seconds is unrealistically short for most workloads), and keeping the
default preserves behavior for every existing caller. This is a
documentation-only change to the variable's `description` string.
## 2. Non-goals
- Do **not** change the `default` value of `timeout` from `180` to `3` (that
  would be a behavior change for existing callers — see § 5).
- Do **not** add a `type` constraint or `validation { ... }` block to `timeout`,
  or otherwise refactor the variable beyond the description string.
- Do **not** touch any other variable in `variables.tf` (e.g. the missing
  `type` on `description`, `filename`, `runtime`, etc., or the commented-out
  `aws_lambda_permission` block). Those are out of scope for this bug.
- Do **not** add new inputs, outputs, or resources to the module.
- Do **not** author the `tests/main.tftest.hcl` file itself here — it is being
  introduced by #383. This spec only requires that its existing `timeout`
  assertion stay correct (see § 8).
## 3. Affected module path(s)
- `modules/aws/lambda/` (existing)
  - `modules/aws/lambda/variables.tf` — the `timeout` variable `description`.
  - `modules/aws/lambda/README.md` — the auto-generated terraform-docs table
    (regenerated, not hand-edited).
## 4. Proposed design
**Signatures only — no full implementations.**
### `variables.tf`
Only the `timeout` variable's `description` string changes; its name, absence of
`type`, and `default = 180` are unchanged.
- `timeout` — `default = 180`; description updated so the stated default agrees
  with the actual value, e.g. "(Optional) The amount of time your Lambda
  Function has to run in seconds. Defaults to 180. See Limits". No other
  attributes of the variable change.
No other variables are added, removed, or modified.
### `outputs.tf`
No changes. `arn` remains the sole output.
### `main.tf`
No changes. The `aws_lambda_function.lambda_function` resource and its
`timeout = var.timeout` wiring are untouched.
## 5. Breaking-change assessment
- Breaking: **no**.
- The only functional value (`default = 180`) is preserved, so no caller's plan
  changes. The edit is confined to a human-readable `description` string and the
  regenerated README, neither of which affects resource behavior. No migration
  is required.
## 6. Checkov / tfsec considerations
- New suppressions: none.
- Existing suppressions affected: none. A description-string change has no
  security-scan impact.
## 7. terraform-docs impact
Yes. The `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/lambda/README.md` will
change: the `timeout` row's description column currently reads "Defaults to 3"
and must be regenerated to reflect the corrected description ("Defaults to 180").
The implementer must regenerate docs (via pre-commit or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/lambda`)
and commit the result so the `Verify - terraform-docs` CI job passes.
## 8. Testing
- `tofu -chdir=modules/aws/lambda init -backend=false && tofu -chdir=modules/aws/lambda validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/lambda` (locally; CI runs on schedule)
- Native `tofu test` plan. The `modules/aws/lambda/tests/main.tftest.hcl` file is
  introduced by #383 and already covers this module's behavior with a
  `mock_provider "aws"`. This bug fix must keep that coverage correct without
  weakening any assertion:
  - **Valid-baseline case** (`plan_succeeds_with_valid_input`): must continue to
    assert `aws_lambda_function.lambda_function.timeout == 180` for the default
    case. Because the chosen direction keeps `default = 180`, this assertion
    stays green as-is; the corresponding `error_message` should read
    "timeout should default to 180." so message and assertion agree.
  - **Override case** (`overrides_are_honored`): must continue to assert that an
    explicit `timeout = 30` override is honored
    (`aws_lambda_function.lambda_function.timeout == 30`) — exercises the
    caller-supplied path independent of the default.
  - **Other default assertions** (`handler`, `memory_size`, `runtime`,
    `variables`) and the `output.arn` assertion remain unchanged.
  - Variable `validation { ... }` rules: none exist on `timeout` (and none are
    being added — see § 2), so there are no `expect_failures` cases to add for
    this fix.
  - Conditional/`count`/`for_each` branches: none in this module, so no
    branch-specific cases are required.
  - This module calls no submodules, so no wiring assertions apply.
  - If #383 has not merged when this fix lands, the implementer must ensure the
    `timeout` baseline assertion (value `180`, message "should default to 180")
    is present and passing; if #383 has merged, no test edit is needed beyond
    confirming the existing assertion still reflects `180`.
  Do not weaken, skip, or mock away any assertion to force a pass — every case
  must exercise real module behavior.
## 9. Open questions
- None. Triage and the issue both endorse aligning the description to the real
  `180` default; the maintainer direction is settled in § 1.
## 10. Acceptance criteria
- `timeout`'s `description` and `default` value are consistent with each other
  (`default = 180`; description states "Defaults to 180").
- The `default` value remains `180` (no behavior change; § 5).
- `modules/aws/lambda/README.md`'s terraform-docs block is regenerated so the
  `timeout` row description matches the corrected text.
- `modules/aws/lambda/tests/main.tftest.hcl`'s baseline default assertion for
  `timeout` continues to match the settled `180` default and passes under
  `tofu test`.
- `tofu fmt -check -diff -recursive` and the `Verify - terraform-docs` CI job
  pass on the implementation PR.
