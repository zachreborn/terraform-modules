# Spec: identity_center permission_set group lookup fails when group is created in the same apply
**Issue:** #456
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/identity_center/permission_set/` resolves every entry in
`var.groups` (a `set(string)` of group display names) via a name-based
`aws_identitystore_group` data source lookup. See
`modules/aws/identity_center/permission_set/main.tf:18` for the data source and
`modules/aws/identity_center/permission_set/main.tf:38` for the `assignments`
local that consumes `data.aws_identitystore_group.this[group].group_id`.
That data source calls the real AWS Identity Store `GetGroupId` API during the
**plan** phase, which requires the group to already exist in AWS.
This creates a chicken-and-egg problem. If a caller adds a brand-new group to
their `identity_center` module's `groups` map and, in the same plan/apply, adds
a `permission_set` module call referencing that new group by name, the plan
fails during the data source refresh — before any resource is created — with:
```
Error: reading IdentityStore Group (d-9067aedd5c): operation error identitystore:
GetGroupId, ... ResourceNotFoundException: GROUP not found.
```
There is currently no way to pass an already-known group ID directly; `groups`
only accepts names that must resolve through this eager lookup, forcing callers
into a two-phase apply (create the group first, then reference it in a second
apply).
This is a related symptom class to #121 (same module, "cannot create + assign in
one apply") but a distinct root cause: #121 is a static `for_each`
unknown-until-apply error on `target_accounts`, whereas this is a real AWS API
`400 / ResourceNotFoundException` from an eager data source read. The fix here
is independent of #121 / its spec PR #304.
The fix follows the established alternate-input pattern already used for a
name-vs-ARN lookup in `modules/aws/iam/user_policy_attachment/` (spec #61): add
an optional pre-resolved-ID input that bypasses the data source for the groups
it covers, while leaving the existing name-based path unchanged for
already-existing groups. Callers can then wire a freshly-created group's `id`
output straight into the permission set, so the for_each keys stay statically
known (group name + account ID) while the group ID rides through as a value that
may be known-only-after-apply.
Originating issue: #456.

## 2. Non-goals
- No new module is created. This is an additive enhancement to the existing
  `permission_set` module only.
- Does **not** fix #121's `target_accounts` unknown-until-apply for_each issue;
  that is tracked separately (spec PR #304).
- Does **not** change or remove the existing name-based `groups` lookup path;
  callers who pass names for already-existing groups are unaffected.
- Does **not** add group *creation* to this module — group lifecycle stays in
  the caller's `identity_center` / `group` module. This spec only lets a caller
  hand an already-known (or same-apply-created) group ID to the permission set.
- No change to the `target_accounts`, `managed_policy_arns`, `inline_policy`,
  or customer-managed-policy contracts.

## 3. Affected module path(s)
- `modules/aws/identity_center/permission_set/` (existing)
  - `variables.tf` — make `groups` optional (default `[]`); add `group_ids`.
  - `main.tf` — filter the data source `for_each` to names not already provided
    via `group_ids`; add a local that merges looked-up IDs with `group_ids`;
    rewire the `assignments` local to consume the merged map.
  - `outputs.tf` — add a resolved group-ID map output (additive).
  - `README.md` — document the new input and the same-apply usage pattern;
    regenerate the auto-generated terraform-docs block.
  - `tests/` — new directory of native `tofu test` files (module currently has
    none).

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
- `groups`
  - type: `set(string)`
  - default: `[]` (changed from required to optional)
  - description: group display names to resolve via the `aws_identitystore_group`
    data source and associate with the permission set. Names supplied here must
    already exist in AWS Identity Store at plan time. Keys present in
    `group_ids` are resolved from that map instead and skipped here.
- `group_ids` (new)
  - type: `map(string)`
  - default: `{}`
  - description: pre-resolved Identity Store group IDs keyed by the same logical
    group name used in `groups` / the assignment keys. Use this to bypass the
    name-based data source lookup entirely — e.g. pass a group's `id` output so
    a new group and its permission set can be created in one apply. Values may be
    known-only-after-apply.
  - validation: every value must be a non-empty string (rejects `""`).

### `outputs.tf`
- `arn` — unchanged (permission set ARN).
- `created_date` — unchanged.
- `id` — unchanged (permission set ID).
- `assignment_ids` — unchanged (map of account-assignment IDs + parsed fields).
- `group_ids` (new, additive) — the effective resolved group-name → group-ID map
  actually used for assignments (the merge of looked-up IDs and the `group_ids`
  input), so callers can confirm which ID each group name resolved to.

### `main.tf`
- `terraform {}` block — unchanged (`required_version = ">= 1.0.0"`,
  `aws >= 6.0.0`).
- `data "aws_ssoadmin_instances" "this"` — unchanged.
- `data "aws_identitystore_group" "this"` — `for_each` narrowed from
  `var.groups` to only the names **not** present in `keys(var.group_ids)`
  (e.g. `toset([for g in var.groups : g if !contains(keys(var.group_ids), g)])`),
  so any group covered by `group_ids` is never looked up via `GetGroupId`. The
  `alternate_identifier { unique_attribute { ... } }` body and
  `var.group_attribute_path` usage are unchanged.
- `locals` — new `group_id_map` merging the looked-up IDs
  (`{ for g, d in data.aws_identitystore_group.this : g => d.group_id }`) with
  `var.group_ids` (the input taking precedence for overlapping keys). The
  existing `assignments` local is rewired to iterate `keys(local.group_id_map)`
  × `var.target_accounts` and read the group ID from `local.group_id_map[group]`
  instead of `data.aws_identitystore_group.this[group].group_id`. Assignment map
  keys (`"${group_name}_${account_id}"`) remain statically known.
- `resource "aws_ssoadmin_permission_set" "this"` — unchanged; keeps the
  `merge(var.tags, { "Name" = var.name })` tagging pattern.
- `resource "aws_ssoadmin_customer_managed_policy_attachment" "this"` —
  unchanged (`count` conditional).
- `resource "aws_ssoadmin_managed_policy_attachment" "this"` — unchanged
  (`for_each` over `managed_policy_arns`).
- `resource "aws_ssoadmin_permission_set_inline_policy" "this"` — unchanged
  (`count` conditional).
- `resource "aws_ssoadmin_account_assignment" "this"` — unchanged structurally;
  `principal_id` continues to come from `each.value.group_id`, which now flows
  from `local.group_id_map`.

## 5. Breaking-change assessment
- Breaking: **no.**
- `groups` moves from required to optional (`[]` default); existing callers that
  pass `groups` continue to work identically. `group_ids`, the narrowed data
  source `for_each`, and the new output are purely additive. A group name absent
  from `group_ids` still resolves exactly as before.
- Bump type: **PATCH** (`fix:` per Conventional Commits) — resolves a reported
  bug via an additive, non-breaking input. (If CODEOWNERS prefer to classify the
  new input as a feature, `feat:` / MINOR is also defensible; the change is
  non-breaking either way.)

## 6. Checkov / tfsec considerations
- New suppressions: **none.** Adding an optional map variable, narrowing an
  existing data source's `for_each`, and adding a local/output introduce no new
  findings that require suppression.
- Existing suppressions affected: **none.**

## 7. terraform-docs impact
Yes — the `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/identity_center/permission_set/README.md` will change:
- Inputs: `groups` becomes optional (Required `no`, Default `[]`); add
  `group_ids` (map, default `{}`).
- Outputs: add `group_ids`.
The hand-written usage example above the docs block will also gain a snippet
showing the same-apply pattern (passing a group's `id` output into `group_ids`).
Docs must be regenerated locally (pre-commit or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/identity_center/permission_set`);
CI only verifies the committed output.

## 8. Testing
- `tofu -chdir=modules/aws/identity_center/permission_set init -backend=false && tofu -chdir=modules/aws/identity_center/permission_set validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/identity_center/permission_set` (locally; CI runs on schedule)
- `pre-commit run --all-files` (fmt + terraform-docs hooks green)
- Native `tofu test` plan (required — `AGENTS.md` § Module Design Specifications
  § 6). The module currently has **no** `tests/` directory; the implementation
  must add one. All cases run offline via `mock_provider "aws"` with `mock_data`
  for `aws_ssoadmin_instances` and `aws_identitystore_group`, and `mock_resource`
  for the SSO resources. Because `aws_ssoadmin_account_assignment.id` is a
  comma-delimited composite that `outputs.tf` parses via `split(",", id)`, the
  mock for that resource must supply an `id` in the
  `principal,GROUP,account,AWS_ACCOUNT,ps_arn,instance_arn` shape so the
  `assignment_ids` output evaluates. Cases (`tests/*.tftest.hcl`):
  - **`validation.tftest.hcl`**
    - `valid_baseline_name_lookup_plans` — `groups` set, `group_ids` empty,
      valid `name`/`target_accounts`; asserts the plan succeeds (covers the
      existing happy path and the `groups` default no longer being required).
    - `rejects_empty_group_id_value` — `group_ids = { readonly = "" }`;
      `expect_failures = [var.group_ids]` (the one `validation {}` rule on
      `group_ids`).
  - **`main.tftest.hcl`** (conditional / `for_each` branch coverage)
    - `name_lookup_branch_reads_data_source` — `groups = ["existing"]`,
      `group_ids = {}`; assert
      `length(data.aws_identitystore_group.this) == 1` and
      `length(aws_ssoadmin_account_assignment.this)` equals
      `groups × target_accounts` (data source path exercised).
    - `group_ids_branch_bypasses_data_source` — `groups = []`,
      `group_ids = { readonly = "94481408-...-mockid" }`; assert
      `length(data.aws_identitystore_group.this) == 0` (no `GetGroupId`) and
      that the assignment set is built from `group_ids` — i.e.
      `length(aws_ssoadmin_account_assignment.this) == length(var.target_accounts)`.
      This case is the regression proof for the issue.
    - `mixed_groups_and_group_ids` — one name in `groups`, one different key in
      `group_ids`; assert `length(data.aws_identitystore_group.this) == 1` (only
      the un-provided name is looked up) and the assignment count equals
      `(count(groups) + count(group_ids)) × count(target_accounts)`.
    - `managed_policy_and_inline_and_customer_managed_toggles` — exercise both
      sides of the `count`/`for_each` toggles for
      `aws_ssoadmin_managed_policy_attachment` (empty vs non-empty
      `managed_policy_arns`), `aws_ssoadmin_permission_set_inline_policy`
      (`inline_policy` null vs set), and
      `aws_ssoadmin_customer_managed_policy_attachment`
      (`customer_managed_iam_policy_name` null vs set), asserting the resulting
      instance counts (`0` vs `N`).
  - **Output assertions** — assert `aws_ssoadmin_permission_set.this.name ==
    var.name`, that `output.group_ids` contains the expected group→ID entries
    (equality against the injected `group_ids` value for the bypass case, and
    non-null for the mocked-lookup case), and that `output.assignment_ids` has
    the expected number of entries.
  - No submodule wiring tests are required: `permission_set` is a leaf module
    that calls no child modules.
  Do not weaken any assertion, delete/skip a `run` block, or mock away the exact
  behavior under test to force a pass. A failing case means a real bug in
  `main.tf` / `variables.tf` / `outputs.tf` — fix the root cause and re-run
  `tofu test` until every case passes for the right reason.

## 9. Open questions
- Should the `group_ids` map key be the group **display name** (the same token
  used in `groups` and in the `"${group_name}_${account_id}"` assignment keys)?
  Default recommendation: **yes**, keep keys consistent with `groups` so
  assignment keys and the `assignment_ids` output remain stable regardless of
  which path resolved a given group.
- If the same key appears in both `groups` and `group_ids`, `group_ids` wins and
  the data source lookup is skipped for it. Default recommendation: accept this
  precedence and document it, rather than adding a cross-variable `precondition`
  to reject the overlap.
- Should `groups` and `group_ids` being simultaneously empty (a permission set
  with zero account assignments) be rejected? Default recommendation: **no** —
  it is already possible today with an empty `groups` set, and a policy-only
  permission set is a legitimate configuration.

## 10. Acceptance criteria
- [ ] A new Identity Center group and a `permission_set` module call referencing
  it can be created together in a single `tofu apply` by passing the group's
  `id` into the new `group_ids` input — no plan-time
  `GetGroupId` / `ResourceNotFoundException`.
- [ ] `group_ids` input variable added: type `map(string)`, default `{}`, with a
  clear description and a `validation` rejecting empty-string values.
- [ ] `groups` changed to optional (default `[]`); existing name-based lookup
  behavior for already-existing groups is unchanged (no breaking change for
  current callers).
- [ ] The `aws_identitystore_group.this` data source `for_each` is narrowed so
  that names present in `group_ids` are **not** looked up via the AWS API.
- [ ] A local merges looked-up IDs with `group_ids` (input takes precedence) and
  the `assignments` local consumes the merged map; assignment map keys remain
  statically known.
- [ ] `group_ids` output added exposing the effective resolved group-name → ID
  map.
- [ ] A `tests/` directory is added with the native `tofu test` cases listed in
  § 8, all passing offline (`tofu init -backend=false && tofu test`), including
  the regression case proving the `group_ids` path reads zero
  `aws_identitystore_group` data sources.
- [ ] `README.md` updated with the same-apply usage example and regenerated
  terraform-docs block; if a two-phase apply remains required for the pure
  name-lookup path, that constraint is documented.
- [ ] `tofu fmt -recursive` passes with no diff.
- [ ] `tofu -chdir=modules/aws/identity_center/permission_set init -backend=false && tofu -chdir=modules/aws/identity_center/permission_set validate` passes.
- [ ] `pre-commit run --all-files` passes (fmt + terraform-docs hooks green).

Co-Authored-By: Oz <oz-agent@warp.dev>
