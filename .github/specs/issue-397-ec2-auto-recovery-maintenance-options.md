# Spec: bug(ec2_instance): auto_recovery variable is declared and validated but never applied to the aws_instance resource
**Issue:** #397
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/ec2_instance/variables.tf` declares an `auto_recovery` input
variable (lines 24-32) with a description, a default of `"default"`, and a
`validation {}` block that restricts the value to `default` or `disabled`.
However, `main.tf`'s `aws_instance.ec2` resource never references
`var.auto_recovery`; the instance has no `maintenance_options {}` block at all.
As a result, setting `auto_recovery` to any value — including the documented
`"disabled"` — has zero effect on the planned infrastructure. The variable is
validated and documented but silently discarded, so callers who set it do not
get the AWS Auto Recovery from User Space (ARU) behavior they expect, with no
error or warning.

The fix is to wire `var.auto_recovery` into the resource via a
`maintenance_options { auto_recovery = var.auto_recovery }` block, so the
already-declared, already-validated input actually drives the plan.

See: https://github.com/zachreborn/terraform-modules/issues/397

This was found while adding native OpenTofu test coverage in #383 (flagged by a
Copilot PR review comment) and deferred from that test-only PR because the fix
touches module `.tf` logic.

## 2. Non-goals
- Changing the `auto_recovery` variable's name, type, default (`"default"`),
  description, or `validation {}` block — all remain as-is.
- Adding, removing, or reworking any other `aws_instance` argument or block
  (`metadata_options`, `root_block_device`, the CloudWatch alarm resources,
  lifecycle ignores, tagging, etc.).
- Introducing any new input variables or outputs.
- Refactoring the `count = var.number` multi-instance pattern.

## 3. Affected module path(s)
- `modules/aws/ec2_instance/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes. The existing `auto_recovery` variable is reused verbatim:

- `auto_recovery` (string, default `"default"`, validation: value must match
  `default|disabled`).

### `outputs.tf`
No changes. No new outputs are required; the acceptance criteria assert on the
planned resource attribute directly in native tests.

### `main.tf`
Add a single nested block to the existing `aws_instance.ec2` resource
(no new top-level resources, data sources, or locals):

- `maintenance_options {}` block on `aws_instance.ec2` with a single argument:
  - `auto_recovery = var.auto_recovery`

No changes to the `count = var.number` pattern, the `lifecycle` ignore list,
tagging, or any other block. The default value `"default"` preserves existing
behavior for callers who do not override it (AWS treats `"default"` as the
account/instance default, so no diff is introduced for unmodified callers).

## 5. Breaking-change assessment
- Breaking: **no**
- Adding `maintenance_options.auto_recovery = var.auto_recovery` with the
  existing default of `"default"` is additive and matches AWS's own default,
  so existing plans for callers who do not set `auto_recovery` remain
  unchanged. Callers who previously set `auto_recovery = "disabled"` (expecting
  it to work) will now correctly see ARU disabled — this is the intended bug
  fix, not a breaking change to a previously functioning contract.

## 6. Checkov / tfsec considerations
- New suppressions: **none** — `maintenance_options.auto_recovery` is not a
  security-relevant attribute and introduces no findings.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
No change to the `<!-- BEGIN_TF_DOCS -->` block. The `auto_recovery` variable is
already declared in `variables.tf`, so it already appears in the generated
Inputs table; wiring it into `main.tf` does not alter the documented inputs or
outputs. No new variables or outputs are added.

## 8. Testing
- `tofu -chdir=modules/aws/ec2_instance init -backend=false && tofu -chdir=modules/aws/ec2_instance validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/ec2_instance` (locally; CI runs on schedule)
- Native `tofu test` plan (required — see `AGENTS.md` § Module Design
  Specifications § 6, Native Test Coverage). The implementation must add or
  extend `modules/aws/ec2_instance/tests/` (created alongside #383) with a
  `mock_provider "aws"` block that mocks `aws_instance` and both
  `aws_cloudwatch_metric_alarm` resources, running offline via
  `tofu init -backend=false && tofu test`. Because the resource uses
  `count = var.number`, assertions index the instance as `aws_instance.ec2[0]`
  and the block as `aws_instance.ec2[0].maintenance_options[0].auto_recovery`.
  Required `run` cases:
  - **Valid-baseline (`command = plan`)**: minimal valid inputs (`ami`,
    `instance_type`, `name`, `vpc_security_group_ids`) with `auto_recovery`
    left at its default. Assert
    `aws_instance.ec2[0].maintenance_options[0].auto_recovery == "default"`,
    proving the default flows through to the plan.
  - **Override case (`command = plan`)**: same inputs plus
    `auto_recovery = "disabled"`. Assert
    `aws_instance.ec2[0].maintenance_options[0].auto_recovery == "disabled"`,
    proving the input actually affects the plan (this is the core regression
    guard for this bug).
  - **Validation failure case (`command = plan`, `expect_failures = [var.auto_recovery]`)**:
    an invalid value such as `auto_recovery = "invalid"`, exercising the
    existing `validation {}` rule on the variable.
  - No new conditional/`count`/`for_each` branch is introduced by this fix, so
    no additional branch cases are required beyond those above. This is not a
    wrapper/composition module, so no submodule wiring assertions apply.
  Do not weaken any assertion, skip a case, or mock away the
  `maintenance_options` behavior to force a pass — each case must exercise the
  real planned attribute. If a case fails, fix the root cause in `main.tf`.

## 9. Open questions
- None. The fix is a single, self-contained nested block. Whether the
  `tests/` directory already exists (from #383) or must be created is an
  implementation detail; the required cases above must be present either way.

## 10. Acceptance criteria
- [ ] `aws_instance.ec2` in `modules/aws/ec2_instance/main.tf` declares a
      `maintenance_options {}` block with `auto_recovery = var.auto_recovery`.
- [ ] `aws_instance.ec2` plans a `maintenance_options.auto_recovery` value equal
      to `var.auto_recovery` (default `"default"`, overridable to `"disabled"`).
- [ ] Native test coverage (`modules/aws/ec2_instance/tests/`) includes
      default and override assertions proving the input affects the plan
      (e.g. `aws_instance.ec2[0].maintenance_options[0].auto_recovery == "disabled"`
      when overridden), plus an `expect_failures` case for the variable's
      existing `validation {}` rule.
- [ ] No new input variables or outputs are added; the `auto_recovery` variable
      is unchanged.
- [ ] No breaking change — callers who do not set `auto_recovery` see no plan
      diff.
- [ ] `tofu fmt -recursive` and `tofu validate` pass; `tofu test` passes offline.
