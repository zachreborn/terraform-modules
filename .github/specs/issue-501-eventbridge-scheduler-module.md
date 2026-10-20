# Spec: feat: new module wrapping aws_scheduler_schedule (EventBridge Scheduler)
**Issue:** #501
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The library has no module for [EventBridge Scheduler](https://docs.aws.amazon.com/scheduler/latest/UserGuide/what-is-scheduler.html)
(`aws_scheduler_schedule`). The only scheduling option today is
`modules/aws/cloudwatch/event`, which wraps the classic EventBridge *rule*
(`aws_cloudwatch_event_rule` + `aws_cloudwatch_event_target`) and has real gaps
relative to Scheduler:

- **No flexible time windows.** There is no `flexible_time_window` equivalent on
  an EventBridge rule, so every invocation fires at the exact scheduled instant
  with no jitter.
- **No timezone-aware schedules.** `var.schedule_expression`
  (`modules/aws/cloudwatch/event/variables.tf (48-52)`) is evaluated in UTC
  only; there is no `schedule_expression_timezone`.
- **No plain static target input.** The target only exposes `input_transformer`
  (`modules/aws/cloudwatch/event/variables.tf (72-79)`), not the provider's
  literal `input` string. A fixed JSON payload therefore has to be faked with an
  `input_transformer` carrying an empty `input_paths` map and the payload in
  `input_template` — a documented workaround, not a feature.
- **No first-class per-target invoke role.** EventBridge rules rely on a
  resource-policy-per-target-type model (e.g. a separate
  `aws_lambda_permission`, via `modules/aws/lambda_permission`); Scheduler
  instead assumes a single IAM role per schedule target.

The concrete driver is a scheduled Lambda deployment (a Paylocity → Active
Directory/Entra ID sync app) whose hosting brief calls for EventBridge Scheduler
by name: a daily, dry-run-by-default invocation with a static `{"apply": false}`
payload. That caller is currently using `modules/aws/cloudwatch/event` plus the
`input_transformer` workaround.

Issue: https://github.com/zachreborn/terraform-modules/issues/501
Provider docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule

Two facts discovered while researching the provider schema shape this spec and
are called out here because they are not obvious from the issue:

- **`aws_scheduler_schedule` has no `tags` argument.** EventBridge Scheduler
  supports tags on schedule *groups*, not on individual schedules. The repo's
  standard `tags = merge(tomap({ Name = var.name }), var.tags)` convention
  therefore cannot be applied to the schedule resource; `var.tags` in this
  module reaches only the composed IAM role and policy (see § 4).
- **`action_after_completion` is newer than the repo's provider floor.** It was
  added to `aws_scheduler_schedule` in `hashicorp/aws` **v6.14.0**
  ([PR #44264](https://github.com/hashicorp/terraform-provider-aws/pull/44264)),
  above the repo-wide `>= 6.0.0` baseline. Per `AGENTS.md` § Module Design
  Specifications § 7, using it requires bumping this module's constraint to
  `>= 6.14.0` (see § 4 and § 9).

## 2. Non-goals
- **No schedule *group* management.** `aws_scheduler_schedule_group` is a
  separate resource with its own tags and lifecycle. This module only *consumes*
  a group by name via `group_name`. A `modules/aws/eventbridge_scheduler_group`
  module, if wanted, should be filed separately.
- **No changes to `modules/aws/cloudwatch/event`.** Its `input_transformer`-only
  target, UTC-only `schedule_expression`, and missing `input` argument are left
  exactly as they are. Adding a literal `input` to that module is a separate
  issue; this spec does not deprecate, alter, or migrate it, and does not
  provide a `moved` block between the two modules (the underlying resource types
  differ, so no in-place migration is possible).
- **No KMS key creation.** `kms_key_arn` takes a caller-supplied CMK ARN. The
  module does **not** call `modules/aws/kms`, because a schedule's encryption key
  is nearly always shared with the target's key and is not owned by the
  schedule's lifecycle.
- **No SQS dead-letter queue creation.** `target_dead_letter_arn` takes a
  caller-supplied queue ARN; the module does not call `modules/aws/sqs_queue`.
  It *does* extend the generated invoke policy to allow `sqs:SendMessage` on
  that queue (see § 4).
- **No map/YAML fan-out input** (`AGENTS.md` § 5). This module manages one
  schedule, matching the issue's proposed interface and the single-resource
  shape of its closest sibling, `modules/aws/cloudwatch/event`. A map input is
  incompatible with the per-schedule composed IAM role this spec specifies
  (each entry would need its own role, policy, and derived action set). Callers
  scale with `for_each` on the module block. See § 9.
- **No target resource-policy management.** The module does not create
  `aws_lambda_permission`, SQS queue policies, or any other resource policy on
  the target. EventBridge Scheduler uses the assumed invoke role, not a
  resource policy.
- **No caller/`global/` changes.** Wiring the Paylocity sync app onto this
  module is out of scope.

## 3. Affected module path(s)
- `modules/aws/eventbridge_scheduler/` (new) — `main.tf`, `variables.tf`,
  `outputs.tf`, `README.md`, `tests/`
- `modules/aws/iam/role/` (existing) — **called, not modified**
- `modules/aws/iam/policy/` (existing) — **called, not modified**

The path is taken verbatim from the issue. It is deliberately flat (not
`modules/aws/scheduler/schedule/`) because § 2 lists no sibling Scheduler module
as in scope.

## 4. Proposed design
**Signatures only — no full implementations.**

### Design decisions the implementation must honour

**Composition (`AGENTS.md` § 2).** When `target_role_arn` is omitted the module
creates the invoke role by calling the existing child modules — never by
declaring `aws_iam_role` / `aws_iam_policy` inline:

- `module "target_invoke_policy"` → `source = "../iam/policy"`
- `module "target_role"` → `source = "../iam/role"`, with
  `policy_arns = concat([module.target_invoke_policy[0].arn], var.target_role_additional_policy_arns)`

Both are gated by `count = local.create_target_role ? 1 : 0`, following the
pattern already used in `modules/aws/ecs/task_definition/main.tf (55-87)`.

**Policy documents are built with `jsonencode()` in `locals`, not with
`data "aws_iam_policy_document"`.** Both forms exist in the repo
(`modules/aws/transfer_family/main.tf:156` uses `jsonencode`;
`modules/aws/ecs/task_definition/main.tf:21` uses the data source). `jsonencode`
is required here: under `mock_provider "aws"` the `aws_iam_policy_document` data
source is mocked, so `.json` is a synthetic value and the wiring assertions in
§ 8 could only test the mock. `jsonencode` locals are known at plan time, so the
generated documents can be exposed as outputs and asserted offline for real.

**Least-privilege action derivation.** The generated invoke policy must be
scoped to `target_arn`, not `"*"`. Because the required action depends on the
target service, the module derives it from the ARN's service namespace
(`split(":", var.target_arn)[2]`) using a static local map:

- `lambda` → `lambda:InvokeFunction`
- `sqs` → `sqs:SendMessage`
- `sns` → `sns:Publish`
- `states` → `states:StartExecution`
- `kinesis` → `kinesis:PutRecord`
- `firehose` → `firehose:PutRecord`
- `events` → `events:PutEvents`
- `codebuild` → `codebuild:StartBuild`
- `codepipeline` → `codepipeline:StartPipelineExecution`
- `sagemaker` → `sagemaker:StartPipelineExecution`

Two target shapes are deliberately **not** derivable and must fail the plan with
a clear message rather than fall back to a wildcard:

- **ECS** — `target_arn` is the *cluster* ARN, but `ecs:RunTask` must be scoped
  to the task definition and paired with `iam:PassRole`.
- **Universal targets** — `arn:<partition>:scheduler:::aws-sdk:<service>:<action>`
  names no real resource.

For both, the caller supplies `target_role_policy_actions` (and usually
`target_role_policy_resources`). This is enforced by precondition **P3** below.

**Trust policy.** The generated `assume_role_policy` allows
`scheduler.amazonaws.com` to `sts:AssumeRole`, with an `aws:SourceAccount`
condition pinned to `data.aws_caller_identity.current.account_id` (confused-deputy
protection, `AGENTS.md` § 3). When `var.name` is set — i.e. the schedule ARN is
known at plan time — it additionally pins `aws:SourceArn` to
`arn:<partition>:scheduler:<region>:<account>:schedule/<group_name_or_default>/<name>`.
Under `name_prefix` the final name is unknown at plan time, so the `SourceArn`
condition is omitted and only `SourceAccount` applies.

### `variables.tf`

#### Schedule variables
- **`name`** — `string`, default `null`. Name of the schedule. Forces
  replacement. Mutually exclusive with `name_prefix` (enforced by precondition
  P1, since cross-variable `validation` requires Terraform >= 1.9).
  `validation`: when non-null, matches `^[0-9a-zA-Z-_.]{1,64}$`.
  *Deviation from the issue, which listed `name` as required:* both forms are
  exposed for complete resource coverage (`AGENTS.md` § 1) and to match the
  `name`/`name_prefix` pattern already used by `modules/aws/cloudwatch/event`,
  `modules/aws/iam/role`, and `modules/aws/iam/policy`. This is strictly more
  permissive and does not weaken any acceptance criterion.
- **`name_prefix`** — `string`, default `null`. Creates a unique name beginning
  with this prefix. Forces replacement. `validation`: when non-null, matches
  `^[0-9a-zA-Z-_.]{1,64}$`.
- **`group_name`** — `string`, default `null`. Schedule group to associate with;
  AWS uses `default` when omitted. Forces replacement. `validation`: when
  non-null, matches `^[0-9a-zA-Z-_.]{1,64}$`.
- **`description`** — `string`, default `null`. `validation`: when non-null,
  length <= 512.
- **`schedule_expression`** — `string`, **required**. `at(...)`, `rate(...)`, or
  `cron(...)`. `validation`: matches `^(at|rate|cron)\(.+\)$`.
- **`schedule_expression_timezone`** — `string`, default `"UTC"`. IANA timezone
  in which the expression is evaluated. `validation`: non-empty (the IANA name
  itself is not enumerable in HCL).
- **`start_date`** — `string`, default `null`. UTC RFC3339 instant after which
  the schedule may begin invoking. `validation`: when non-null, matches
  `^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$`.
- **`end_date`** — `string`, default `null`. Same type and `validation` as
  `start_date`. Ordering relative to `start_date` is precondition P4.
- **`state`** — `string`, default `"ENABLED"`. `validation`:
  `contains(["ENABLED", "DISABLED"], var.state)`.
- **`action_after_completion`** — `string`, default `null` (provider default
  `NONE`). `validation`: when non-null,
  `contains(["NONE", "DELETE"], var.action_after_completion)`.
- **`kms_key_arn`** — `string`, default `null`. Customer-managed CMK for
  encrypting the schedule's data. `validation`: when non-null, matches `^arn:`.
- **`region`** — `string`, default `null`. Region where the schedule is managed;
  defaults to the provider's region. Mirrors
  `modules/aws/managed_prefix_list/variables.tf (47-51)`.
- **`flexible_time_window`** — object, default `{ mode = "OFF" }`:
  ```
  object({
    mode                      = optional(string, "OFF")
    maximum_window_in_minutes = optional(number)
  })
  ```
  Three separate `validation` blocks so each failure names its own cause:
  1. `mode` is one of `OFF`, `FLEXIBLE`.
  2. `mode == "FLEXIBLE"` requires `maximum_window_in_minutes` non-null and
     within `1..1440`.
  3. `mode == "OFF"` requires `maximum_window_in_minutes` to be null (AWS
     rejects a window on an `OFF` schedule).

#### Target variables
- **`target_arn`** — `string`, **required**. ARN of the target to invoke, or a
  universal-target service ARN. `validation`: matches `^arn:`.
- **`target_input`** — `string`, default `null`. Text or well-formed JSON passed
  to the target on every invocation. *This is the capability the issue is
  chiefly about;* callers pass e.g. `jsonencode({ apply = false })`.
- **`target_role_arn`** — `string`, default `null`. Existing invoke role. When
  `null`, the module creates one (see composition above). `validation`: when
  non-null, matches `^arn:`.
- **`target_dead_letter_arn`** — `string`, default `null`. SQS queue ARN for
  the target's `dead_letter_config`. `validation`: when non-null, matches
  `^arn:`.
- **`target_retry_policy`** — object, default `null`:
  ```
  object({
    maximum_event_age_in_seconds = optional(number)
    maximum_retry_attempts       = optional(number)
  })
  ```
  Two `validation` blocks: `maximum_event_age_in_seconds` within `60..86400`
  when non-null; `maximum_retry_attempts` within `0..185` when non-null.
- **`target_ecs_parameters`** — object, default `null`, covering every argument
  of the provider's `ecs_parameters` block:
  ```
  object({
    task_definition_arn     = string
    capacity_provider_strategy = optional(list(object({
      capacity_provider = string
      base              = optional(number)
      weight            = optional(number)
    })), [])
    enable_ecs_managed_tags = optional(bool)
    enable_execute_command  = optional(bool)
    group                   = optional(string)
    launch_type             = optional(string)
    network_configuration = optional(object({
      assign_public_ip = optional(bool)
      security_groups  = optional(set(string))
      subnets          = optional(set(string))
    }))
    placement_constraints = optional(list(object({
      type       = string
      expression = optional(string)
    })), [])
    placement_strategy = optional(list(object({
      type  = string
      field = optional(string)
    })), [])
    platform_version = optional(string)
    propagate_tags   = optional(string)
    reference_id     = optional(string)
    region           = optional(string)
    tags             = optional(map(string))
    task_count       = optional(number)
  })
  ```
  `validation` blocks: `launch_type` in `EC2`/`FARGATE`/`EXTERNAL` when non-null;
  `task_count` within `1..10` when non-null; `capacity_provider_strategy` at most
  6 entries; `placement_constraints` at most 10; `placement_strategy` at most 5.
- **`target_eventbridge_parameters`** — `object({ detail_type = string, source = string })`,
  default `null`. `validation`: `detail_type` length <= 128.
- **`target_kinesis_parameters`** — `object({ partition_key = string })`,
  default `null`. `validation`: `partition_key` length within `1..256`.
- **`target_sagemaker_pipeline_parameters`** —
  `object({ pipeline_parameter = optional(list(object({ name = string, value = string })), []) })`,
  default `null`. `validation`: at most 200 entries.
- **`target_sqs_parameters`** — `object({ message_group_id = optional(string) })`,
  default `null`.

At most one of the five templated `target_*_parameters` variables may be set;
this is precondition P2 (cross-variable, so not expressible as a `validation`
block below Terraform 1.9).

#### Created-invoke-role variables
All are ignored when `target_role_arn` is supplied.

- **`target_role_name`** — `string`, default `null`. When null the module passes
  a derived `name_prefix` to `modules/aws/iam/role` instead
  (`substr("${coalesce(var.name, var.name_prefix)}-scheduler-", 0, 38)` — IAM
  caps `name_prefix` at 38 characters).
- **`target_role_path`** — `string`, default `"/"`.
- **`target_role_permissions_boundary`** — `string`, default `null`.
- **`target_role_max_session_duration`** — `number`, default `3600`.
  `validation`: within `3600..43200` (mirrors `modules/aws/iam/role`).
- **`target_role_policy_actions`** — `list(string)`, default `null`. Overrides
  the derived action set. `validation`: when non-null, non-empty.
- **`target_role_policy_resources`** — `list(string)`, default `null`. Overrides
  the policy's `Resource`; when null the module uses `[var.target_arn]`.
  `validation`: when non-null, non-empty and every element matches `^arn:`.
- **`target_role_additional_policy_arns`** — `list(string)`, default `[]`.
  Extra managed/customer policy ARNs attached alongside the generated one (e.g.
  `kms:GenerateDataKey` for an encrypted SQS target). `validation`: every
  element matches `^arn:`.

#### General variables
- **`tags`** — `map(string)`, default `{ terraform = "true" }`. Applied to the
  composed IAM role and policy only. `aws_scheduler_schedule` accepts no tags,
  so the repo's `merge(tomap({ Name = var.name }), var.tags)` convention applies
  to the child modules, not to the schedule. The description must say this
  explicitly, since it is surprising.

### `outputs.tf`
- **`arn`** — ARN of the schedule.
- **`id`** — ID of the schedule (its name).
- **`name`** — resolved schedule name, including one generated from
  `name_prefix`.
- **`group_name`** — schedule group the schedule belongs to.
- **`state`** — `ENABLED` / `DISABLED` as applied.
- **`schedule_expression`** — the applied expression.
- **`schedule_expression_timezone`** — the applied timezone.
- **`target_arn`** — ARN of the invoked target, read back off the resource's
  `target` block (not echoed from `var.target_arn`).
- **`target_role_arn`** — resolved invoke role ARN, whether supplied via
  `target_role_arn` or created by the module. This is the issue's third
  requested output.
- **`target_role_name`** — name of the created role; `null` when the caller
  supplied `target_role_arn`.
- **`target_role_created`** — `bool`, `true` when the module created the role.
- **`target_invoke_policy_arn`** — ARN of the generated invoke policy; `null`
  when the caller supplied `target_role_arn`.
- **`target_assume_role_policy_json`** — generated trust policy document;
  `null` when no role was created.
- **`target_invoke_policy_json`** — generated invoke policy document; `null`
  when no role was created.

The last two exist so the composition can be asserted offline (§ 8) and so
callers can inspect exactly what least-privilege policy was derived; they are
not merely diagnostic.

### `main.tf`

**`terraform {}` block** (`AGENTS.md` § 7 — constraints are per-module floors,
each with a one-line comment giving the reason):

- `required_version = ">= 1.3.0"` — `optional()` attributes are used throughout
  the object type constraints above. Same rationale and comment style as
  `modules/aws/managed_prefix_list/main.tf (5-7)`.
- `aws version = ">= 6.14.0"` — `action_after_completion` was added to
  `aws_scheduler_schedule` in `hashicorp/aws` v6.14.0
  ([PR #44264](https://github.com/hashicorp/terraform-provider-aws/pull/44264)).
  Every other argument this module sets exists at the repo baseline `>= 6.0.0`.
  See § 9 for the alternative.

**Data sources** — each `count = local.create_target_role ? 1 : 0`, so a caller
supplying `target_role_arn` makes no extra API calls:

- `data "aws_caller_identity" "current"` — `aws:SourceAccount` condition.
- `data "aws_partition" "current"` — partition segment of the `aws:SourceArn`.
- `data "aws_region" "current"` — region segment of the `aws:SourceArn`.

**Locals:**

- `create_target_role` — `var.target_role_arn == null`.
- `target_service` — `split(":", var.target_arn)[2]`.
- `derivable_target_actions` — the static service → action map listed above.
- `invoke_policy_actions` — `coalesce(var.target_role_policy_actions, lookup(...))`.
- `invoke_policy_resources` — `coalesce(var.target_role_policy_resources, [var.target_arn])`.
- `assume_role_policy_json` — `jsonencode({...})`, conditions as described above.
- `invoke_policy_json` — `jsonencode({...})`; one statement for the target, plus
  a second `sqs:SendMessage` statement on `var.target_dead_letter_arn` when that
  variable is non-null.
- `target_role_arn` — `local.create_target_role ? module.target_role[0].arn : var.target_role_arn`.

**Composed modules** (both `count = local.create_target_role ? 1 : 0`):

- `module "target_invoke_policy"` — `source = "../iam/policy"`;
  `policy = local.invoke_policy_json`; `description` names the schedule;
  `name`/`name_prefix` derived as described; `path = var.target_role_path`;
  `tags` merged.
- `module "target_role"` — `source = "../iam/role"`;
  `assume_role_policy = local.assume_role_policy_json`;
  `policy_arns = concat([module.target_invoke_policy[0].arn], var.target_role_additional_policy_arns)`;
  `max_session_duration`, `path`, `permissions_boundary`, `tags` from the
  corresponding variables.

**`resource "aws_scheduler_schedule" "this"`** — a single instance (no
`count`/`for_each`). Arguments: `name`, `name_prefix`, `group_name`,
`description`, `schedule_expression`, `schedule_expression_timezone`,
`start_date`, `end_date`, `state`, `action_after_completion`, `kms_key_arn`,
`region`. No `tags` argument (see above). Nested blocks:

- `flexible_time_window { mode, maximum_window_in_minutes }` — static block
  (the provider requires exactly one), fed from `var.flexible_time_window`.
- `target { arn, role_arn, input }` — static block (required); `role_arn` is
  `local.target_role_arn`, which is the wiring point between the composed role
  and the schedule. Inside it:
  - `dynamic "dead_letter_config"` — `for_each` on `var.target_dead_letter_arn != null`
  - `dynamic "retry_policy"` — `for_each` on `var.target_retry_policy != null`
  - `dynamic "ecs_parameters"` — `for_each` on `var.target_ecs_parameters != null`,
    with nested `dynamic "capacity_provider_strategy"`, `dynamic "network_configuration"`,
    `dynamic "placement_constraints"`, and `dynamic "placement_strategy"`
  - `dynamic "eventbridge_parameters"` — `for_each` on `var.target_eventbridge_parameters != null`
  - `dynamic "kinesis_parameters"` — `for_each` on `var.target_kinesis_parameters != null`
  - `dynamic "sagemaker_pipeline_parameters"` — `for_each` on
    `var.target_sagemaker_pipeline_parameters != null`, with a nested
    `dynamic "pipeline_parameter"`
  - `dynamic "sqs_parameters"` — `for_each` on `var.target_sqs_parameters != null`

  The `dynamic … != null ? [x] : []` idiom matches
  `modules/aws/ecs/task_definition/main.tf (114-195)`.

**No `lifecycle { ignore_changes = ... }`.** Nothing on this resource is
mutated outside Terraform, so the repo's `aws_instance`-style ignore pattern
does not apply here.

**`lifecycle { precondition ... }` blocks** on `aws_scheduler_schedule.this`,
following the `modules/aws/managed_prefix_list/main.tf (34-48)` precedent (these
are cross-variable checks, which `validation` blocks cannot express below
Terraform 1.9, and the repo floor is 1.3.0):

- **P1** — exactly one of `var.name` / `var.name_prefix` is set.
- **P2** — at most one of the five templated `target_*_parameters` variables is
  set.
- **P3** — when `local.create_target_role` and `var.target_role_policy_actions`
  is null, `local.target_service` must be a key of
  `local.derivable_target_actions`. The error message must name the service and
  tell the caller to set `target_role_policy_actions` (and usually
  `target_role_policy_resources`), explicitly covering the ECS and
  universal-target cases.
- **P4** — when both `start_date` and `end_date` are set, `end_date` must be
  strictly later. (RFC3339 `...Z` strings sort lexicographically, so a string
  comparison is correct and needs no time functions.)

### `README.md`
Per `AGENTS.md` § 4, outside the generated block:

- Description of the module and the `aws_scheduler_schedule` resource it manages.
- **Prerequisites** — the target (Lambda function, SQS queue, state machine, …)
  must already exist; a CMK must already exist if `kms_key_arn` is used; a
  schedule group must already exist if `group_name` is set (this module does not
  create one).
- **Usage examples** — at minimum (a) the issue's driving case: a daily
  Lambda invocation with a static `target_input` payload and a module-created
  invoke role; (b) a `FLEXIBLE` window with a non-UTC
  `schedule_expression_timezone`; (c) a caller-supplied `target_role_arn`;
  (d) an ECS target showing the explicit `target_role_policy_actions` /
  `target_role_policy_resources` that precondition P3 requires.
- **Notes / design decisions** — the schedule resource accepts no tags and
  `var.tags` therefore reaches only the composed IAM role and policy; how the
  invoke action is derived and when the caller must supply it; the
  `aws:SourceArn` condition being omitted under `name_prefix`; and the
  `>= 6.14.0` provider floor and why.
- The `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers.

## 5. Breaking-change assessment
- Breaking: **no**.
- Purely additive. A brand-new module directory; no existing module's variables,
  outputs, resources, or defaults change. `modules/aws/iam/role` and
  `modules/aws/iam/policy` are called with their existing interfaces and are not
  edited, so their current callers are unaffected.
- No existing caller can be broken because the module has no callers. Classified
  as `feat:` (MINOR) under the repo's release-please conventions.
- One adoption caveat worth review attention, not a breaking change: the
  `aws >= 6.14.0` provider floor is higher than the repo baseline `>= 6.0.0`.
  A caller pinned to `hashicorp/aws` 6.0–6.13 cannot use this module. That is
  what `AGENTS.md` § 7 requires given `action_after_completion`; § 9 records the
  alternative if reviewers prefer to keep the floor at `>= 6.0.0`.

## 6. Checkov / tfsec considerations
- **New suppressions: none.** No inline `#tfsec:ignore:` or `#checkov:skip=`
  comment is planned, and no new entry in the repo-root `.checkov.yaml`.
  Rationale:
  - The generated invoke policy is scoped to concrete actions and
    `[var.target_arn]`; precondition P3 makes an un-derivable target a plan-time
    error rather than a silent `"*"`. The IAM-wildcard checks
    (`CKV_AWS_290`, `CKV_AWS_355`) should therefore not fire on generated
    output — and they are already globally skipped in `.checkov.yaml (162-164)`
    regardless.
  - `kms_key_arn` is exposed as a caller-controlled variable, so a
    CMK-encryption check on the schedule would fall in the existing
    "configurable by caller" category; none is expected to fire, and none is
    pre-emptively suppressed.
  - `CKV_TF_1` (module sources must use a git URL with a commit hash) is already
    globally skipped in `.checkov.yaml:16`, so the `../iam/role` and
    `../iam/policy` relative sources need no new entry.
  - `skip-path: tests/` in `.checkov.yaml (10-11)` already covers the new
    `tests/` fixtures.
- **Existing suppressions affected: none.** No entry in `.checkov.yaml` relates
  to EventBridge Scheduler, and no existing module is touched.
- The implementation must still run `checkov -d modules/aws/eventbridge_scheduler`
  locally. If a check does fire, the fix is to correct the module — not to add a
  suppression — unless the finding is genuinely a caller-controlled variable, in
  which case a new `.checkov.yaml` entry must be added in the same documented
  format as the existing ones, and this spec section updated in review.

## 7. terraform-docs impact
**Yes — one new generated block, no changes to any existing one.**

- `modules/aws/eventbridge_scheduler/README.md` gains a fresh
  `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` block containing the
  Requirements (`opentofu/terraform >= 1.3.0`, `aws >= 6.14.0`), Providers,
  **Modules** (`target_role` → `../iam/role`, `target_invoke_policy` →
  `../iam/policy`), Resources, Inputs, and Outputs tables.
- No other module's README changes: `modules/aws/iam/role/README.md` and
  `modules/aws/iam/policy/README.md` are unaffected because being *called* by a
  new module does not alter their own generated content.

The implementation must generate the block locally — `pre-commit run --all-files`,
or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/eventbridge_scheduler`
— and commit the result. The `Verify - terraform-docs` job fails on any diff and
does not auto-commit.

## 8. Testing
Standard local checks:

- `tofu -chdir=modules/aws/eventbridge_scheduler init -backend=false && tofu -chdir=modules/aws/eventbridge_scheduler validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/eventbridge_scheduler` (locally; CI runs on schedule)

Native `tofu test` plan (required — `AGENTS.md` § Module Design Specifications
§ 6). Every case uses `command = plan`, follows the `mock_provider` / `run` /
`expect_failures` conventions in `modules/aws/managed_prefix_list/tests/` and
`modules/aws/organizations/tests/wiring.tftest.hcl`, and must pass fully offline
via `tofu -chdir=modules/aws/eventbridge_scheduler init -backend=false && tofu -chdir=modules/aws/eventbridge_scheduler test`.

### Shared mock setup
Each test file declares a `mock_provider "aws"` with:

- `mock_resource "aws_scheduler_schedule"` — `defaults` for `arn`
  (`arn:aws:scheduler:us-east-1:123456789012:schedule/default/example`) and `id`.
- `mock_resource "aws_iam_role"` — `defaults` for `arn`
  (`arn:aws:iam::123456789012:role/mock-scheduler-role`) and `name`, so the
  created role's ARN is a distinguishable literal the wiring cases can assert on.
- `mock_resource "aws_iam_policy"` — `defaults` for `arn`
  (`arn:aws:iam::123456789012:policy/mock-invoke-policy`) and `id`.
- `mock_data "aws_caller_identity"` — `defaults = { account_id = "123456789012" }`.
- `mock_data "aws_partition"` — `defaults = { partition = "aws" }`.
- `mock_data "aws_region"` — `defaults` pinning the region used in the
  `aws:SourceArn` assertions.

The `assume_role_policy` and invoke-policy documents are `jsonencode()` locals
exposed as outputs, so `jsondecode(output.…)` assertions test the module's real
output rather than a mocked provider value.

### `tests/main.tftest.hcl` — baseline, schedule-level branches, outputs
- **`plan_succeeds_with_valid_baseline`** — only `name`, `schedule_expression`,
  and a Lambda `target_arn`. Assert `flexible_time_window[0].mode == "OFF"`,
  `maximum_window_in_minutes == null`, `schedule_expression_timezone == "UTC"`,
  `state == "ENABLED"`, `action_after_completion == null`, and
  `length(aws_scheduler_schedule.this.target) == 1`. This is the required
  valid-baseline case and also covers the "no templated parameters" side of
  every target branch.
- **`outputs_expose_schedule_attributes`** — same inputs; assert
  `output.arn` and `output.id` equal the mocked values, and that `output.name`,
  `output.group_name`, `output.state`, `output.schedule_expression`,
  `output.schedule_expression_timezone`, and `output.target_arn` each equal the
  corresponding attribute on `aws_scheduler_schedule.this` (real values, not
  merely non-null).
- **`name_prefix_branch_omits_name`** — `name_prefix` set, `name` null; assert
  `aws_scheduler_schedule.this.name == null` and `name_prefix` is passed
  through. Covers the P1 "prefix" side.
- **`group_name_is_passed_through`** — non-default `group_name`; assert it lands
  on the resource and on `output.group_name`. Covers the set/unset branch.
- **`flexible_time_window_flexible_branch`** — `mode = "FLEXIBLE"`,
  `maximum_window_in_minutes = 15`; assert both land on the
  `flexible_time_window` block. This is the issue's third acceptance criterion.
- **`non_utc_timezone_is_applied`** — `schedule_expression_timezone = "America/Denver"`;
  assert the resource attribute equals it. The issue's second acceptance
  criterion.
- **`state_disabled_is_applied`** — `state = "DISABLED"`; assert pass-through.
- **`start_and_end_date_are_applied`** — both set and correctly ordered; assert
  both land on the resource. Covers the set side of both branches and the
  passing side of precondition P4.
- **`action_after_completion_delete_is_applied`** — `"DELETE"`; assert
  pass-through. Covers the set side; the baseline covers the unset side.
- **`kms_key_arn_is_applied`** — assert pass-through; baseline covers unset.
- **`region_override_is_honored`** — assert `aws_scheduler_schedule.this.region`
  equals the override, mirroring
  `modules/aws/managed_prefix_list/tests/main.tftest.hcl (99-111)`.

### `tests/target.tftest.hcl` — target block branches
- **`static_target_input_is_passed_through`** — `target_input = jsonencode({ apply = false })`;
  assert `aws_scheduler_schedule.this.target[0].input` decodes to
  `{ apply = false }`. **This is the issue's first and primary acceptance
  criterion** — it proves a literal payload needs no `input_transformer`.
- **`dead_letter_config_branch_creates_block`** — `target_dead_letter_arn` set;
  assert `length(target[0].dead_letter_config) == 1` and its `arn` matches.
  Baseline covers the empty side.
- **`retry_policy_branch_creates_block`** — both retry fields set; assert the
  block exists and both values land.
- **`ecs_parameters_branch_creates_block`** — an ECS target with
  `task_definition_arn`, `launch_type`, `task_count`, a
  `capacity_provider_strategy` entry, a `network_configuration`, a
  `placement_constraints` entry, and a `placement_strategy` entry, plus explicit
  `target_role_policy_actions`/`target_role_policy_resources` (required by P3).
  Assert the `ecs_parameters` block exists and that **each** nested dynamic block
  produced exactly one element with the supplied values — this is the only case
  covering those four nested `for_each` branches.
- **`eventbridge_parameters_branch_creates_block`** — assert `detail_type` and
  `source` land.
- **`kinesis_parameters_branch_creates_block`** — assert `partition_key` lands.
- **`sagemaker_pipeline_parameters_branch_creates_block`** — two
  `pipeline_parameter` entries; assert `length(...) == 2` and that the
  name/value pairs land, covering the nested dynamic.
- **`sqs_parameters_branch_creates_block`** — assert `message_group_id` lands.

### `tests/iam_role.tftest.hcl` — composition/wiring (`AGENTS.md` § 6)
- **`created_role_arn_is_wired_into_the_schedule_target`** — no
  `target_role_arn`. Assert
  `aws_scheduler_schedule.this.target[0].role_arn == "arn:aws:iam::123456789012:role/mock-scheduler-role"`
  (the mocked `aws_iam_role` ARN) and that `output.target_role_arn` equals the
  same value. Comparing against the mocked literal — not merely `!= null` —
  is what proves the value came out of the `../iam/role` child module and back
  into the schedule, following the precedent in
  `modules/aws/organizations/tests/wiring.tftest.hcl (185-188)`. Also assert
  `output.target_role_created == true`, `output.target_role_name != null`, and
  `output.target_invoke_policy_arn == "arn:aws:iam::123456789012:policy/mock-invoke-policy"`
  (proving the `../iam/policy` child module was created and its ARN surfaced).
- **`supplied_role_arn_skips_role_creation`** — `target_role_arn` set to a
  literal. Assert `aws_scheduler_schedule.this.target[0].role_arn` equals that
  literal, `output.target_role_created == false`, and
  `output.target_role_name`, `output.target_invoke_policy_arn`,
  `output.target_assume_role_policy_json`, and `output.target_invoke_policy_json`
  are all `null` — proving both `count = 0` branches.
- **`derived_invoke_policy_scopes_lambda_action_to_target_arn`** — Lambda
  target, no explicit actions. Assert
  `jsondecode(output.target_invoke_policy_json).Statement[0].Action == ["lambda:InvokeFunction"]`
  and `.Resource == [<the lambda target_arn>]`. This is the issue's fourth
  acceptance criterion (least privilege scoped to `target_arn`) and the derived
  branch of `target_role_policy_actions`.
- **`derived_invoke_policy_scopes_sqs_action_to_target_arn`** — an SQS target;
  assert the action is `["sqs:SendMessage"]`. Proves the derivation map is keyed
  on the ARN's service namespace rather than hard-coded to Lambda.
- **`explicit_policy_actions_and_resources_override_derivation`** — both
  override variables set on an ECS target; assert the decoded statement uses the
  supplied actions and resources verbatim. Covers the override branch of both
  variables and the `coalesce` fallback logic.
- **`dead_letter_queue_adds_send_message_statement`** —
  `target_dead_letter_arn` set; assert the decoded invoke policy has two
  statements and that the second allows `sqs:SendMessage` on the DLQ ARN.
  Covers the conditional second statement.
- **`additional_policy_arns_are_attached_alongside_generated_policy`** — one
  extra managed-policy ARN. Assert `output.target_role_created == true` and,
  since the child module's attachments are not addressable from the wrapper's
  tests, assert on the module's own contribution: the run plans successfully and
  `output.target_invoke_policy_arn` is still the generated policy — proving
  `concat` did not replace it. The empty-list side is covered by the baseline.
- **`assume_role_policy_pins_service_and_source_account`** — assert the decoded
  `output.target_assume_role_policy_json` has principal
  `scheduler.amazonaws.com`, action `sts:AssumeRole`, and an
  `aws:SourceAccount` condition equal to the mocked `123456789012`.
- **`assume_role_policy_pins_source_arn_when_name_is_set`** — assert the decoded
  trust policy's `aws:SourceArn` condition equals the constructed
  `arn:aws:scheduler:<region>:123456789012:schedule/default/<name>`, proving the
  partition/region/account data sources are wired in correctly.
- **`assume_role_policy_omits_source_arn_under_name_prefix`** — same inputs but
  with `name_prefix`; assert the decoded trust policy has **no** `aws:SourceArn`
  key while `aws:SourceAccount` is still present. Covers the other side of that
  conditional.

### `tests/validation.tftest.hcl` — one case per failure mode
`expect_failures` on the variable for `validation` blocks, and on
`aws_scheduler_schedule.this` for preconditions (the pattern already used in
`modules/aws/managed_prefix_list/tests/validation.tftest.hcl (80, 94)`). Every
case must supply otherwise-valid inputs so it fails only for the reason under
test.

- **`valid_baseline_does_not_fail`** — minimal valid input; assert
  `aws_scheduler_schedule.this.schedule_expression` equals the supplied
  expression, proving the validation blocks do not reject the happy path.

Variable-validation cases:

- `rejects_name_with_invalid_characters` → `[var.name]`
- `rejects_name_longer_than_64_characters` → `[var.name]`
- `rejects_name_prefix_with_invalid_characters` → `[var.name_prefix]`
- `rejects_group_name_with_invalid_characters` → `[var.group_name]`
- `rejects_description_longer_than_512_characters` → `[var.description]`
- `rejects_schedule_expression_without_at_rate_or_cron` → `[var.schedule_expression]`
- `rejects_empty_schedule_expression_timezone` → `[var.schedule_expression_timezone]`
- `rejects_start_date_that_is_not_rfc3339_utc` → `[var.start_date]`
- `rejects_end_date_that_is_not_rfc3339_utc` → `[var.end_date]`
- `rejects_invalid_state` → `[var.state]`
- `rejects_invalid_action_after_completion` → `[var.action_after_completion]`
- `rejects_kms_key_arn_that_is_not_an_arn` → `[var.kms_key_arn]`
- `rejects_invalid_flexible_time_window_mode` → `[var.flexible_time_window]`
- `rejects_flexible_mode_without_maximum_window_in_minutes` → `[var.flexible_time_window]`
- `rejects_maximum_window_in_minutes_above_1440` → `[var.flexible_time_window]`
- `rejects_maximum_window_in_minutes_when_mode_is_off` → `[var.flexible_time_window]`
- `rejects_target_arn_that_is_not_an_arn` → `[var.target_arn]`
- `rejects_target_role_arn_that_is_not_an_arn` → `[var.target_role_arn]`
- `rejects_target_dead_letter_arn_that_is_not_an_arn` → `[var.target_dead_letter_arn]`
- `rejects_maximum_event_age_below_60` → `[var.target_retry_policy]`
- `rejects_maximum_retry_attempts_above_185` → `[var.target_retry_policy]`
- `rejects_invalid_ecs_launch_type` → `[var.target_ecs_parameters]`
- `rejects_ecs_task_count_above_10` → `[var.target_ecs_parameters]`
- `rejects_more_than_six_capacity_provider_strategies` → `[var.target_ecs_parameters]`
- `rejects_more_than_ten_placement_constraints` → `[var.target_ecs_parameters]`
- `rejects_more_than_five_placement_strategies` → `[var.target_ecs_parameters]`
- `rejects_detail_type_longer_than_128_characters` → `[var.target_eventbridge_parameters]`
- `rejects_empty_kinesis_partition_key` → `[var.target_kinesis_parameters]`
- `rejects_more_than_200_pipeline_parameters` → `[var.target_sagemaker_pipeline_parameters]`
- `rejects_empty_target_role_policy_actions` → `[var.target_role_policy_actions]`
- `rejects_target_role_policy_resources_that_are_not_arns` → `[var.target_role_policy_resources]`
- `rejects_additional_policy_arn_that_is_not_an_arn` → `[var.target_role_additional_policy_arns]`
- `rejects_target_role_max_session_duration_below_3600` → `[var.target_role_max_session_duration]`

Precondition cases, all `expect_failures = [aws_scheduler_schedule.this]`:

- `rejects_both_name_and_name_prefix` (P1)
- `rejects_neither_name_nor_name_prefix` (P1)
- `rejects_two_templated_parameter_blocks` (P2) — e.g. `target_sqs_parameters`
  and `target_kinesis_parameters` together
- `rejects_ecs_target_without_explicit_policy_actions` (P3) — an ECS cluster
  `target_arn`, no `target_role_arn`, no `target_role_policy_actions`
- `rejects_universal_target_without_explicit_policy_actions` (P3) — an
  `arn:aws:scheduler:::aws-sdk:sqs:sendMessage` target under the same conditions
- `rejects_end_date_before_start_date` (P4)

Note for the implementer: P3 must **not** fire when the caller supplies
`target_role_arn`, because no role is created. That passing path is already
covered by `supplied_role_arn_skips_role_creation` above; add an ECS-target
variant of it if the implementation makes the two conditions interact.

Per `AGENTS.md` § 6, if a case fails, fix the root cause in
`main.tf`/`variables.tf`/`outputs.tf` (or a demonstrably wrong expected value in
the test). Do not narrow an assertion, delete a `run` block, loosen an
`expect_failures` case, or mock away the behavior under test to force a pass.

## 9. Open questions
- **Provider floor vs. `action_after_completion`.** `AGENTS.md` § 7 requires
  `aws >= 6.14.0` because the module sets that argument, but that floor is 14
  minor releases above the repo baseline and locks out callers pinned to
  6.0–6.13. The alternative is to drop `action_after_completion` from this
  module's surface (accepting an `AGENTS.md` § 1 coverage gap) and keep
  `>= 6.0.0`, adding the argument in a later `feat:` once the repo baseline
  moves. This spec assumes `>= 6.14.0`; reviewers should confirm.
- **Single schedule vs. a `schedules` map (`AGENTS.md` § 5).** Listed as a
  non-goal in § 2 with rationale, but § 5 is written as a "must" for resources
  callers will have many of, and schedules qualify. Folding the map in now would
  avoid a future breaking interface change, at the cost of a per-entry IAM role
  fan-out (`for_each` over the `../iam/role` and `../iam/policy` modules) and a
  materially larger test matrix. Reviewers should decide explicitly rather than
  let the precedent form by default.
- **Scope of the derived-action map.** The ten services listed in § 4 cover
  Scheduler's templated targets. Should `ecs` get a derivation that scopes
  `ecs:RunTask` to `target_ecs_parameters.task_definition_arn` and adds
  `iam:PassRole` (making the common ECS case work without explicit actions), or
  is requiring explicit actions there the safer least-privilege default? This
  spec assumes the latter.
- **Naming of the target-prefixed variables.** `target_input`,
  `target_retry_policy`, `target_ecs_parameters`, … flatten the provider's
  nested `target` block into prefixed top-level variables (following
  `modules/aws/cloudwatch/event`'s `event_target_arn`). The alternative is a
  single `target` object variable that mirrors the provider block one-for-one.
  Flattened is proposed because it keeps per-field `validation` blocks possible;
  a single object would push nearly every check into preconditions.
- **`modules/aws/cloudwatch/event` follow-up.** Should a separate issue be filed
  to add a literal `input` to that module's target, so existing callers can drop
  the `input_transformer` workaround without migrating to Scheduler? Out of
  scope here, but the issue's motivation implies it.

## 10. Acceptance criteria
- [ ] `modules/aws/eventbridge_scheduler/` exists with `main.tf`,
      `variables.tf`, `outputs.tf`, `README.md`, and `tests/`, following the
      repo's four-file layout and `###` section-header convention.
- [ ] A caller can create a schedule with a static `target_input` payload — a
      plain JSON string on the target — with no `input_transformer`-style
      workaround, and a `tofu test` case asserts the payload lands on
      `aws_scheduler_schedule.this.target[0].input`.
- [ ] `schedule_expression_timezone` accepts a non-UTC IANA timezone, defaults
      to `UTC`, and is asserted to reach the resource.
- [ ] `flexible_time_window` supports `mode = "FLEXIBLE"` with
      `maximum_window_in_minutes`, defaults to `{ mode = "OFF" }`, and rejects
      an out-of-range or mode-inconsistent window at plan time.
- [ ] When `target_role_arn` is omitted, the module provisions a least-privilege
      invoke role via `modules/aws/iam/role` plus a generated policy via
      `modules/aws/iam/policy`, scoped to `target_arn` with a derived
      service-specific action — never `"*"` — and a trust policy limited to
      `scheduler.amazonaws.com` with an `aws:SourceAccount` condition.
- [ ] When `target_role_arn` is supplied, neither child module is created and
      `output.target_role_arn` returns the supplied ARN.
- [ ] A target whose action cannot be derived (ECS, universal targets) fails at
      plan time with a message directing the caller to
      `target_role_policy_actions`, rather than falling back to a wildcard.
- [ ] Every argument of `aws_scheduler_schedule` — including all five templated
      `*_parameters` blocks, `dead_letter_config`, `retry_policy`, `start_date`,
      `end_date`, `action_after_completion`, `kms_key_arn`, `group_name`,
      `name_prefix`, and `region` — is reachable from `variables.tf`
      (`AGENTS.md` § 1).
- [ ] `outputs.tf` exposes at least `arn`, `name`, and `target_role_arn` (the
      issue's three requested outputs) plus the remaining outputs in § 4, and
      every one is asserted in `tests/`.
- [ ] `tests/` contains a valid-baseline case, one `expect_failures` case per
      `validation` rule, one `expect_failures` case per precondition, one case
      per conditional/`dynamic` branch, output assertions, and the
      submodule-wiring assertions in § 8; all pass offline via
      `tofu -chdir=modules/aws/eventbridge_scheduler init -backend=false && tofu -chdir=modules/aws/eventbridge_scheduler test`
      with no credentials or backend.
- [ ] No test is weakened, skipped, or mocked past the behavior under test to
      obtain a pass.
- [ ] `main.tf` declares `required_version = ">= 1.3.0"` and
      `aws version = ">= 6.14.0"` (subject to § 9), each with a one-line comment
      giving the reason, per `AGENTS.md` § 7.
- [ ] `README.md` includes the description, prerequisites, the four usage
      examples in § 4, the design notes (including that the schedule takes no
      tags), and a committed, regenerated `<!-- BEGIN_TF_DOCS -->` block so
      `Verify - terraform-docs` passes.
- [ ] No new Checkov/tfsec suppressions and no inline skip comments; no
      modifications to `modules/aws/iam/role`, `modules/aws/iam/policy`,
      `modules/aws/cloudwatch/event`, `.checkov.yaml`, or any other existing
      file.
- [ ] `tofu fmt -check -diff -recursive` and
      `tofu -chdir=modules/aws/eventbridge_scheduler validate` pass.
