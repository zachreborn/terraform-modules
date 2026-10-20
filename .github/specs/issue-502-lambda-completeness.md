# Spec: feat: modules/aws/lambda completeness (tags, vpc_config, more outputs, optional defaults)
**Issue:** #502
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
`modules/aws/lambda` is one of the oldest modules in the library and has drifted
well behind `AGENTS.md` § Module Design Specifications § 1 (Complete Resource
Coverage). The whole module is 24 lines of resource configuration
(`modules/aws/lambda/main.tf (11-24)`) and exposes a single output
(`modules/aws/lambda/outputs.tf:1`):

```hcl
resource "aws_lambda_function" "lambda_function" {
  description = var.description
  environment { variables = var.variables }
  filename         = var.filename
  function_name    = var.function_name
  handler          = var.handler
  memory_size      = var.memory_size
  role             = var.role
  runtime          = var.runtime
  source_code_hash = var.source_code_hash
  timeout          = var.timeout
}
```

Concrete gaps this spec closes, all surfaced while wiring the module into a
scheduled Lambda deployment (see the issue for the originating use case):

- **No `tags`.** Every sibling AWS module in this library takes a `tags` map and
  merges a `Name` key (`tags = merge(tomap({ Name = var.name }), var.tags)` —
  e.g. `modules/aws/ecs/capacity_provider/main.tf:37`). `aws_lambda_function`
  supports `tags`, but callers of this module have no way to set them.
- **No `vpc_config`.** Any function that must reach private resources (the
  originating app needs Active Directory over Direct Connect/VPN) cannot be
  attached to a VPC through this module at all.
- **No `reserved_concurrent_executions`, `dead_letter_config`, or
  `tracing_config`.** All three are standard `aws_lambda_function` arguments
  with no equivalent input. Notably, the repo-root `.checkov.yaml` already
  documents these as caller-configurable by name
  (`.checkov.yaml (94-100)`: `CKV_AWS_50` "exposed as tracing_config variable",
  `CKV_AWS_115` "exposed as reserved_concurrent_executions variable",
  `CKV_AWS_116` "exposed as dead_letter_config variable"), so the suppression
  rationale currently describes variables that do not exist. This spec makes the
  code match that documented intent.
- **`outputs.tf` exposes only `arn`** (and with no `description`, so the
  terraform-docs Outputs row reads `n/a` — `modules/aws/lambda/README.md:130`).
  Callers wiring API Gateway integrations, `aws_lambda_permission` statements,
  aliases, or event-source mappings need `function_name`, `invoke_arn`,
  `qualified_arn`, `version`, and `last_modified`.
- **`description`, `filename`, and `source_code_hash` are labelled "(Optional)"
  in their descriptions but have no `default`**
  (`modules/aws/lambda/variables.tf (1-14)`), making them required in practice:
  omitting any of them fails with `No value for required variable` rather than
  falling through to the provider's optional behaviour. The generated README
  confirms the mismatch — all three render `Required: yes` next to an
  "(Optional)" description (`modules/aws/lambda/README.md (115-122)`).

See: https://github.com/zachreborn/terraform-modules/issues/502

## 2. Non-goals
- **No change to the `runtime` default.** `python3.6` is deprecated and is
  tracked separately as #402; deliberately untouched here so the two changes
  stay independently reviewable.
- **No change to the `timeout` default or description.** Handled by #403
  (closed) — this spec does not revisit it.
- **No full § 1 coverage sweep of `aws_lambda_function`.** The resource also
  supports `architectures`, `code_signing_config_arn`, `ephemeral_storage`,
  `file_system_config`, `image_config`/`image_uri`/`package_type`, `kms_key_arn`,
  `layers`, `logging_config`, `publish`, `replace_security_groups_on_destroy`,
  `replacement_security_group_ids`, `s3_bucket`/`s3_key`/`s3_object_version`,
  `skip_destroy`, `snap_start`, and `timeouts`. This spec implements exactly the
  set enumerated in the issue; the remainder should be filed as a follow-up
  "complete `aws_lambda_function` coverage" issue (see § 9).
- **No S3/container deployment-package support.** Making `filename` and
  `source_code_hash` optional is in scope; adding `s3_bucket`/`s3_key`/
  `s3_object_version`/`image_uri` is not (see § 9 — this is the one place the
  issue's acceptance criteria and its proposed-input list diverge).
- **No `environment` block rework.** The block stays unconditional with its
  existing `variables` default of `{ lambda = "true" }`. Making it dynamic (so
  a function can have no environment variables) or changing that default is a
  behaviour change for existing callers and belongs in its own issue.
- **No un-commenting of the `aws_lambda_permission` block**
  (`modules/aws/lambda/main.tf (26-33)`) or its commented-out variables
  (`modules/aws/lambda/variables.tf (58-75)`). Per `AGENTS.md` § 2 (Module
  Composition) a permission resource belongs in its own module; the dead code
  stays as-is here.
- **No map/`for_each` multi-function input** (`AGENTS.md` § 5). This module
  manages a single function and keeps that shape.
- **No new module and no changes to any other module** or to `global/`.

## 3. Affected module path(s)
- `modules/aws/lambda/` (existing)
  - `modules/aws/lambda/variables.tf` — five new variables, three default
    additions, new `validation` blocks.
  - `modules/aws/lambda/main.tf` — `tags`, three `dynamic` blocks, one scalar
    argument, `required_version` bump.
  - `modules/aws/lambda/outputs.tf` — six new outputs plus descriptions.
  - `modules/aws/lambda/tests/` — extended `main.tftest.hcl` plus two new test
    files (§ 8).
  - `modules/aws/lambda/README.md` — usage example refresh + regenerated
    terraform-docs block.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Existing variables keep their current names, types, and defaults except where
noted. New/changed declarations:

Changed (add `default = null` only — types and descriptions otherwise unchanged,
beyond a clarifying sentence noted below):

- `description` — `string`, **`default = null`**. Description clarified to state
  that the provider omits the field when unset.
- `filename` — `string`, **`default = null`**. Description clarified to state
  that a function created without a local package source requires an alternative
  source configured outside this module today (see § 9).
- `source_code_hash` — `string`, **`default = null`**.

New:

- `tags` — `map(string)`, `default = {}`. "(Optional) A map of tags to assign to
  the Lambda function. A `Name` tag is merged automatically from
  `function_name`; a caller-supplied `Name` wins." `{}` is the dominant default
  across the library (51 modules vs. 22 using `{ terraform = "true" }`) and is
  what the newest modules (e.g. `modules/aws/ecs/service`) use.
- `vpc_config` — `default = null`, type:
  ```hcl
  object({
    subnet_ids                  = list(string)
    security_group_ids          = list(string)
    ipv6_allowed_for_dual_stack = optional(bool)
  })
  ```
  "(Optional) VPC configuration attaching the function to a VPC. When omitted,
  the function runs outside any VPC." Two `validation` blocks:
  - `subnet_ids` must contain at least one entry when `vpc_config` is set.
  - `security_group_ids` must contain at least one entry when `vpc_config` is
    set.
  Both conditions must be null-safe (`var.vpc_config == null ? true : …`) so the
  omitted branch passes. `ipv6_allowed_for_dual_stack` left unset defers to the
  provider's own default.
- `reserved_concurrent_executions` — `number`, `default = null`. "(Optional)
  Amount of reserved concurrent executions for this function. `0` disables the
  function (throttles all invocations); omit (or `null`) to leave the function
  unreserved, which is the provider's own default." One `validation`: value is
  `null` or `>= -1`.
- `dead_letter_config` — `object({ target_arn = string })`, `default = null`.
  "(Optional) Dead-letter queue configuration. `target_arn` must be an SQS queue
  or SNS topic ARN, and the function's execution role must be granted
  `sqs:SendMessage` / `sns:Publish` on it (not managed by this module)." One
  `validation`: when set, `target_arn` matches an anchored ARN pattern for the
  two services AWS accepts, e.g. `^arn:[a-z0-9-]+:(sqs|sns):`. Anchor the regex
  so substring matches do not pass (same defect class as #396).
- `tracing_config` — `object({ mode = string })`, `default = null`. "(Optional)
  AWS X-Ray tracing mode." One `validation`: when set, `mode` is exactly
  `Active` or `PassThrough` (case-sensitive, the values AWS accepts).

Design notes the implementation must honour:

- Every `validation.condition` references only its own variable, so no
  cross-variable references are introduced (which would require >= 1.9).
- Validations must be null-safe for the `default = null` branch, and must not
  use `try()`/`can()` in a way that silently swallows a genuinely invalid value.
- No new `validation` blocks on `description`, `filename`, or
  `source_code_hash` — relaxing them to `null` must not add a new rejection.

### `outputs.tf`
Existing:

- `arn` — unchanged value (`aws_lambda_function.lambda_function.arn`); gains a
  `description` so the generated Outputs table no longer renders `n/a`.

New (each with a `description`):

- `function_name` — the function's unique name.
- `invoke_arn` — ARN to be used in `aws_api_gateway_integration`'s `uri` /
  `aws_lambda_permission`.
- `qualified_arn` — ARN identifying the function's published version
  (`<arn>:<version>`).
- `version` — latest published version of the function.
- `last_modified` — date the function was last modified.
- `tags_all` — the merged module/provider-default tag map, matching the
  convention already used by `modules/aws/managed_prefix_list/outputs.tf`,
  `modules/aws/budgets/outputs.tf`, and others.

### `main.tf`
One resource, `aws_lambda_function.lambda_function`, keeps its current
arguments. Additions:

- `tags = merge(tomap({ Name = var.function_name }), var.tags)` — the repo's
  standard tagging pattern (`AGENTS.md` § Code Conventions), with
  `function_name` as the `Name` source since this module has no `name` variable.
- `reserved_concurrent_executions = var.reserved_concurrent_executions` — plain
  passthrough; `null` yields the provider's unreserved default.
- `dynamic "vpc_config"` — `for_each = var.vpc_config == null ? [] : [var.vpc_config]`,
  setting `subnet_ids`, `security_group_ids`, and
  `ipv6_allowed_for_dual_stack`.
- `dynamic "dead_letter_config"` — same null-gated `for_each` pattern, setting
  `target_arn`.
- `dynamic "tracing_config"` — same null-gated `for_each` pattern, setting
  `mode`.

No `count`/`for_each` on the resource itself, no `lifecycle` block, and no
`moved` blocks (nothing is renamed). The `environment` block and the
commented-out `aws_lambda_permission` block are untouched.

`terraform {}` block:

- `required_version` `">= 1.0.0"` → `">= 1.3.0"`, with a one-line comment giving
  the reason per `AGENTS.md` § 7: the `vpc_config` object type uses an
  `optional()` attribute, which requires 1.3.0.
- `aws` provider constraint stays `">= 6.0.0"`. Every argument used here
  (`tags`, `vpc_config` incl. `ipv6_allowed_for_dual_stack`,
  `dead_letter_config`, `tracing_config`, `reserved_concurrent_executions`) and
  every attribute read (`invoke_arn`, `qualified_arn`, `version`,
  `last_modified`, `tags_all`) predates the 6.0.0 floor, so no bump is
  warranted — and per § 7 the floor must not be raised "to be safe".

### `README.md`
Outside the generated block, the hand-written **Usage** example
(`modules/aws/lambda/README.md (65-79)`) is refreshed to:

- drop the legacy `"${…}"` interpolation wrapping and the deprecated
  `base64sha256(file(…))` form in favour of current HCL,
- show `tags`, and
- add a second, VPC-attached example demonstrating `vpc_config`,
  `dead_letter_config`, `tracing_config`, and
  `reserved_concurrent_executions`, with a note that the execution role needs
  `AWSLambdaVPCAccessExecutionRole`-equivalent ENI permissions (created by the
  caller via `modules/aws/iam/role`, not by this module).

A short note records which inputs are genuinely optional now, satisfying the
issue's last acceptance criterion.

## 5. Breaking-change assessment
- Breaking: **no**. Conventional Commit type `feat:` → MINOR.
- Every new variable is optional with a default that reproduces today's
  behaviour: `vpc_config`, `dead_letter_config`, `tracing_config`, and
  `reserved_concurrent_executions` all default to `null`, so their `dynamic`
  blocks render zero blocks and the resource plans exactly as it does now.
- Adding `default = null` to `description`, `filename`, and `source_code_hash`
  strictly relaxes the input contract. Callers already passing them are
  unaffected; callers omitting them stop getting a "No value for required
  variable" error.
- New outputs are additive and cannot break a caller.
- **One caller-visible diff worth flagging in review:** the new
  `tags = merge(tomap({ Name = var.function_name }), var.tags)` means existing
  callers, who cannot set tags today, will see a single in-place tag addition
  (`Name = <function_name>`) on their next `apply`. That is an in-place update,
  not a replacement, and it matches the tagging convention every other module in
  the library already applies. A caller who wants no `Name` tag cannot opt out;
  the escape hatch is to set `tags = { Name = "…" }` to choose the value. This
  is the intended convention, documented in the variable description and the
  README.
- The `required_version` bump `>= 1.0.0` → `>= 1.3.0` only affects callers on
  Terraform 1.0–1.2. Every OpenTofu release (1.6+) already satisfies it.

## 6. Checkov / tfsec considerations
- New suppressions: **none.** The repo-root `.checkov.yaml` already skips every
  Lambda check this change touches — `CKV_AWS_50` (X-Ray tracing),
  `CKV_AWS_115` (concurrency limit), `CKV_AWS_116` (DLQ), `CKV_AWS_117` (VPC
  config), `CKV_AWS_173` (env-var KMS encryption), and `CKV_AWS_272` (code
  signing) at `.checkov.yaml (94-100)`. This work makes three of those
  rationales accurate rather than aspirational.
- Existing suppressions affected: **none removed or edited.** The module carries
  no inline `#tfsec:ignore:` or `#checkov:skip=` comments today and needs none:
  each newly exposed control is caller-configurable, which is exactly the
  situation the repo-level skips cover (`AGENTS.md` § Security Posture
  Philosophy).
- The `.checkov.yaml` comments for `CKV_AWS_173` and `CKV_AWS_272` reference
  `kms_key_arn` and `code_signing_config_arn` variables that this spec does not
  add (see § 2 and § 9). No change to those lines is proposed here; the
  follow-up coverage issue should either add the variables or correct the
  comments.
- Defaults remain provider-default (`null`) rather than opinionated-on
  (`AGENTS.md` § 3): X-Ray tracing, a DLQ, and VPC placement all have cost or
  connectivity consequences and, unlike encryption or public-access blocking,
  cannot be enabled safely without caller-supplied ARNs/subnets. Making them
  *expressible* is the security win here.

## 7. terraform-docs impact
**Yes** — `modules/aws/lambda/README.md`'s `<!-- BEGIN_TF_DOCS -->` block
changes in four places:

- **Requirements** — the `terraform` row moves from `>= 1.0.0` to `>= 1.3.0`.
- **Inputs** — five new rows (`tags`, `vpc_config`,
  `reserved_concurrent_executions`, `dead_letter_config`, `tracing_config`), and
  the `description`, `filename`, and `source_code_hash` rows flip from
  `Required: yes` / `Default: n/a` to `Required: no` / `Default: null`.
  (`validation {}` block contents are not rendered.)
- **Outputs** — six new rows, and the existing `arn` row's description changes
  from `n/a` to real text.
- The hand-written Usage section above the markers also changes, but that is
  outside the generated block.

The implementer must regenerate and commit the block (`pre-commit run --all-files`,
or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/lambda`);
the `Verify - terraform-docs` CI job fails on any diff and does not auto-commit.

## 8. Testing
Standard local checks:

- `tofu -chdir=modules/aws/lambda init -backend=false && tofu -chdir=modules/aws/lambda validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/lambda` (locally; CI runs on schedule)

Native `tofu test` plan (required — `AGENTS.md` § Module Design Specifications
§ 6). All cases use `mock_provider "aws"` with a `mock_resource "aws_lambda_function"`
supplying defaults for the computed attributes the outputs read (`arn`,
`invoke_arn`, `qualified_arn`, `version`, `last_modified`, `tags_all`), follow
the `mock_provider` / `run` / `expect_failures` conventions in
`modules/aws/lambda/tests/main.tftest.hcl` and
`modules/aws/organizations/account/tests/validation.tftest.hcl`, use
`command = plan`, and must run fully offline. This is a single-resource module,
not a wrapper, so **no submodule wiring tests apply.**

### `modules/aws/lambda/tests/main.tftest.hcl` (extend)
Existing cases stay and must keep passing:

- **`plan_succeeds_with_valid_input`** — the valid baseline. Its `runtime ==
  "python3.6"` and `timeout == 180` assertions, and their explanatory comments
  referencing #402/#403, are unchanged by this spec.
- **`overrides_are_honored`** — unchanged.

New cases:

- **`omitting_optional_package_inputs_plans_successfully`** — supplies only
  `function_name` and `role`; asserts the plan succeeds and that
  `description`, `filename`, and `source_code_hash` are `null` on the planned
  resource. This is the direct regression test for the "no value for required
  variable" gap.
  *Implementer note:* if the provider rejects this plan because no deployment
  package source is configured at all, that is a real coverage gap (the module
  has no `s3_bucket`/`image_uri` input — § 9), not a reason to weaken or delete
  the case; raise it in review so the missing inputs can be pulled into scope.
- **`tags_default_to_name_only`** — omits `tags`; asserts
  `aws_lambda_function.lambda_function.tags` has exactly one entry and that
  `tags["Name"]` equals the supplied `function_name`.
- **`tags_merge_with_name`** — `tags = { Environment = "test", Team = "platform" }`;
  asserts `tags["Name"] == <function_name>` **and** both caller tags land
  unchanged.
- **`caller_supplied_name_tag_wins`** — `tags = { Name = "custom-name" }`;
  asserts `tags["Name"] == "custom-name"`, pinning the documented
  `merge(tomap({Name = …}), var.tags)` precedence.
- **`outputs_expose_function_attributes`** — asserts every output against its
  mocked value: `output.arn`, `output.invoke_arn`, `output.qualified_arn`,
  `output.version`, `output.last_modified`, and `output.tags_all`; and asserts
  `output.function_name` equals the `function_name` input (it is an argument,
  not a mocked computed attribute, so this one tests real wiring).

### `modules/aws/lambda/tests/optional_blocks.tftest.hcl` (new)
One `run` block per side of each new conditional, as required by § 6:

- **`vpc_config_omitted_creates_no_vpc_block`** — asserts
  `length(aws_lambda_function.lambda_function.vpc_config) == 0`.
- **`vpc_config_attaches_subnets_and_security_groups`** — two subnet IDs and one
  security group ID; asserts `vpc_config[0].subnet_ids` and
  `vpc_config[0].security_group_ids` contain exactly the supplied values.
- **`vpc_config_ipv6_allowed_for_dual_stack_enabled`** — the same input plus
  `ipv6_allowed_for_dual_stack = true`; asserts the attribute is `true`, proving
  the `optional()` attribute is wired through rather than dropped.
- **`dead_letter_config_omitted_creates_no_block`** — asserts
  `length(aws_lambda_function.lambda_function.dead_letter_config) == 0`.
- **`dead_letter_config_sets_target_arn`** — an SQS ARN; asserts
  `dead_letter_config[0].target_arn` matches it.
- **`tracing_config_omitted_creates_no_block`** — asserts
  `length(aws_lambda_function.lambda_function.tracing_config) == 0`.
- **`tracing_config_active`** / **`tracing_config_passthrough`** — assert
  `tracing_config[0].mode` is `Active` / `PassThrough` respectively; both
  accepted values must be exercised because the validation rejects everything
  else.
- **`reserved_concurrent_executions_omitted_is_unreserved`** — asserts the
  planned value represents "unreserved".
- **`reserved_concurrent_executions_set`** — `5`; asserts the planned value is
  `5`.
- **`reserved_concurrent_executions_zero_throttles_function`** — `0`; asserts
  the planned value is `0`, proving `0` is passed through rather than treated as
  "unset" by a falsy check.

*Implementer note on the "omitted" cases:* pin the assertion to whatever the
plan actually produces for an unset block/attribute (an empty block list, and
`null` or the provider's schema default for
`reserved_concurrent_executions`). If a value is unknown at plan time because
the provider marks the attribute `Computed`, keep the case and raise it in
review — do not delete it, mark it skipped, or replace the assertion with
something that would pass regardless of module behaviour.

### `modules/aws/lambda/tests/validation.tftest.hcl` (new)
One `expect_failures` case per distinct way each new `validation { ... }` block
can fail. Every case supplies otherwise-valid inputs so it fails only for the
rule under test:

- **`rejects_vpc_config_with_empty_subnet_ids`** — `subnet_ids = []` with a
  valid security group; `expect_failures = [var.vpc_config]`.
- **`rejects_vpc_config_with_empty_security_group_ids`** —
  `security_group_ids = []` with valid subnets;
  `expect_failures = [var.vpc_config]`.
- **`rejects_tracing_config_with_invalid_mode`** — `mode = "Enabled"`;
  `expect_failures = [var.tracing_config]`.
- **`rejects_tracing_config_with_wrong_case_mode`** — `mode = "active"`,
  proving the check is case-sensitive as AWS is;
  `expect_failures = [var.tracing_config]`.
- **`rejects_dead_letter_config_with_non_arn_target`** —
  `target_arn = "my-queue"`; `expect_failures = [var.dead_letter_config]`.
- **`rejects_dead_letter_config_with_unsupported_service_arn`** — e.g. an S3
  bucket ARN, proving the pattern is anchored to `sqs`/`sns` and not merely
  "starts with `arn:`"; `expect_failures = [var.dead_letter_config]`.
- **`rejects_negative_reserved_concurrent_executions`** — `-2`;
  `expect_failures = [var.reserved_concurrent_executions]`.
- **`accepts_unreserved_sentinel_reserved_concurrent_executions`** — `-1` plans
  successfully, proving the rule is not over-strict about AWS's own sentinel.
- **`valid_baseline_passes_all_validations`** — every new variable set to a
  valid value simultaneously; asserts the plan succeeds, proving the rules do
  not interfere with one another.

Every `expect_failures` case must fail *because* the new validation rejects the
input. If one does not fail, fix the condition in `variables.tf` — do not loosen
the assertion, delete the case, or mock the validation away. The full suite must
pass offline via
`tofu -chdir=modules/aws/lambda init -backend=false && tofu -chdir=modules/aws/lambda test`.

## 9. Open questions
- **Does `filename = null` alone satisfy the issue's fourth acceptance
  criterion?** That criterion's parenthetical — "e.g. when deploying from an S3
  object instead of a local `filename`" — implies S3 deployment, but
  `s3_bucket`/`s3_key`/`s3_object_version` are absent from the issue's proposed
  input list and from this module entirely. This spec reads the criterion
  literally (no "no value" error) and defers S3/container sources to the
  follow-up coverage issue. Reviewers who want the S3 path usable now should say
  so and the three `s3_*` inputs will be folded into scope.
- **`tags` default `{}` vs `{ terraform = "true" }`.** The issue offers both.
  This spec picks `{}` (the majority convention, 51 modules vs. 22, and what the
  newest modules use). Reviewers may prefer the `terraform = "true"` form for
  consistency with the older AWS modules.
- **Should the `Name` tag be opt-out?** As specified, a caller can override the
  value but not remove the key. An alternative is a separate `name` variable
  defaulting to `null` that suppresses the merge when unset — at the cost of
  diverging from the pattern every other module uses.
- **Should the remaining `aws_lambda_function` arguments land in the same PR?**
  Listed as a non-goal (§ 2), but `kms_key_arn` and `code_signing_config_arn` in
  particular are already named in `.checkov.yaml`'s suppression rationale, so
  the comment drift persists until that follow-up lands.
- **Should `qualified_invoke_arn`, `source_code_size`, `signing_job_arn`, and
  `signing_profile_version_arn` be added as outputs too?** They are free to
  expose and would move the module closer to § 1; this spec limits outputs to
  the issue's five plus `tags_all`.

## 10. Acceptance criteria
- [ ] A caller can set `tags` and see them applied to `aws_lambda_function`,
      merged with an automatic `Name` key derived from `function_name`, with a
      caller-supplied `Name` taking precedence.
- [ ] A caller can set `vpc_config` and have the function attached to the
      specified subnets/security groups, including
      `ipv6_allowed_for_dual_stack`; omitting it produces no `vpc_config` block.
- [ ] A caller can set `reserved_concurrent_executions`, `dead_letter_config`,
      and `tracing_config` independently, each defaulting to the provider's own
      default when omitted.
- [ ] A caller can omit `description`, `filename`, and `source_code_hash`
      without a "No value for required variable" error.
- [ ] `outputs.tf` exposes `function_name`, `invoke_arn`, `qualified_arn`,
      `version`, `last_modified`, and `tags_all` in addition to the existing
      `arn`, and every output (including `arn`) has a `description`.
- [ ] Invalid inputs fail at plan time with clear messages: a `tracing_config`
      mode other than `Active`/`PassThrough`, a `dead_letter_config.target_arn`
      that is not an SQS/SNS ARN, an empty `vpc_config.subnet_ids` or
      `vpc_config.security_group_ids`, and a
      `reserved_concurrent_executions` below `-1`.
- [ ] `modules/aws/lambda/tests/` gains the cases in § 8 (extended
      `main.tftest.hcl`, new `optional_blocks.tftest.hcl`, new
      `validation.tftest.hcl`); `tofu test` passes offline and all pre-existing
      cases still pass unweakened.
- [ ] `required_version` is `">= 1.3.0"` with a comment stating the reason; the
      `aws` provider constraint remains `">= 6.0.0"`.
- [ ] `README.md`'s hand-written usage examples are updated to show the new
      inputs and to distinguish required from optional, and the regenerated
      `<!-- BEGIN_TF_DOCS -->` block is committed so `Verify - terraform-docs`
      passes.
- [ ] No new Checkov/tfsec suppressions; no changes to the `runtime`/`timeout`
      defaults, the `environment` block, the commented-out
      `aws_lambda_permission` code, or any other module.
- [ ] `tofu fmt -check -diff -recursive` and `tofu validate` pass for the
      module.
