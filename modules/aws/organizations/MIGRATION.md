# Migration Guide: AWS Organizations Modules (v8 → v9)

This is the canonical migration guide for anyone currently calling
[`organization`](organization), [`ou`](ou), and/or [`account`](account) directly. It covers both
migration paths available in this release. Each module's own README also has a focused
"Migration Guide" section; this document is the umbrella reference when you use more than one of
these modules together (the common case) and covers the newly-introduced composed
[`modules/aws/organizations`](.) module, which has no migration guide of its own since it didn't
exist before this release.

Both worked examples below source their map inputs from a YAML file rather than inline HCL — this is
the recommended, best-practice pattern for both paths (see each submodule's README for the rationale),
and it makes the practical difference between the two paths concrete rather than abstract.

## What changed

- [`ou`](ou) and [`account`](account) have **breaking interface changes**: both switched from
  managing a single resource per module call to a map-based input that manages many resources
  (including nested OU hierarchies) per module call. See each module's README for the full field-level
  changes.
- [`organization`](organization) is **unchanged** in this release.
- A new composed [`modules/aws/organizations`](.) module was added, wiring `organization`, `ou`, and
  `account` together behind one set of inputs driven by a single YAML file.

Both migration paths below require **moving Terraform state** rather than letting Terraform
destroy/recreate resources: AWS refuses to delete a non-empty Organizational Unit or a member account
still in the organization, so a plain `terraform apply` against the new interface would fail outright
without `moved` blocks (or manual `terraform state mv`) reconciling your existing state first.

## Choose a path

- **Path A — Keep the modules separate.** Update your `ou`/`account` call sites to the new map
  interface, but keep `organization`, `ou`, and `account` as separate module calls. Choose this if you
  manage these independently, only adopt one or two of the three modules, or want the smallest possible
  diff for this release.
- **Path B — Adopt the composed module.** Replace your separate `organization`/`ou`/`account` module
  calls with one `module "organizations"` block. Choose this if you always use all three together (the
  common case) and want a single YAML-driven module call going forward.

Both paths are one-time state-migration efforts; neither is inherently "safer" than the other from an
AWS-API perspective. Path A is a smaller diff today; Path B removes the manual
`organizational_unit_ids` wiring, lets top-level OUs omit `parent_id` entirely (see the worked example),
and gives you the single-YAML-file experience described in the [composed module's README](README.md).

### Finding your current resource addresses

Before writing `moved` blocks, list your current addresses so you know exactly what you're migrating:

```
terraform state list | grep -E 'aws_organizations_(organization|organizational_unit|account)'
```

---

## Path A: Continue using the individual modules

### 1. `organization` — no changes needed

The `organization` submodule's interface is unchanged in this release, and it isn't map-based (it
manages one Organization, not a collection), so it isn't part of the shared YAML file below — leave
existing calls as-is, with its arguments inline as before.

### 2. `ou` — convert to the map interface

Full step-by-step guide: [`ou/README.md` → Migration Guide](ou/README.md#migration-guide-v8---v9).
Summary:

- Convert each `module "x_ou" { name = ...; parent_id = ... }` block into one entry in a single
  `organizational_units` map on **one** `module` block (recommended name: `organizational_units`),
  ideally sourced from a YAML file (see the worked example below).
- Replace `parent_id = module.<other_ou>.id` with `parent_key = "<other_ou_key>"` for OUs nested under
  another OU created by the same module call. Top-level OUs (parented directly to the org root) must
  still set a literal `parent_id` in Path A — this module has no way to default it on its own.
- Add a `moved` block per existing OU. The destination depends on nesting depth: entries with a literal
  `parent_id` land in `level_0`, entries nested one level deep land in `level_1`, and so on up to
  `level_3`.
- Update references: `module.<x>.id` → `module.organizational_units.ids["<key>"]`,
  `module.<x>.arn` → `.arns["<key>"]`, `module.<x>.accounts` → `.accounts["<key>"]`.

### 3. `account` — convert to the map interface

Full step-by-step guide: [`account/README.md` → Migration Guide](account/README.md#migration-guide-v8---v9).
Summary:

- Convert each `module "x_account" { name = ...; email = ...; parent_id = ... }` block into one entry
  in a single `accounts` map on **one** `module` block (recommended name: `accounts`), ideally sourced
  from the same YAML file as `organizational_units` (see the worked example below).
- Replace `parent_id = module.<ou>.id` with `parent_key = "<ou_key>"`, and pass
  `organizational_unit_ids = module.organizational_units.ids` on the accounts module block.
- Add a `moved` block per existing account.
- Update references: `module.<x>.id` → `module.accounts.ids["<key>"]`, `.arn` → `.arns["<key>"]`,
  `.tags_all` → `.tags_all["<key>"]`.

### Worked example (Path A)

`organization_structure.yaml` — note that the top-level `workloads` OU must set a literal `parent_id`
here; `organization`'s root ID isn't available to a plain YAML file, and this module can't default it
for you the way the composed module can (see the Path B worked example for the difference):

```yaml
# organization_structure.yaml
organizational_units:
  workloads:
    parent_id: r-n1v2
  prod:
    parent_key: workloads

accounts:
  company_ventures:
    email: jdoe@example.com
    parent_key: prod
```

```
module "organization" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/organization"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]
}

locals {
  org_structure = yamldecode(file("${path.module}/organization_structure.yaml"))
}

module "organizational_units" {
  source                = "github.com/zachreborn/terraform-modules//modules/aws/organizations/ou"
  organizational_units  = local.org_structure.organizational_units
}

module "accounts" {
  source                   = "github.com/zachreborn/terraform-modules//modules/aws/organizations/account"
  accounts                 = local.org_structure.accounts
  organizational_unit_ids  = module.organizational_units.ids
}
```

`moved` blocks (add to your consumer configuration, not the module) — these assume you're migrating
directly from the pre-v9 individual-resource-per-module addresses, e.g. `module "workloads_ou"`,
`module "prod_ou"`, and `module "company_ventures"`:

```
moved {
  from = module.workloads_ou.aws_organizations_organizational_unit.this
  to   = module.organizational_units.aws_organizations_organizational_unit.level_0["workloads"]
}

moved {
  from = module.prod_ou.aws_organizations_organizational_unit.this
  to   = module.organizational_units.aws_organizations_organizational_unit.level_1["prod"]
}

moved {
  from = module.company_ventures.aws_organizations_account.account
  to   = module.accounts.aws_organizations_account.this["company_ventures"]
}
```

---

## Path B: Migrate to the composed `organizations` module

This consolidates `organization`, `ou`, and `account` module calls into one `module "organizations"`
block, sourced from a single YAML file. It's a larger one-time diff than Path A, but leaves you with a
single, YAML-driven module call going forward — see the [composed module's README](README.md) for the
full input/output reference.

### 1. Fold `organization`'s settings into the shared YAML file's `organization:` key

Unlike Path A, `organization` settings live in the *same* YAML file as `organizational_units` and
`accounts` here, because the composed module's `organization` variable is a single object with the same
fields as the standalone submodule's variables — it fits the YAML shape naturally.

### 2. Fold `ou` and `account` into the same YAML file

Build the `organizational_units` and `accounts` sections exactly as described in Path A steps 2–3 — the
shape is identical. The only differences: they're top-level keys in the *same* YAML file as
`organization` (rather than a separate file used only by `ou`/`account`), and a top-level OU no longer
needs a literal `parent_id` — leaving it bare (e.g. `workloads:` with nothing after it) attaches it
automatically to the Organization managed by this same module call. Drop any
`organizational_unit_ids = module.organizational_units.ids` wiring you had — the composed module does
this internally.

If you already completed Path A and are now moving to Path B, this step is straightforward: merge your
existing `organizational_units`/`accounts` YAML content into one file alongside a new `organization:`
key, and (optionally) simplify any top-level OUs that now have a literal `parent_id` back down to bare
entries.

### Worked example (Path B)

`organization_structure.yaml` — the same organization, OUs, and account as the Path A example, but as
one file with `organization:` included and `workloads` left bare (no `parent_id` needed):

```yaml
# organization_structure.yaml
organization:
  enabled_policy_types:
    - SERVICE_CONTROL_POLICY
    - TAG_POLICY

organizational_units:
  workloads:
  prod:
    parent_key: workloads

accounts:
  company_ventures:
    email: jdoe@example.com
    parent_key: prod
```

```
locals {
  org_structure = yamldecode(file("${path.module}/organization_structure.yaml"))
}

module "organizations" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/organizations"

  organization          = try(local.org_structure.organization, null)
  organizational_units  = local.org_structure.organizational_units
  accounts              = local.org_structure.accounts
}
```

### 3. Rewrite `moved` blocks to cross into the composed module

Every resource now lives one or two module levels deeper, inside `module.organizations`. The rewrite
rule for each resource type:

- `aws_organizations_organization` (the org resource itself, and everything the `organization`
  submodule creates internally — SCP policies, policy attachments, etc.): prepend
  `module.organizations.module.organization["this"].` to the existing `module.organization.`-prefixed
  address.
- `aws_organizations_organizational_unit`: prepend `module.organizations.module.organizational_units.`
  to the address you'd use in Path A (i.e. `...level_N["<key>"]`).
- `aws_organizations_account`: prepend `module.organizations.module.accounts.` to the address you'd use
  in Path A (i.e. `...aws_organizations_account.this["<key>"]`).

If you already did Path A, this is purely mechanical: take every Path A destination address and prepend
`module.organizations.`. If you're migrating directly from the pre-v9 individual-resource-per-module
addresses, write the `moved` blocks straight to the final Path B address in one hop (no need to pass
through the Path A address as an intermediate step). Continuing the worked example, migrating directly
from the pre-v9 state (`module "organization"`, `module "workloads_ou"`, `module "prod_ou"`,
`module "company_ventures"`):

```
moved {
  from = module.organization.aws_organizations_organization.org
  to   = module.organizations.module.organization["this"].aws_organizations_organization.org
}

moved {
  from = module.workloads_ou.aws_organizations_organizational_unit.this
  to   = module.organizations.module.organizational_units.aws_organizations_organizational_unit.level_0["workloads"]
}

moved {
  from = module.prod_ou.aws_organizations_organizational_unit.this
  to   = module.organizations.module.organizational_units.aws_organizations_organizational_unit.level_1["prod"]
}

moved {
  from = module.company_ventures.aws_organizations_account.account
  to   = module.organizations.module.accounts.aws_organizations_account.this["company_ventures"]
}
```

If you also enabled the `organization` submodule's Identity Center SCP, Region SCP, or organization
backup policy features, apply the same `module.organization.` → `module.organizations.module.organization["this"].`
prefix rewrite to those resources' addresses too (e.g.
`module.organization.module.identity_center_scp["identity_center_scp"].aws_organizations_policy.this` →
`module.organizations.module.organization["this"].module.identity_center_scp["identity_center_scp"].aws_organizations_policy.this`).

### 4. Update downstream references

| Old reference (Path A or pre-v9) | New reference (Path B) |
|---|---|
| `module.organization.id` / `.arn` / `.roots` | `module.organizations.organization.id` / `.arn` / `.roots` |
| `module.organizational_units.ids["<key>"]` | `module.organizations.organizational_unit_ids["<key>"]` |
| `module.organizational_units.arns["<key>"]` | `module.organizations.organizational_unit_arns["<key>"]` |
| `module.organizational_units.accounts["<key>"]` | `module.organizations.organizational_unit_accounts["<key>"]` |
| `module.accounts.ids["<key>"]` | `module.organizations.account_ids["<key>"]` |
| `module.accounts.arns["<key>"]` | `module.organizations.account_arns["<key>"]` |
| `module.accounts.tags_all["<key>"]` | `module.organizations.account_tags_all["<key>"]` |

---

## Which path should I pick?

- Only using `ou` or only using `account` (not both, and not `organization` via this repo)? **Path A**
  — there's no consolidation benefit for a single module.
- Using `organization`, `ou`, and `account` together, and always will? **Path B** — you get the
  single-YAML-file experience (including the org root ID) and automatic `organizational_unit_ids`
  wiring.
- Using `organization`/`ou` here but accounts are vended by a different process (e.g. Control Tower
  Account Factory), or vice versa? **Path A** — the composed module still requires you to supply
  `accounts`/`organizational_units` directly; there's no benefit to routing through it for a partial
  combination.
