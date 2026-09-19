# Spec: bug(ec2_instance): unanchored regex validations accept invalid values for instance_initiated_shutdown_behavior and auto_recovery
**Issue:** #396
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/ec2_instance/variables.tf` declares two enum-style string
variables whose `validation {}` blocks use **unanchored** regexes:

- `instance_initiated_shutdown_behavior` — `can(regex("stop|terminate", ...))`
- `auto_recovery` — `can(regex("default|disabled", ...))`

Because neither pattern is anchored with `^`/`$`, `regex()` matches on
substring containment rather than a full match. Any string that merely
*contains* one of the alternatives passes — e.g. `"stop-now"`,
`"terminate-instance-now"`, and `"default-invalid"` all validate
successfully even though they are not valid enum members. The invalid
value is then passed straight to `aws_instance.ec2`, where it either
fails at apply time against the provider or, for `auto_recovery`, is not
even a real `aws_instance` argument (see § 9), defeating the purpose of
the client-side guardrail.

Every other enum validation in the same file is already correctly
anchored (`tenancy`, `root_volume_type`, `http_endpoint`, `http_tokens`,
plus the boolean `^(true|false)$` checks), so this is an isolated
inconsistency rather than a module-wide pattern.

This was found while adding native OpenTofu test coverage in #383 (flagged
by a Copilot PR review comment) and deferred because that PR was
test-authoring only.

See: https://github.com/zachreborn/terraform-modules/issues/396

## 2. Non-goals
- No changes to any other variable, its type, default, or validation.
- No changes to `main.tf`, `outputs.tf`, or resource wiring.
- No change to the set of accepted values — the valid enum members
  (`stop`/`terminate` and `default`/`disabled`) stay exactly the same;
  only invalid substring matches stop passing.
- Not auditing or "fixing" the `auto_recovery` argument's mapping onto
  `aws_instance` (whether it corresponds to a real provider argument);
  that is tracked as an open question, not part of this bug fix.
- No changes to error-message wording (the existing messages already
  describe the correct valid values).

## 3. Affected module path(s)
- `modules/aws/ec2_instance/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Two `validation {}` conditions are re-anchored to require a full match.
Variable names, types, descriptions, and defaults are unchanged:

- **`instance_initiated_shutdown_behavior`** (string, default `"stop"`)
  - `validation.condition` changes to
    `can(regex("^(stop|terminate)$", var.instance_initiated_shutdown_behavior))`
  - `error_message` unchanged (`"The value must be either stop or terminate."`)
- **`auto_recovery`** (string, default `"default"`)
  - `validation.condition` changes to
    `can(regex("^(default|disabled)$", var.auto_recovery))`
  - `error_message` unchanged (`"The value must be either default or disabled."`)

All other variables in the file remain byte-for-byte identical.

### `outputs.tf`
No changes. Existing outputs (`id`, `availability_zone`, `key_name`,
`public_dns`, `public_ip`, `primary_network_interface_id`, `private_dns`,
`private_ip`, `security_groups`, `vpc_security_group_ids`, `subnet_id`)
are unchanged.

### `main.tf`
No changes. Resource blocks (`aws_instance.ec2`,
`aws_cloudwatch_metric_alarm.instance`, `aws_cloudwatch_metric_alarm.system`)
and their `count = var.number` pattern, the `root_block_device` /
`metadata_options` blocks, the `lifecycle { ignore_changes = [ami, user_data] }`
block, and the `merge(var.tags, { Name = ... })` tagging are all unaffected.

## 5. Breaking-change assessment
- Breaking: **no** (practically).
- The change only *tightens* validation: values that were always
  invalid (e.g. `"stop-now"`, `"default-invalid"`) now fail at plan time
  instead of being forwarded to the provider. Every documented, valid
  value (`stop`, `terminate`, `default`, `disabled`) and both defaults
  continue to pass unchanged.
- Theoretical caller impact: a caller currently passing an out-of-enum
  string that happened to slip through would now get a plan-time error.
  That is the intended correction (the value was never valid), so it is
  classified as a `fix:` (PATCH) rather than a breaking change. No
  migration steps are required for correct callers.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. Tightening a variable validation introduces
  no new resource configuration and no security-relevant surface.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
**No.** The `terraform-docs` table renders variable name, type,
description, and default — none of which change. `validation {}` block
contents are not part of the generated `<!-- BEGIN_TF_DOCS -->` table, so
`modules/aws/ec2_instance/README.md` will not change. (CI's
`Verify - terraform-docs` job should still pass with no diff.)

## 8. Testing
Standard local checks:
- `tofu -chdir=modules/aws/ec2_instance init -backend=false && tofu -chdir=modules/aws/ec2_instance validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/ec2_instance` (locally; CI runs on schedule)

Native `tofu test` plan (required — `AGENTS.md` § Module Design
Specifications § 6). The `ec2_instance` module currently has **no**
`tests/` directory, so the implementation must create
`modules/aws/ec2_instance/tests/validation.tftest.hcl` following the
`mock_provider` / `run` / `expect_failures` conventions in
`modules/aws/organizations/account/tests/validation.tftest.hcl`. Because
`aws_instance` requires credentials/network to plan against a real
provider, the file must open with a `mock_provider "aws" {}` block so
`tofu test` runs fully offline.

A minimal, always-required set of `variables` (required inputs with no
default) must be supplied in each `run` block so the plan reaches
variable validation: `ami = "ami-0123456789abcdef0"`,
`instance_type = "t3.micro"`, `name = "test-ec2"`,
`vpc_security_group_ids = ["sg-0123456789abcdef0"]`.

Required `run` blocks:

- **`valid_baseline_plans_successfully`** (`command = plan`) — supply the
  required inputs plus the defaults left implicit; assert the instance is
  planned, e.g. `length(aws_instance.ec2) == var.number` (i.e. `== 1`).
  This proves normal configuration still plans.
- **`accepts_valid_shutdown_behavior_terminate`** (`command = plan`) —
  set `instance_initiated_shutdown_behavior = "terminate"`; assert the
  plan succeeds (e.g. `aws_instance.ec2[0].instance_initiated_shutdown_behavior == "terminate"`).
  Covers the non-default valid enum member.
- **`accepts_valid_auto_recovery_disabled`** (`command = plan`) — set
  `auto_recovery = "disabled"`; assert the plan succeeds. Covers the
  non-default valid enum member.
- **`rejects_shutdown_behavior_substring_match`** (`command = plan`) —
  set `instance_initiated_shutdown_behavior = "stop-now"`;
  `expect_failures = [var.instance_initiated_shutdown_behavior]`. This is
  the exact regression from the issue and must fail only because the
  regex is anchored.
- **`rejects_auto_recovery_substring_match`** (`command = plan`) — set
  `auto_recovery = "default-invalid"`;
  `expect_failures = [var.auto_recovery]`. Second regression case.

Guidance for the implementer: these `expect_failures` cases must fail
*because* the anchored regex rejects the value — do not weaken an
assertion, delete a case, or mock away the validation to force a green
run. If a case does not fail as expected, the regex anchoring in
`variables.tf` is the thing to fix, not the test. Additional
`expect_failures` cases for the module's other anchored validations
(`ami`, `tenancy`, `root_volume_type`, `http_endpoint`, `http_tokens`)
are welcome for completeness but are not required by this bug fix.

## 9. Open questions
- `auto_recovery` is validated and declared but is **not** wired into any
  resource in `main.tf` (the `aws_instance` argument for auto-recovery is
  `maintenance_options { auto_recovery = ... }`, which the module does not
  currently set). This spec only anchors the existing validation; whether
  to actually plumb `auto_recovery` into `aws_instance.ec2` is out of
  scope and should be filed as a separate issue if desired.

## 10. Acceptance criteria
- [ ] `instance_initiated_shutdown_behavior = "stop-now"` fails validation.
- [ ] `auto_recovery = "default-invalid"` fails validation.
- [ ] Existing valid values (`stop`, `terminate`, `default`, `disabled`)
      continue to pass, and the module defaults still plan.
- [ ] Both `validation.condition` regexes are anchored with `^(...)$`,
      consistent with the other enum validations in the file.
- [ ] `modules/aws/ec2_instance/tests/validation.tftest.hcl` is created
      with the `mock_provider`-backed valid-baseline and `expect_failures`
      cases described in § 8, and `tofu -chdir=modules/aws/ec2_instance test`
      passes offline.
- [ ] No changes to `main.tf`, `outputs.tf`, error messages, or any other
      variable; no new Checkov/tfsec suppressions.
- [ ] `tofu fmt -check -diff -recursive` and
      `tofu -chdir=modules/aws/ec2_instance validate` pass.
