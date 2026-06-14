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
(`modules/aws/identity_center/permission_set/main.tf:44-54`). `target_accounts`
is typed `set(string)` (`variables.tf:65-75`) and the account ID is interpolated
directly into the map key:

```hcl
... : "${item.group_name}_${item.account_id}" => item
```

`local.assignments` then drives `aws_ssoadmin_account_assignment.this` via
`for_each` (`main.tf:99-107`). Terraform/OpenTofu require every `for_each` key to
be **known at plan time**. A computed `account_id` makes the key unknown, so the
plan aborts before it can even create the assignment.

The fix proposed in the issue is to stop putting the (possibly unknown) account
ID in the `for_each` key. Re-type `target_accounts` as `map(string)` where the
**key** is a static, caller-defined label (always known at plan time) and the
**value** is the account ID (allowed to be unknown at plan time, because it is
only consumed as the `target_id` *attribute*, not as a key).

See: https://github.com/zachreborn/terraform-modules/issues/121

## 2. Non-goals
- Adding any account-creation/onboarding resources (e.g.
  `aws_organizations_account`) to this module — it continues to only *assign*
  permission sets to accounts the caller already references.
- Changing any variable other than `target_accounts` (`groups`, `name`,
  `description`, the policy variables, `relay_state`, `session_duration`,
  `group_attribute_path`, `tags` all keep their current contract).
- Changing the shape of any output. In particular, the `assignment_ids` output
  key scheme (`"${principal_id}_${target_id}"`, derived from the applied
  resource `id`) is intentionally **not** changed (see §4 `outputs.tf`).
- Shipping a generic, data-driven `moved` block *inside* the module. `moved`
  requires static, literal addresses and cannot be generated from `for_each`,
  variables, or functions, and the old→new key mapping is caller-specific — so
  the migration is **documented** rather than shipped (see §5).
- Correcting unrelated pre-existing README example issues (e.g.
  `managed_policy_arns` shown as a bare string rather than a `list(string)`).
  Only the `target_accounts` example syntax is updated by this change.

## 3. Affected module path(s)
- `modules/aws/identity_center/permission_set/` (existing)

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

### `outputs.tf`
No changes. `assignment_ids` (`outputs.tf:16-28`) derives its map key and fields
by `split(",", assignment.id)` on the **applied** resource ID, so it remains
keyed by `"${principal_id}_${target_id}"` and is independent of the
`local.assignments` key. `arn`, `created_date`, and `id` are likewise unchanged.

### `main.tf`
No new resources, data sources, or child modules. Two edits, both confined to
the `for_each` **key** so account IDs leave the key space:

- `local.assignments` (`main.tf:44-54`): iterate `var.target_accounts` as a map
  (`for label, account_id in var.target_accounts`), carry the `label` (and the
  resolved `account_id`) onto each item, and derive the key from the **label**
  instead of the account ID:
  ```hcl
  ... : "${item.group_name}_${item.label}" => item
  ```
  The per-item object continues to expose `group_name`, `group_id`, and
  `account_id`; a `label` field is added for the key. Update the explanatory
  comment block to match the new key scheme.
- `aws_ssoadmin_account_assignment.this` (`main.tf:99-107`): unchanged in shape.
  It still uses `for_each = local.assignments` and reads
  `target_id = each.value.account_id`. The account ID now lives only in the
  attribute value, which is permitted to be unknown at plan time.

The data sources (`aws_ssoadmin_instances.this`,
`aws_identitystore_group.this` keyed by `var.groups`), the permission-set and
policy-attachment resources, the `tags = merge(...)` handling, and all other
`count`/`for_each` patterns are unchanged.

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
- Scope of in-repo callers: **none.** A repo-wide search found references to
  `target_accounts` and this module path only within the module's own
  `main.tf`, `variables.tf`, and `README.md`; `global/` does not consume it. The
  breaking change therefore affects external consumers and the module's own
  README examples only.

## 6. Checkov / tfsec considerations
- New suppressions: **none.** Re-typing an input variable and changing a
  `for_each` key introduces no security-relevant resource configuration.
- Existing suppressions affected: **none.** `.checkov.yaml` and `.trivyignore`
  are not modified.

## 7. terraform-docs impact
Yes. The auto-generated `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/identity_center/permission_set/README.md` changes: the
`target_accounts` row in the Inputs table flips its Type from `set(string)` to
`map(string)` and its Description to the updated text. No rows are added or
removed; the Resources and Outputs tables are unaffected. The block must be
regenerated (`pre-commit run --all-files`, or the per-module
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/identity_center/permission_set`)
and committed, or the `Verify - terraform-docs` CI job fails.

Separately, the hand-written usage examples in the README (the Managed Policy,
Customer Managed Policy, and Inline Policy blocks, which currently pass
`target_accounts` as a list literal) live **outside** the `BEGIN_TF_DOCS`
markers and must be updated by hand to the new `map(string)` syntax (label =>
account ID).

## 8. Testing
- `tofu -chdir=modules/aws/identity_center/permission_set init -backend=false && tofu -chdir=modules/aws/identity_center/permission_set validate`
  (Terraform equivalents also acceptable).
- `tofu fmt -check -diff -recursive`.
- `checkov -d modules/aws/identity_center/permission_set` (locally; CI runs on
  schedule).
- `pre-commit run --all-files` to confirm terraform-docs is in sync.
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
      `variables.tf`, with an updated description documenting the
      static-label-key / account-ID-value contract.
- [ ] `local.assignments` in `main.tf` derives the `for_each` key from the map
      **label** (not the account ID); the account ID is only used as the
      `target_id` attribute on `aws_ssoadmin_account_assignment.this`.
- [ ] `tofu plan` / `terraform plan` succeeds when a new account is created and
      its permission set assigned simultaneously in the same configuration.
- [ ] State migration from the old `"${group_name}_${account_id}"` scheme to the
      new `"${group_name}_${label}"` scheme is documented in the README (caller
      `moved` blocks and/or `state mv`), since the module cannot ship a generic
      `moved` block.
- [ ] README usage examples are updated to the new `map(string)` syntax.
- [ ] `terraform-docs` is regenerated and the `<!-- BEGIN_TF_DOCS -->` block
      reflects the updated `target_accounts` type and description.
- [ ] `tofu fmt -recursive` passes with no diff.
- [ ] All CI checks pass (`Linter`, `Test OpenTofu`, `Verify - terraform-docs`,
      Invisible Unicode Check).
