# Spec: Fix cloudwatch/alarm action variables typed as string, not list/set(string)
**Issue:** #386
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
The `modules/aws/cloudwatch/alarm` module wraps a single
`aws_cloudwatch_metric_alarm` resource. Under AWS provider `>= 6.0.0` the
resource's `alarm_actions`, `ok_actions`, and `insufficient_data_actions`
arguments are `set(string)`, but the module declares the backing variables as
`type = string` (`variables.tf:7-10`, `variables.tf:42-45`, `variables.tf:57-60`).
As a result any value assigned to these variables is type-checked as a plain
string before it reaches the resource block, so it can never satisfy the
resource's `set of string` requirement. A single-element list at the call site
does not help: OpenTofu unifies it down to the declared `string` type before it
reaches the resource. `tofu plan`/`tofu test` therefore always fails with:
```
Error: Incorrect attribute value type
  on main.tf line 13, in resource "aws_cloudwatch_metric_alarm" "alarm":
  13:   alarm_actions             = var.alarm_actions
Inappropriate value for attribute "alarm_actions": set of string required, but have string.
```
(and the same for `insufficient_data_actions` and `ok_actions`). There is no
valid input that lets this module plan today, so the module is non-functional
for its core purpose. The three variables are also declared without defaults,
forcing every caller to supply a value even though the underlying arguments are
optional.
Separately, several variables that are semantically numeric
(`datapoints_to_alarm`, `evaluation_periods`, `period`, `threshold`) are typed
`string`. These do not currently block a plan (OpenTofu coerces numeric strings),
but tightening them improves caller-facing type safety and is in scope for this
same pass per the issue's acceptance criteria. The module currently ships no
`outputs.tf` content and no `tests/` directory; both gaps are addressed here so
the fix is verifiable and the module aligns with `AGENTS.md`.
Originating issue: #386.

## 2. Non-goals
- No change to the set of provider arguments the module exposes beyond fixing
  variable types/defaults and (optionally) adding outputs — this is a bug fix,
  not a full "complete resource coverage" rewrite of the module.
- No conversion of this single-resource module to a map/`for_each` (YAML)
  multi-instance pattern; the alarm module manages one alarm per instantiation
  and that shape is unchanged.
- No composition/submodule extraction; the module remains a single-resource
  wrapper with no calls to other modules.
- No changes to any other module, and no changes outside
  `modules/aws/cloudwatch/alarm/`.

## 3. Affected module path(s)
- `modules/aws/cloudwatch/alarm/` (existing) — `variables.tf`, `main.tf`
  (unchanged references, but re-verified), `outputs.tf` (new content),
  `README.md` (regenerated terraform-docs), and a new `tests/` directory.

## 4. Proposed design
**Signatures only — no full implementations.**
### `variables.tf`
Fix the three action variables to be collections of strings with an empty-set
default (matching the provider's optional/empty default), and add safe defaults
where the underlying argument is optional. Proposed variable signatures:
- `actions_enabled` — `bool`, "(Optional) Indicates whether actions execute during
  alarm state changes." default `true`. (Retype from `string` to `bool`.)
- `alarm_actions` — `list(string)`, "(Optional) ARNs of actions to execute when
  the alarm transitions into ALARM." default `[]`.
- `ok_actions` — `list(string)`, "(Optional) ARNs of actions to execute when the
  alarm transitions into OK." default `[]`.
- `insufficient_data_actions` — `list(string)`, "(Optional) ARNs of actions to
  execute when the alarm transitions into INSUFFICIENT_DATA." default `[]`.
- `alarm_description` — `string`, description unchanged. default `null`.
- `alarm_name` — `string` (Required), description unchanged. No default.
- `comparison_operator` — `string` (Required), description unchanged. No default.
- `datapoints_to_alarm` — `number`, "(Optional) Number of datapoints that must be
  breaching to trigger the alarm." default `null`. (Retype from `string`.)
- `dimensions` — `map(string)`, description unchanged. default `{}`. (Tighten
  from `map(any)`.)
- `evaluation_periods` — `number` (Required), description unchanged. No default.
  (Retype from `string`.)
- `metric_name` — `string` (Required), description unchanged. No default.
- `namespace` — `string` (Required), description unchanged. No default.
- `period` — `number` (Required), description unchanged. No default. (Retype
  from `string`.)
- `statistic` — `string`, description unchanged. default `null`.
- `threshold` — `number` (Required), description unchanged. default `1`.
  (Retype from `string`.)
- `treat_missing_data` — `string`, description unchanged. default `"missing"`.
- `unit` — `string`, description unchanged. default `null`.
Optional (recommended) input validation the implementation should add, each of
which drives an `expect_failures` test case in § 8:
- `comparison_operator` — `validation { ... }` restricting to the provider's
  allowed operators (`GreaterThanOrEqualToThreshold`, `GreaterThanThreshold`,
  `LessThanThreshold`, `LessThanOrEqualToThreshold`, and the anomaly-detection
  band operators).
- `treat_missing_data` — `validation { ... }` restricting to
  `missing`, `ignore`, `breaching`, `notBreaching`.
If the implementer chooses not to add a given `validation {}` block, the matching
`expect_failures` case in § 8 is dropped with it — do not ship a validation case
that has no backing rule.
### `outputs.tf`
The module currently exposes nothing. Add outputs surfacing the created alarm
so callers can wire alarms to other resources (e.g. dashboards, composed
services per `AGENTS.md` § 2):
- `arn` — the alarm's ARN (`aws_cloudwatch_metric_alarm.alarm.arn`).
- `id` — the alarm's ID/name (`aws_cloudwatch_metric_alarm.alarm.id`).
### `main.tf`
No structural change: a single `resource "aws_cloudwatch_metric_alarm" "alarm"`
block whose argument-to-variable wiring is unchanged. Once the variables are
retyped, the existing `alarm_actions = var.alarm_actions` (etc.) assignments
become type-correct. No `count`/`for_each`, no lifecycle ignores, and no tagging
block are introduced (the resource does not take a `tags` argument in the shape
this module manages; tagging convention is therefore N/A here). The
`terraform {}` block (`required_version >= 1.0.0`, `aws >= 6.0.0`) is unchanged.

## 5. Breaking-change assessment
- Breaking: yes.
- Rationale and migration:
  - `alarm_actions`, `ok_actions`, `insufficient_data_actions` change from
    `string` to `list(string)`. Because the module cannot plan today, no working
    caller can exist, so real-world blast radius is effectively nil; but the type
    signature changes, so callers must pass lists (e.g.
    `alarm_actions = ["arn:aws:sns:...:topic"]`) instead of a bare string. These
    now default to `[]`, so callers that do not need actions can omit them.
  - `actions_enabled` (`string`→`bool`), `datapoints_to_alarm`,
    `evaluation_periods`, `period`, `threshold` (`string`→`number`), and
    `dimensions` (`map(any)`→`map(string)`) tighten types. Callers passing
    numeric/boolean literals or numeric strings continue to work via coercion;
    callers passing genuinely non-numeric strings would now error (intended).
  - Adding defaults (`alarm_description`, `statistic`, `unit` → `null`;
    `datapoints_to_alarm` → `null`; `treat_missing_data` → `"missing"`) is
    backward compatible — previously-required inputs become optional.
  - Per `AGENTS.md` Release strategy, this lands as a `fix!:` / documented
    `BREAKING CHANGE:` and bumps MAJOR.

## 6. Checkov / tfsec considerations
- New suppressions: none. Retyping variables and adding outputs introduces no
  new resource behavior that would trip a Checkov/tfsec check.
- Existing suppressions affected: none (the module has no inline suppressions).

## 7. terraform-docs impact
Yes. The `<!-- BEGIN_TF_DOCS --> … <!-- END_TF_DOCS -->` block in
`modules/aws/cloudwatch/alarm/README.md` will change: the Inputs table updates
the types and defaults for the retyped variables, and a new Outputs table
(`arn`, `id`) is added. The implementation must regenerate docs
(`terraform-docs markdown table --output-file README.md --output-mode inject
modules/aws/cloudwatch/alarm` or `pre-commit run --all-files`) and commit the
result; CI's `Verify - terraform-docs` job will otherwise fail. The README usage
example should also be updated to show list-typed action inputs.

## 8. Testing
- `tofu -chdir=modules/aws/cloudwatch/alarm init -backend=false && tofu -chdir=modules/aws/cloudwatch/alarm validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/cloudwatch/alarm` (locally; CI runs on schedule)
- Native `tofu test` (required — `AGENTS.md` § 6). Add a `tests/` directory whose
  cases run fully offline via `mock_provider "aws"` with a `mock_resource
  "aws_cloudwatch_metric_alarm"` supplying `id`/`arn` defaults (mirroring
  `modules/aws/organizations/tests/organization.tftest.hcl`). Required cases:
  - **Valid baseline** (`main.tftest.hcl`, `command = plan`) — supply required
    variables plus list-typed `alarm_actions`, `ok_actions`,
    `insufficient_data_actions` (each `["arn:aws:sns:us-east-1:123456789012:test-topic"]`);
    assert the plan succeeds. This is the exact scenario the issue says fails
    today and must now pass.
  - **Output assertions** — assert `output.arn` is non-null and `output.id` is
    non-null against the mocked resource values.
  - **Empty-action default branch** — a `run` block that omits all three action
    variables and asserts the plan still succeeds (proving the new `[]` defaults
    make the actions optional). This exercises the optional-vs-required behavior
    change.
  - **Multi-element action list** — a `run` block passing two ARNs in
    `alarm_actions` and asserting the plan succeeds, proving the `set(string)`
    semantics (multiple actions per state transition) the issue calls out.
  - **Validation `expect_failures` cases** (`validation.tftest.hcl`) — one per
    `validation {}` block the implementation adds:
    - Invalid `comparison_operator` value → `expect_failures = [var.comparison_operator]`.
    - Invalid `treat_missing_data` value → `expect_failures = [var.treat_missing_data]`.
    Include the matching valid-baseline case in the same file. If a given
    `validation {}` block is not implemented, drop its `expect_failures` case
    rather than shipping a case with no backing rule.
  - There are no `count`/`for_each` conditional branches in this
    single-resource module and no submodule calls, so no per-branch or wiring
    tests apply beyond the default-vs-supplied action cases above.
  Do not weaken any assertion, delete/skip a `run` block, or mock away the
  behavior under test to force a pass. If a case fails, fix the root cause in the
  module's `.tf` files and re-run until it passes for the right reason.

## 9. Open questions
- Should the retyped collection variables be `list(string)` or `set(string)`?
  Proposed: `list(string)` (caller-friendly, ordered, and coerced to the
  resource's set) — confirm during review.
- Should the input `validation {}` blocks (§ 4) be added in this PR, or deferred?
  Proposed: add them now so type safety and validation coverage land together;
  the § 8 `expect_failures` cases assume they are present.
- Should `outputs.tf` expose additional attributes beyond `arn`/`id`? Proposed:
  `arn` and `id` only, since those are the attributes callers need for wiring.

## 10. Acceptance criteria
- `alarm_actions`, `ok_actions`, and `insufficient_data_actions` in
  `modules/aws/cloudwatch/alarm/variables.tf` are `list(string)` (or
  `set(string)`), each defaulting to `[]` rather than being required.
- `tofu -chdir=modules/aws/cloudwatch/alarm test` passes, including a baseline
  `plan` run that supplies real ARNs as lists and succeeds (the scenario that
  fails today).
- The numeric-semantic variables (`datapoints_to_alarm`, `evaluation_periods`,
  `period`, `threshold`) and `actions_enabled` are retyped to `number`/`bool`
  respectively without breaking a valid baseline plan.
- A `tests/*.tftest.hcl` suite meeting `AGENTS.md` § 6 is added and runs offline
  via `mock_provider` (`tofu init -backend=false && tofu test`, no credentials).
- `outputs.tf` exposes `arn` and `id`, asserted by the test suite.
- `tofu fmt -check -diff -recursive` is clean and the terraform-docs block in the
  module README is regenerated and committed.
- The change is committed as a breaking `fix!:` (MAJOR bump) per `AGENTS.md`.
