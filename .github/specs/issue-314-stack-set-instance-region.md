# Spec: feat(cloudformation/stack_set): add region variable to aws_cloudformation_stack_set_instance
**Issue:** #314
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The `modules/aws/cloudformation/stack_set` module deploys a StackSet
(`aws_cloudformation_stack_set.this`) and a single set of stack instances
(`aws_cloudformation_stack_set_instance.this`, `modules/aws/cloudformation/stack_set/main.tf` (74-83)).
The instance resource does **not** expose any variable for the target deployment
region, so stack instances are always created in the provider's configured
region. This makes it impossible to manage a StackSet whose control-plane region
differs from the instance deployment region — for example, importing an existing
StackSet whose control plane lives in `us-east-1` while its instances are
deployed to `us-west-2`. Without an input for the instance region, using the
module against such a StackSet forces both into the provider's region and
produces destructive drift, so callers must drop down to raw
`aws_cloudformation_stack_set` / `aws_cloudformation_stack_set_instance`
resources instead.

Issue #314 requests exposing this as a `region` input. Triage classified it as a
feature and confirmed it is non-breaking
(https://github.com/zachreborn/terraform-modules/issues/314).

**Important provider nuance (drives the design below).** The module pins
`aws >= 6.0.0` (`modules/aws/cloudformation/stack_set/main.tf:9`). As part of the
v6.0.0 *Enhanced Region Support* release, the AWS provider had to special-case
the handful of resources that already owned a top-level `region` argument.
`aws_cloudformation_stack_set_instance` is one of them: its historical `region`
argument is now **deprecated** in favour of a new, mutually-exclusive
`stack_set_instance_region` argument. The authoritative provider schema
(`internal/service/cloudformation/stack_set_instance.go`) shows:

- `region` — `Optional, Computed, ForceNew`, `ConflictsWith: ["stack_set_instance_region"]`,
  `Deprecated: "region is deprecated. Use stack_set_instance_region instead."`
- `stack_set_instance_region` — `Optional, Computed, ForceNew`,
  `ConflictsWith: ["region"]` (the non-deprecated replacement).
- The resource is annotated `@Region(overrideEnabled=false)`, so the new v6
  provider-level per-resource `region` meta-argument is **not** added here;
  `region` on this resource is exclusively the legacy stack-instance target
  region, not a provider-region override.

At create time the provider resolves the target region in the order
`stack_set_instance_region` → `region` (deprecated) → provider region.

Because the module's minimum supported provider is exactly the release that
introduced `stack_set_instance_region` (v6.0.0) and deprecated `region`, wiring
the new input into the deprecated `region` argument (as the issue body sketches)
would emit a `Deprecated attribute` warning on every plan and is slated for
removal in the next provider major (`v7.0.0`). This spec therefore exposes the
capability through the **non-deprecated** `stack_set_instance_region` argument.

Provider references:
- Resource docs (`region` marked Deprecated; `stack_set_instance_region` is the
  replacement):
  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance
- Schema source (definitive):
  https://github.com/hashicorp/terraform-provider-aws/blob/main/internal/service/cloudformation/stack_set_instance.go
- v6 upgrade guide / Enhanced Region Support (lists
  `aws_cloudformation_stack_set_instance` among the special-cased resources):
  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-6-upgrade

## 2. Non-goals
- **No use of the deprecated `region` argument.** This spec intentionally does
  *not* expose the provider's deprecated `region` argument, nor a module
  variable literally named `region`. The capability is surfaced via
  `stack_set_instance_region` instead (see §4 and the §9 open question that
  records this rename from the issue's wording).
- **No multi-region / list-of-regions input.** The module manages a single
  `aws_cloudformation_stack_set_instance.this`, which targets exactly one
  region. Deploying one StackSet to several regions at once (the provider's
  separate `aws_cloudformation_stack_instances` resource with a `regions` list)
  is out of scope.
- **No `for_each` / map / YAML fan-out** of stack instances. The module remains a
  single-StackSet, single-instance-group module; AGENTS.md's scalable-input
  guidance (§5) targets modules that manage many like resources and is not
  triggered by adding one scalar input here.
- **No broader coverage of other un-exposed instance arguments.** Arguments such
  as `account_id`, `parameter_overrides`, `retain_stack`, `concurrency_mode`, and
  the instance-level `operation_preferences` block remain unexposed; closing the
  remaining coverage gap is a separate effort.
- **No new outputs** and no change to the `aws_cloudformation_stack_set.this`
  control-plane resource or its provider/region configuration.

## 3. Affected module path(s)
- `modules/aws/cloudformation/stack_set/` (existing)
  - `modules/aws/cloudformation/stack_set/variables.tf` — add one variable.
  - `modules/aws/cloudformation/stack_set/main.tf` — wire the variable into
    `aws_cloudformation_stack_set_instance.this`.
  - `modules/aws/cloudformation/stack_set/README.md` — regenerated terraform-docs
    Inputs table (mechanical).

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Add one new variable in the existing `Stack Set Instance Variables` section
(`modules/aws/cloudformation/stack_set/variables.tf` (137-166)):

- **`stack_set_instance_region`**
  - type: `string`
  - default: `null`
  - description: target AWS region in which to create the stack instances; when
    `null` the provider's configured region is used. Wording should note this is
    useful when the StackSet control-plane region differs from the instance
    deployment region, and that it maps to the resource's non-deprecated
    `stack_set_instance_region` argument (the successor to the deprecated
    `region` argument).
  - No `validation` block is required (any partition region string is valid;
    matching the existing free-form string inputs in this module).

All existing variables remain unchanged.

### `outputs.tf`
No changes. The existing outputs (`arn`, `name`, `id`) are unaffected. (The
instance's computed `id` already encodes the resolved region, so no new output
is needed to satisfy this issue.)

### `main.tf`
No blocks are added or removed. Within the existing
`aws_cloudformation_stack_set_instance "this"` resource
(`modules/aws/cloudformation/stack_set/main.tf` (74-83)), add a single argument
assignment:

- `stack_set_instance_region = var.stack_set_instance_region`

Notes for the implementer:
- Wire into `stack_set_instance_region`, **not** the deprecated `region`
  argument (they are mutually exclusive and `region` is deprecated as of the
  module's minimum provider, `aws 6.0.0`).
- The argument is `ForceNew` in the provider, so changing it on an existing
  deployment replaces the stack instance(s). This matches AWS behaviour
  (an instance's region is immutable) and should be called out in the README
  notes, not worked around.
- No `count`/`for_each`, no `dynamic` block, no `lifecycle` change, and no
  tagging change are introduced. The `terraform {}` provider block
  (`>= 6.0.0`) is already sufficient — `stack_set_instance_region` exists across
  the module's entire supported provider range.

## 5. Breaking-change assessment
- Breaking: **no**.
- The new `stack_set_instance_region` variable defaults to `null`. With a `null`
  value the argument is omitted and the provider falls back to the configured
  (provider) region — byte-for-byte identical to today's behaviour. Existing
  callers that do not set the variable see no plan diff and need no changes; no
  state migration is required.
- Setting the variable to a region (e.g. `us-west-2`) on a **new** deployment
  creates the instances in that region. Setting it on an **existing** deployment
  is a deliberate region change and will force replacement of the stack
  instance(s) (provider `ForceNew`); this is inherent to AWS and is not a
  regression introduced by the module.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. Adding a region-targeting input does not introduce
  or alter any security-relevant resource configuration (no encryption,
  networking, IAM, or public-access surface is touched).
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
Yes. The auto-generated `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/cloudformation/stack_set/README.md` gains one row in the **Inputs**
table for `stack_set_instance_region` (name, `string`, default `null`). Per
AGENTS.md, CI (`Verify - terraform-docs`) only *verifies* the committed output
and does **not** auto-commit, so the implementer must regenerate locally
(`pre-commit run --all-files`, or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/cloudformation/stack_set`)
and commit the result. The hand-written usage/notes prose in the README should
also gain a short mention of the new input and its `ForceNew` behaviour.

## 8. Testing
- `tofu -chdir=modules/aws/cloudformation/stack_set init -backend=false && tofu -chdir=modules/aws/cloudformation/stack_set validate`
  (equivalently the `terraform -chdir=... ` forms).
- `tofu fmt -check -diff -recursive` (equivalently `terraform fmt ...`).
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/cloudformation/stack_set`
  and confirm the only README change is the added `stack_set_instance_region`
  Inputs row.
- `checkov -d modules/aws/cloudformation/stack_set` (locally; CI runs on
  schedule) — expect no new findings.
- Manual confirmation:
  - Omitting `stack_set_instance_region` against an existing deployment produces
    **no** plan diff (behaviour unchanged) and **no** `Deprecated attribute`
    warning for the instance region.
  - Setting `stack_set_instance_region = "us-west-2"` plans an instance whose
    resolved region is `us-west-2`.

## 9. Open questions
- **Variable name vs. the issue's wording (recommendation: keep
  `stack_set_instance_region`).** Issue #314 and its accepted acceptance criteria
  name the input `region`. This spec deliberately renames it to
  `stack_set_instance_region` so that (a) it maps 1:1 to the non-deprecated
  provider argument — consistent with this module's existing
  name-equals-argument convention (`region_concurrency_type`, `region_order`,
  `account_filter_type`, etc.), and (b) it avoids colliding with the deprecated
  `region` argument and the provider's broader "enhanced region" `region`
  concept. CODEOWNERS should confirm this rename. If a literal `region` input is
  strongly preferred for ergonomics, the fallback is a `region` *variable* that
  still wires into the `stack_set_instance_region` *argument* (never the
  deprecated `region` argument); exposing both inputs is not recommended because
  the underlying arguments are mutually exclusive.

## 10. Acceptance criteria
- `modules/aws/cloudformation/stack_set/variables.tf` contains a
  `stack_set_instance_region` variable of type `string` with `default = null`
  and a description matching the module's existing style (per the §9 decision;
  this supersedes the issue's literal `region` naming).
- `modules/aws/cloudformation/stack_set/main.tf` wires
  `var.stack_set_instance_region` into the **non-deprecated**
  `stack_set_instance_region` argument of
  `aws_cloudformation_stack_set_instance.this` (the deprecated `region` argument
  is not used).
- A caller that omits `stack_set_instance_region` observes behaviour identical to
  before this change (instances created in the provider region) with no plan diff
  on an existing deployment and no deprecation warning.
- A caller that sets `stack_set_instance_region = "us-west-2"` has its stack
  instance(s) targeted to `us-west-2`.
- `tofu validate` (and `terraform validate`) pass on the module.
- `tofu fmt -check` passes and `modules/aws/cloudformation/stack_set/README.md`
  is regenerated via terraform-docs to include the new input.
- No new Checkov/tfsec suppressions are introduced.
