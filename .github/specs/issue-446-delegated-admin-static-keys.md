# Spec: bug: delegated_admin for_each fails when registering a brand-new account in the same apply
**Issue:** #446
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix
## 1. Background
`modules/aws/organizations/delegated_admin` manages
`aws_organizations_delegated_administrator.this` and today keys its input by AWS
account ID. `variables.tf` declares:
```hcl
variable "delegated_admins" {
  type = map(list(string)) # key = AWS account ID, value = list of service principals
}
```
`main.tf:16-23` flattens that map into the resource `for_each` using the account
ID (the map *key*) as part of the instance key:
```hcl
for_each = merge([
  for account_id, services in var.delegated_admins : {
    for service in services : "${account_id}-${service}" => {
      account_id        = account_id
      service_principal = service
    }
  }
]...)
```
Callers typically supply the map keys as
`module.organizations.account_ids["<key>"]`. When one of those account IDs
belongs to an `aws_organizations_account` created in the *same* plan, its ID is
unknown until apply. Because the unknown value is used as a map **key**,
OpenTofu/Terraform marks the entire `var.delegated_admins` map as "known only
after apply" and fails the whole plan — even entries for accounts that already
exist in state — with:
```
Error: Invalid for_each argument
  ...
  var.delegated_admins is a map of list of string, known only after apply
  ...
When working with unknown values in for_each, it's better to define the map keys
statically in your configuration and place apply-time results only in the map
values.
```
This forces consumers to split "create the account" and "register it as a
delegated administrator" into two separate applies/PRs. The OpenTofu error text
and the issue both point at the fix: key the map by a caller-supplied **static**
logical name and carry the account ID as a **value**, mirroring this repo's own
`modules/aws/organizations/account` module, which keys `accounts` by a static
logical name (`for_each = var.accounts`) rather than by AWS account ID. The
module has **no `tests/` directory** today, so this fix also introduces the
module's first native test coverage per `AGENTS.md` § Module Design
Specifications § 6.
## 2. Non-goals
- No change to the underlying `aws_organizations_delegated_administrator`
  resource behavior or to which service principals AWS permits — only the
  module's input shape and the `for_each` key derivation change.
- Not adding delegated-admin wiring to the composed `modules/aws/organizations`
  module. That module does not call `delegated_admin` today (callers wire it
  themselves); this spec keeps that boundary and only updates the composed
  module's README to cross-reference the corrected usage.
- Not preserving the old `map(list(string))` account-ID-keyed shape via a
  compatibility shim. The interface change is intentional and breaking (see § 5).
- Not adopting the OpenTofu `-exclude=...` two-apply workaround; the goal is a
  single converging plan.
## 3. Affected module path(s)
- `modules/aws/organizations/delegated_admin/` (existing) — `variables.tf`,
  `main.tf`, `outputs.tf`, `README.md`
- `modules/aws/organizations/delegated_admin/tests/` (new) — first native
  `tofu test` suite
- `modules/aws/organizations/README.md` (existing) — cross-reference note only,
  no `.tf` change
## 4. Proposed design
**Signatures only — no full implementations.**
Re-key `delegated_admins` by a caller-supplied static logical name and move the
AWS account ID into each entry's value, so the flattened `for_each` key is fully
resolvable at plan time even when an `account_id` value is unknown until apply.
### `variables.tf`
Replace the `map(list(string))` declaration with a map of objects keyed by a
static logical name:
- `variable "delegated_admins"` — `type = map(object({ account_id = string,
  services = list(string) }))`, `default = {}`, `nullable = false`.
  - Map key: caller-supplied **static** logical name (e.g. the account's
    `organization_structure.yaml`-style key), known at plan time.
  - `account_id`: the target AWS account ID; may be an apply-time value such as
    `module.organizations.account_ids["<key>"]`. Used only as a resource
    argument (a *value*), never as a `for_each` key.
  - `services`: list of service principal names (e.g.
    `"backup.amazonaws.com"`).
  - Description documents the static-key requirement, the two-field object, and
    an example.
  - `validation { ... }` block: each entry's `services` list must be non-empty
    (`length(entry.services) > 0`), with an error message naming the offending
    key. This is the only new validation rule (one `expect_failures` case in
    § 8). No `validation` is added on `account_id` format, because such a check
    would evaluate an apply-time-unknown value and risks reintroducing
    plan-time coupling; account-ID shape is left to AWS to enforce.
### `outputs.tf`
The module currently exposes no outputs. Add outputs surfacing the managed
resource, keyed by the same static logical name (`AGENTS.md` § 1 — surface
attributes worth exposing):
- `output "delegated_administrator_ids"` — map of logical key →
  `aws_organizations_delegated_administrator.this` instance IDs
  (`"<account_id>/<service_principal>"`).
- `output "delegated_administrators"` — map of logical key → the full resource
  object for each instance (exposing `account_id`, `service_principal`, `arn`,
  `name`, `email`, `status`, `joined_method`, `joined_timestamp`,
  `delegation_enabled_date`).
### `main.tf`
- `resource "aws_organizations_delegated_administrator" "this"` — rebuild the
  `for_each` so the instance key is derived from the **static** map key and the
  service principal, and `account_id` is only a value:
  ```hcl
  for_each = merge([
    for admin_key, admin in var.delegated_admins : {
      for service in admin.services : "${admin_key}-${service}" => {
        account_id        = admin.account_id
        service_principal = service
      }
    }
  ]...)
  ```
  `account_id = each.value.account_id` and
  `service_principal = each.value.service_principal` unchanged.
- No lifecycle ignores, tagging, or provider block changes (the resource takes
  no `tags`; the `terraform {}` block with `aws >= 6.0.0` stays as-is).
## 5. Breaking-change assessment
- Breaking: **yes**.
- `var.delegated_admins` changes from `map(list(string))` keyed by account ID to
  `map(object({ account_id = string, services = list(string) }))` keyed by a
  static logical name. Callers must migrate, e.g.:
  ```hcl
  # before
  delegated_admins = {
    (module.organizations.account_ids["backups"]) = ["backup.amazonaws.com"]
  }
  # after
  delegated_admins = {
    backups = {
      account_id = module.organizations.account_ids["backups"]
      services   = ["backup.amazonaws.com"]
    }
  }
  ```
- Existing managed instances change their resource instance keys (from
  `"<account_id>-<service>"` to `"<logical_key>-<service>"`), so applies will
  plan destroy+recreate unless callers add `moved {}` blocks. Because
  `aws_organizations_delegated_administrator` registration is idempotent on
  `(account_id, service_principal)`, the migration guidance in the README should
  recommend `moved {}` blocks (or a targeted state `mv`) to avoid churn. The
  implementation should document this in the module README's migration/notes
  section.
- Conventional Commit type `feat!:` (or `fix!:`) → **MAJOR** release per
  `AGENTS.md` § Release & Tag Strategy.
## 6. Checkov / tfsec considerations
- New suppressions: none.
- Existing suppressions affected: none.
## 7. terraform-docs impact
Yes — `modules/aws/organizations/delegated_admin/README.md`'s
`<!-- BEGIN_TF_DOCS -->` block will change: the `delegated_admins` input row
gains the new object type and `{}` default, and two new rows appear in the
Outputs table (`delegated_administrator_ids`, `delegated_administrators`). The
implementation PR must regenerate docs (pre-commit `terraform_docs` hook or the
per-module `terraform-docs` command) and commit the result so the
`Verify - terraform-docs` CI job passes. The composed
`modules/aws/organizations/README.md` gets a hand-edited cross-reference note
(no `terraform-docs` block change there).
## 8. Testing
- `tofu -chdir=modules/aws/organizations/delegated_admin init -backend=false && tofu -chdir=modules/aws/organizations/delegated_admin validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/organizations/delegated_admin` (locally; CI runs on schedule)
- Native `tofu test` plan (required — `AGENTS.md` § Module Design Specifications
  § 6). The module has no tests today, so the implementation must add a
  `modules/aws/organizations/delegated_admin/tests/` directory. Every `run`
  block uses a `mock_provider "aws"` so `tofu test` runs offline with
  `command = plan`, following
  `modules/aws/organizations/account/tests/validation.tftest.hcl` and
  `modules/aws/organizations/tests/wiring.tftest.hcl`. Required cases:
  - **Valid baseline** — `run "valid_baseline_plans"` with a single entry keyed
    by a static logical name and a known `account_id`. Asserts the plan succeeds
    and `length(aws_organizations_delegated_administrator.this) == 1`.
  - **Static keys independent of account_id (core fix)** —
    `run "instance_keys_are_static"` with two entries, each with multiple
    `services`. Asserts the resource instance keys equal the expected
    `"${logical_key}-${service}"` set (i.e.
    `keys(aws_organizations_delegated_administrator.this)` matches a statically
    computed set) — proving the `for_each` key no longer derives from
    `account_id`.
  - **Mixed known + apply-time-unknown account_id (regression)** —
    `run "mixed_known_and_unknown_account_ids_plans"`. Use a setup/harness
    module under `tests/setup/` that declares a mocked `aws_organizations_account`
    and outputs its `id`; a prior `run "setup" { command = plan; module { source
    = "./setup" } }` block produces that id, which is then passed as one entry's
    `account_id` (alongside a second entry with a static literal `account_id`).
    Asserts the plan succeeds with no `Invalid for_each argument` error and that
    both entries produce instances. If the `mock_provider` renders the mocked
    account `id` known at plan time, the setup module must leave that computed
    attribute un-defaulted so it stays unknown at plan — the unknown-value path
    is the exact condition the bug requires, and this case must fail before the
    fix and pass after it.
  - **`expect_failures` per `validation { ... }` rule** —
    `run "rejects_entry_with_empty_services"` passing an entry whose `services`
    is `[]`, with `expect_failures = [var.delegated_admins]` (exercises the one
    new validation rule).
  - **`for_each` branch coverage** — `run "empty_map_creates_no_instances"`
    leaving `delegated_admins` unset (exercises the new `default = {}`), asserting
    `length(aws_organizations_delegated_administrator.this) == 0`; and a
    multi-service entry in the baseline/static-keys cases above exercises the
    inner `for service in admin.services` flattening (one entry → multiple
    instances).
  - **Output assertions** — assert on every meaningful output: in the baseline,
    `output.delegated_administrator_ids["<key>"]` is non-null and
    `output.delegated_administrators["<key>"].account_id` equals the input
    `account_id`; in the empty-map case both outputs have length 0.
  - **Wiring assertions** — the setup/harness case doubles as a wiring check:
    assert the account `id` produced by the setup module flows into the
    delegated-admin instance's `account_id` (and thus its output), proving the
    parent→value plumbing that a real caller
    (`module.organizations.account_ids[...]`) relies on.
  Do not weaken any assertion, skip a `run` block, or mock away the behavior
  under test to force a pass — every case must exercise real module behavior,
  and the mixed known/unknown case must fail before the fix and pass after it.
## 9. Open questions
- Interface confirmation: this spec recommends the **breaking** static-key
  object shape (`map(object({ account_id, services }))`) rather than the
  non-breaking "document the two-step limitation" alternative the issue also
  allows. The breaking fix satisfies acceptance criterion (1) — single-apply
  registration of a brand-new account — which the doc-only alternative cannot.
  Reviewers should confirm the breaking change (MAJOR bump) is acceptable versus
  documentation-only.
- Migration ergonomics: confirm whether the README should ship copy-pasteable
  `moved {}` guidance (recommended) or whether callers are expected to accept the
  one-time destroy+recreate of delegated-administrator registrations (which is
  idempotent server-side).
## 10. Acceptance criteria
- [ ] Callers can create a new AWS account and register it as an AWS
  Organizations delegated administrator for one or more service principals in
  the same `tofu plan`/`apply`, without hitting `Invalid for_each argument`.
  Native test coverage exercises a `delegated_admins` map mixing a
  statically-known account ID with an `account_id` value known only after apply
  (via a mocked/unknown resource attribute), asserting the plan succeeds.
- [ ] `delegated_admins` is keyed by a caller-supplied static logical name and
  carries the AWS account ID only as a value, so the resource `for_each` key is
  resolvable at plan time.
- [ ] `modules/aws/organizations/delegated_admin/tests/` native `tofu test`
  suite is added and asserts the baseline, static-key, mixed known/unknown,
  validation (`expect_failures`), empty-map branch, output, and wiring cases
  described in § 8 (including a case that fails before the fix and passes after).
- [ ] `modules/aws/organizations/delegated_admin/README.md` documents the new
  input shape, an updated usage example, and migration guidance (`moved {}` /
  state move); `modules/aws/organizations/README.md` cross-references it.
- [ ] `tofu fmt`, `tofu test`, and `terraform-docs` all pass in CI (README
  regenerated and committed).
