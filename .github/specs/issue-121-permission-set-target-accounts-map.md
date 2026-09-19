# Spec: fix(aws/identity_center/permission_set): type target_accounts as map(string) for plan-time-safe for_each keys
**Issue:** #121
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/identity_center/permission_set` cannot assign a permission set to a
**newly created** AWS account in the same `plan`/`apply`. When a caller passes a
computed account ID (e.g. `module.organization.id` from a net-new
`aws_organizations_account`) into `target_accounts`, planning fails with:

> The `for_each` value depends on resource attributes that cannot be determined
> until apply.

The root cause is the `for_each` **key** derivation in `local.assignments`
(`modules/aws/identity_center/permission_set/main.tf:53-63`). `target_accounts`
is typed `set(string)` (`variables.tf:87-97`) and the account ID is interpolated
directly into the map key:

```hcl
... : "${item.group_name}_${item.account_id}" => item
```

`local.assignments` then drives `aws_ssoadmin_account_assignment.this` via
`for_each` (`main.tf:108-116`). Terraform/OpenTofu require every `for_each` key to
be **known at plan time**. A computed `account_id` makes the key unknown, so the
plan aborts before it can even create the assignment.

The fix proposed in the issue is to stop putting the (possibly unknown) account
ID in the `for_each` key. Re-type `target_accounts` as `map(string)` where the
**key** is a static, caller-defined label (always known at plan time) and the
**value** is the account ID (allowed to be unknown at plan time, because it is
only consumed as the `target_id` *attribute*, not as a key).

**Precedent:** this exact pattern -- static, caller-defined label as the
`for_each` key; a value that may be unknown at plan time consumed only as a
resource *attribute* -- has already shipped in this same module and its
siblings: `permission_set`'s own `group_ids` input (#458), `delegated_admin`'s
`account_key`/`account_ids` split (#449), and the `account`/`ou` map rekey
(#362). This spec applies the established house pattern to `target_accounts`
rather than introducing a new one.

See: https://github.com/zachreborn/terraform-modules/issues/121

## 2. Non-goals
- Adding any account-creation/onboarding resources (e.g.
  `aws_organizations_account`) to this module — it continues to only *assign*
  permission sets to accounts the caller already references.
- Changing any variable other than `target_accounts` (`groups`, `name`,
  `description`, the policy variables, `relay_state`, `session_duration`,
  `group_attribute_path`, `tags` all keep their current contract).
- Changing the *value shape* of any output. `assignment_ids` entries keep
  exactly the same fields (`principal_id`, `principal_type`, `target_id`,
  `target_type`, `permission_set_arn`, `instance_arn`, all parsed from the
  applied resource `id`). Its **map key** does change, as an unavoidable
  consequence of re-keying `local.assignments` -- see the corrected §4
  `outputs.tf` and §5 below; this is no longer a non-goal, since it does not
  hold after #458 (see that section for why).
- Shipping a generic, data-driven `moved` block *inside* the module. `moved`
  requires static, literal addresses and cannot be generated from `for_each`,
  variables, or functions, and the old→new key mapping is caller-specific — so
  the migration is **documented** rather than shipped (see §5).
- Correcting unrelated pre-existing README example issues (e.g.
  `managed_policy_arns` shown as a bare string rather than a `list(string)`).
  Only the `target_accounts` example syntax is updated by this change.

## 3. Affected module path(s)
- `modules/aws/identity_center/permission_set/` (existing) -- primary fix.
- `modules/aws/identity_center/` (existing) -- the parent module added by
  #458 composes `permission_set` via its own `permission_sets` map input.
  That input's `target_accounts` field (`variables.tf`, forwarded unchanged
  in `main.tf`) must be re-typed to `map(string)` in lockstep, or the
  parent's own object-type constraint rejects a caller's re-typed map before
  it ever reaches the submodule.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Re-type the existing required variable; no new variables are added.

- **`target_accounts`**
  - before: `type = set(string)` (required)
  - after: `type = map(string)` (required)
  - description: update to make the contract explicit, e.g.
    `"(Required) Map of AWS accounts to assign the permission set to. The key is a static, caller-defined label (e.g. account name/alias) that must be known at plan time; the value is the AWS account ID, which may be a computed reference (e.g. a newly created account's ID)."`
  - replace the existing list-literal example comment with a `map(string)`
    example (label => account ID).

All other variables in `variables.tf` are unchanged.

The parent `modules/aws/identity_center/variables.tf`'s `permission_sets`
object type has its own inline `target_accounts = set(string)` field (used
purely to forward the value through to the submodule) that must be re-typed
to `map(string)` identically, with a matching description update.

### `outputs.tf`
**Correction (post-#458):** the original "no changes" claim below no longer
holds. PR #458 (merged 2026-07-26, composing `permission_set` as a child
module) changed `assignment_ids` (`outputs.tf:16-28`) to be keyed directly by
the resource's own `for_each` key -- i.e. by `local.assignments`'s key --
instead of re-parsing `split(",", assignment.id)` into a key:

```hcl
value = {
  for key, assignment in aws_ssoadmin_account_assignment.this : key => { ... }
}
```

Re-keying `local.assignments` from `"${group_name}_${account_id}"` to
`"${group_name}_${label}"` (§4 `main.tf`, below) therefore **also** changes
`assignment_ids`'s map key to the new `"${group_name}_${label}"` scheme. The
*value* shape of each entry (`principal_id`, `principal_type`, `target_id`,
`target_type`, `permission_set_arn`, `instance_arn`, still parsed from
`split(",", assignment.id)`) is unchanged. `arn`, `created_date`, `id`,
`group_ids`, and `group_attribute_path` are unaffected. This output-key
change must be folded into the breaking-change assessment (§5) and the
module's README breaking-change note alongside the resource `for_each` key
change -- they are the same change viewed from two places.

### `main.tf`
No new resources, data sources, or child modules. Two edits, both confined to
the `for_each` **key** so account IDs leave the key space:

- `local.assignments` (`main.tf:53-63`): iterate `var.target_accounts` as a map
  (`for label, account_id in var.target_accounts`), carry the `label` (and the
  resolved `account_id`) onto each item, and derive the key from the **label**
  instead of the account ID:
  ```hcl
  ... : "${item.group_name}_${item.label}" => item
  ```
  The per-item object continues to expose `group_name`, `group_id`, and
  `account_id`; a `label` field is added for the key. Update the explanatory
  comment block to match the new key scheme.
- `aws_ssoadmin_account_assignment.this` (`main.tf:108-116`): unchanged in
  shape. It still uses `for_each = local.assignments` and reads
  `target_id = each.value.account_id`. The account ID now lives only in the
  attribute value, which is permitted to be unknown at plan time.

The data sources (`aws_ssoadmin_instances.this`,
`aws_identitystore_group.this` keyed by `var.groups`), the permission-set and
policy-attachment resources, the `tags = merge(...)` handling, and all other
`count`/`for_each` patterns are unchanged.

### Parent module: `modules/aws/identity_center`
`main.tf`'s `permission_sets` module block already forwards
`target_accounts = each.value.target_accounts` verbatim (no interpolation),
so no logic change is needed there -- only the `variables.tf` object-type
field noted above. `outputs.tf`'s `permission_set_assignment_ids` output
forwards the submodule's `assignment_ids` map unchanged, so it inherits the
new `<group_name>_<label>` key automatically with no code change of its own.

## 5. Breaking-change assessment
- Breaking: **yes.**
- The `for_each` key for `aws_ssoadmin_account_assignment.this` changes from
  `"${group_name}_${account_id}"` (e.g. `"admins_123456789012"`) to
  `"${group_name}_${label}"` (e.g. `"admins_organization"`). Terraform/OpenTofu
  key existing instances by the old string, so without a state migration every
  assignment plans as **destroy + create**. Destroying an
  `aws_ssoadmin_account_assignment` revokes the group's access to that account
  until the create completes, so callers must migrate state rather than let the
  resources be recreated.
- Callers must also convert the `target_accounts` argument from a
  set/list literal to a map (label => account ID); the variable is required, so
  this affects **every** caller.
- **Migration (must be documented in the module README):** the module cannot
  ship a generic `moved` block because `moved` requires static, literal
  addresses (no `for_each`/variable/function interpolation) and the old key
  embeds caller-specific account IDs. The README must document, per
  group×account assignment, one of:
  - a caller-authored `moved` block in the root module, e.g.
    ```hcl
    moved {
      from = module.admins_permissions.aws_ssoadmin_account_assignment.this["admins_123456789012"]
      to   = module.admins_permissions.aws_ssoadmin_account_assignment.this["admins_organization"]
    }
    ```
    (note: a `moved` block targeting a resource inside a module must be written
    in that module; if it cannot be expressed from the root, fall back to
    `state mv`), or
  - a `tofu state mv` / `terraform state mv` command mapping each old key to the
    new label-based key (scriptable for many accounts).
- **`assignment_ids` output key also changes** (see corrected §4
  `outputs.tf`): `"${group_name}_${account_id}"` becomes
  `"${group_name}_${label}"` for `permission_set`'s own output and for the
  parent `identity_center` module's pass-through
  `permission_set_assignment_ids` output. Any caller indexing either output
  by the old key must update those references; this is a second, output-facing
  breaking change riding on the same `for_each` re-key, not a new one.
- Scope of in-repo callers: **not none.** A repo-wide search found no
  external `global/` consumers of `target_accounts`, but #458 (merged after
  this spec was drafted) added an in-repo caller: `modules/aws/identity_center`
  composes `permission_set` via `permission_sets`, whose own
  `target_accounts` field must be re-typed identically (see §3). Its
  `README.md` (composed-usage and YAML-file examples) and its
  `tests/permission_sets.tftest.hcl` also use `target_accounts` and must be
  updated in the same change (see §7, §8). External consumers and both
  modules' own README examples are affected; `global/` still does not
  consume either module.

## 6. Checkov / tfsec considerations
- New suppressions: **none.** Re-typing an input variable and changing a
  `for_each` key introduces no security-relevant resource configuration.
- Existing suppressions affected: **none.** `.checkov.yaml` and `.trivyignore`
  are not modified.

## 7. terraform-docs impact
Yes, for **both** affected modules. The auto-generated `<!-- BEGIN_TF_DOCS -->`
block in `modules/aws/identity_center/permission_set/README.md` changes: the
`target_accounts` row in the Inputs table flips its Type from `set(string)` to
`map(string)` and its Description to the updated text; the `assignment_ids`
output row's description text (which documents the key scheme) also updates
to reflect `<group_name>_<label>`. No rows are added or removed; the
Resources table is unaffected.

`modules/aws/identity_center/README.md`'s own `<!-- BEGIN_TF_DOCS -->` block
also changes: the `permission_sets` input's inline object-type description
embeds `target_accounts = set(string)`, which flips to `map(string)`.

Both blocks must be regenerated (`pre-commit run --all-files`, or per-module
`terraform-docs markdown table --output-file README.md --output-mode inject <module_path>`
for each of `modules/aws/identity_center/permission_set` and
`modules/aws/identity_center`) and committed, or the `Verify - terraform-docs`
CI job fails.

Separately, the hand-written usage examples that live **outside** the
`BEGIN_TF_DOCS` markers must be updated by hand to the new `map(string)`
syntax (label => account ID):
- `permission_set/README.md`: the Managed Policy, Customer Managed Policy,
  Inline Policy, and Same-Apply (`group_ids`) examples.
- `identity_center/README.md`: the Composed Usage (`permission_sets`) example
  and the YAML File Input example.
Both READMEs' existing breaking-change notes (documenting the prior
`assignment_ids` key change from #458) should be extended to also cover this
change's key-scheme shift, rather than adding a disconnected second note.

## 8. Testing
- `tofu -chdir=modules/aws/identity_center/permission_set init -backend=false && tofu -chdir=modules/aws/identity_center/permission_set test`
  and the same for `modules/aws/identity_center` (Terraform equivalents also
  acceptable). #458 added native `tests/` directories to both modules after
  this spec was drafted, so `test` (not just `validate`) is now the correct
  offline check -- see below for which fixtures must change.
- `tofu fmt -check -diff -recursive`.
- `checkov -d modules/aws/identity_center/permission_set` and
  `checkov -d modules/aws/identity_center` (locally; CI runs on schedule).
- `pre-commit run --all-files` to confirm terraform-docs is in sync.
- **Existing native test fixtures that must be converted from `set(string)`
  list literals to `map(string)` (label => account ID), including their
  key-based assertions (`"<group>_<account_id>"` -> `"<group>_<label>"`):**
  - `modules/aws/identity_center/permission_set/tests/main.tftest.hcl`
  - `modules/aws/identity_center/permission_set/tests/scale.tftest.hcl`
  - `modules/aws/identity_center/permission_set/tests/validation.tftest.hcl`
  - `modules/aws/identity_center/tests/permission_sets.tftest.hcl`
- **New regression case (one per module)** proving the `for_each`/output key
  is derived from the label and not the account ID: use a
  `target_accounts` map whose label is textually distinct from its account-ID
  value (e.g. `{ prod = "999999999999" }`) and assert the resulting
  `assignment_ids` key is `"<group>_prod"`, not `"<group>_999999999999"`.
  This mirrors how the existing `group_ids` tests prove the analogous
  group-side fix from #458.
- Functional check that the bug is resolved: in a root module, create a net-new
  account (or feed any not-yet-known value) and pass its computed ID as a
  `target_accounts` map **value** with a static label **key**; confirm
  `tofu plan` / `terraform plan` succeeds (no "for_each ... cannot be determined
  until apply" error) in a single plan/apply.
- Migration check: starting from state created by the old `set(string)` key
  scheme, confirm that applying the documented `moved` blocks / `state mv`
  commands results in **no** destroy/create for `aws_ssoadmin_account_assignment.this`.

## 9. Open questions
- Should the README also show a `moved`-block migration snippet, a `state mv`
  snippet, or both? Recommendation: document both, since `moved` inside a
  consumed module can be awkward to express from the root and `state mv` is the
  reliable fallback for bulk migration.
- Should the new description / a `validation` block assert the value looks like a
  12-digit account ID? Recommendation: **do not** add strict format validation,
  to avoid friction with computed values and to keep the change minimal; treat
  as optional only.

## 10. Acceptance criteria
- [ ] `target_accounts` is re-typed from `set(string)` to `map(string)` in
      `permission_set/variables.tf`, with an updated description documenting
      the static-label-key / account-ID-value contract.
- [ ] The parent `identity_center/variables.tf`'s `permission_sets[*].target_accounts`
      field is re-typed to `map(string)` identically.
- [ ] `local.assignments` in `permission_set/main.tf` derives the `for_each`
      key from the map **label** (not the account ID); the account ID is only
      used as the `target_id` attribute on `aws_ssoadmin_account_assignment.this`.
- [ ] `tofu plan` / `terraform plan` succeeds when a new account is created and
      its permission set assigned simultaneously in the same configuration.
- [ ] State migration from the old `"${group_name}_${account_id}"` scheme to the
      new `"${group_name}_${label}"` scheme is documented in the README (caller
      `moved` blocks and/or `state mv`), since the module cannot ship a generic
      `moved` block. The README breaking-change note also documents that
      `assignment_ids` (both `permission_set`'s own and `identity_center`'s
      pass-through `permission_set_assignment_ids`) is keyed by the same new
      scheme.
- [ ] README usage examples in both `permission_set/README.md` and
      `identity_center/README.md` are updated to the new `map(string)` syntax.
- [ ] `terraform-docs` is regenerated for both modules and each
      `<!-- BEGIN_TF_DOCS -->` block reflects the updated `target_accounts`
      type and description.
- [ ] All four existing native test files
      (`permission_set/tests/{main,scale,validation}.tftest.hcl`,
      `identity_center/tests/permission_sets.tftest.hcl`) are converted to
      `map(string)` fixtures with key assertions updated to the new scheme,
      and `tofu test` passes for both modules.
- [ ] At least one new test run per module asserts the `for_each`/output key
      is derived from the label, not the account ID (label textually distinct
      from its account-ID value).
- [ ] `tofu fmt -recursive` passes with no diff.
- [ ] All CI checks pass (`Linter`, `Test OpenTofu`, `Verify - terraform-docs`,
      Invisible Unicode Check).
