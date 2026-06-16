# Spec: bug(aws_backup): Invalid for_each argument in organization_backup_plan module (list(bool) not accepted by OpenTofu 1.10+)
**Issue:** #320
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
The `modules/services/aws_backup` module conditionally instantiates an
organization-wide backup plan via a child module block,
`module "organization_backup_plan"` (`modules/services/aws_backup/main.tf` (273-280)).
That block gates itself with a `for_each` whose expression evaluates to a
`list(bool)`:

```hcl
for_each = var.enable_organization_backup ? [true] : []
```

`for_each` has always required a **map** or a **set of strings**. Historically
OpenTofu/Terraform only enforced this dynamically, so the common path —
`enable_organization_backup = false`, which yields an empty `[]` — slipped
through because an empty collection produced zero instances and was never
type-checked against the element constraint. OpenTofu 1.10.7+ (and Terraform
1.10+) now enforce the `for_each` type **statically**, so the `list(bool)` type
is rejected regardless of the boolean's runtime value. The module therefore
fails `tofu validate` / `tofu plan` for every caller on 1.10+, even with the
feature disabled. Observed error (from the issue):

```
│ Error: Invalid for_each argument
│   on .../modules/services/aws_backup/main.tf line 276, in module "organization_backup_plan":
│  276:   for_each = var.enable_organization_backup ? [true] : []
│ The given "for_each" argument value is unsuitable: the "for_each" argument
│ must be a map, or set of strings, and you have provided a value of type
│ list of bool.
```

Because the type error is raised statically, there is no caller-side workaround
other than pinning to a pre-`v8.19.1` module version; the fix must be made in
the module source. Issue #320 was triaged as a bug with a low breaking-change
risk and proposes replacing the `list(bool)` with a `set(string)`
(https://github.com/zachreborn/terraform-modules/issues/320).

The idiomatic single-instance pattern in Terraform/OpenTofu is a one-element
set keyed by a stable string (`toset(["this"])`), which satisfies the `for_each`
type constraint while preserving the "create zero or one instance" toggle
semantics of `var.enable_organization_backup`. `toset()` is available across the
module's entire supported tool range (`required_version = ">= 1.0.0"`), so no
version-constraint change is needed.

## 2. Non-goals
- **No change to `var.enable_organization_backup`.** Its type (`bool`), default
  (`false`), description, and toggle semantics are unchanged. This is purely a
  fix to the `for_each` *expression* type, not to the input that drives it.
- **No new inputs or outputs.** The module exposes no output referencing
  `module.organization_backup_plan` today, and this spec adds none.
- **No map/YAML fan-out** for multiple organization backup plans. The block
  manages an optional single instance; AGENTS.md's scalable-input guidance (§5)
  targets modules that manage many like resources and is not triggered here.
- **No changes to the child module** `../../aws/organizations/delegated_resource_policy`
  or to its `content` / `tags` inputs.
- **No broader refactor** of the `aws_backup` module (KMS keys, IAM, vaults,
  vault locks, backup plans/selections). Only the one `for_each` expression on
  `module "organization_backup_plan"` is in scope. (No other `count`/`for_each`
  block in this module uses a `list`-typed collection — every other block is a
  plain resource without `for_each`.)

## 3. Affected module path(s)
- `modules/services/aws_backup/` (existing)
  - `modules/services/aws_backup/main.tf` — change the single `for_each`
    expression on `module "organization_backup_plan"` (line 276). No other file
    in the module changes.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes. `enable_organization_backup`
(`modules/services/aws_backup/variables.tf` (204-208)) remains:

- **`enable_organization_backup`** — type `bool`, default `false`, existing
  description retained.

### `outputs.tf`
No changes. No output references `module.organization_backup_plan`
(`modules/services/aws_backup/outputs.tf` exposes only the four vault ARNs), so
the fix has no output surface.

### `main.tf`
No blocks are added or removed. Within the existing
`module "organization_backup_plan"` block
(`modules/services/aws_backup/main.tf` (273-280)), change only the `for_each`
expression so it evaluates to a `set(string)` instead of a `list(bool)`:

- `for_each` — replace `var.enable_organization_backup ? [true] : []` with a
  `set(string)` conditional, e.g.
  `var.enable_organization_backup ? toset(["this"]) : toset([])`.

Notes for the implementer:
- The truthy branch must be a non-empty set of strings (the `"this"` key is the
  conventional single-instance key; any consistent string key is acceptable).
  The falsy branch must be an **empty set** (`toset([])` or `[]` coerced to a
  set), which produces zero instances.
- `source`, `content = file("org_backup_plan.json")`, and `tags = var.tags`
  on the block are unchanged.
- No `count`, no `dynamic` block, no `lifecycle` change, and no tagging change
  are introduced. The `terraform {}` block (`required_version = ">= 1.0.0"`,
  `aws >= 4.0.0`) is unchanged — `toset()` is valid across that whole range.

## 5. Breaking-change assessment
- Breaking: **no** for the default and only currently-functional configuration.
- Default path (`enable_organization_backup = false`): the expression evaluates
  to an empty set, producing zero instances — identical to the prior empty-list
  behaviour. No instances exist before or after, so there is **no** state change
  and **no** migration. This restores `validate`/`plan` for every caller on
  OpenTofu/Terraform 1.10+ with no diff.
- Enabled path (`enable_organization_backup = true`): on 1.10+ the current code
  never plans successfully (the static type error fires before any instance is
  created), so there is no existing 1.10+ state to migrate. The instance key
  after the fix is the string `"this"`
  (`module.organization_backup_plan["this"]`).
- Migration edge case: if any caller managed to deploy an
  `organization_backup_plan` instance under a different instance key on an older
  tool, aligning to the new `"this"` key is a one-time address change, e.g.:

  ```sh
  tofu state mv 'module.<name>.module.organization_backup_plan[<old-key>]' \
                'module.<name>.module.organization_backup_plan["this"]'
  ```

  This is an address-only move (no resource replacement, no AWS-side change).
  Callers on 1.10+ are currently blocked entirely, so in practice this affects
  no functioning 1.10+ deployment.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. The change is a `for_each` collection-type fix and
  touches no security-relevant configuration (no encryption, IAM, networking, or
  public-access surface).
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
No expected change. `terraform-docs` renders the **Modules** table as name +
source + version only and does not encode `count`/`for_each`, so the existing
`organization_backup_plan` row in
`modules/services/aws_backup/README.md` (the `<!-- BEGIN_TF_DOCS -->` block) is
unaffected, and no Inputs/Outputs rows change. Per AGENTS.md, the implementer
should still run terraform-docs
(`pre-commit run --all-files`, or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/services/aws_backup`)
to confirm the committed README is byte-for-byte unchanged, since CI
(`Verify - terraform-docs`) verifies but does not auto-commit.

## 8. Testing
- `tofu -chdir=modules/services/aws_backup init -backend=false && tofu -chdir=modules/services/aws_backup validate`
  (equivalently the `terraform -chdir=...` forms). Must pass on OpenTofu 1.10+,
  which currently fails.
- `tofu fmt -check -diff -recursive` (equivalently `terraform fmt ...`).
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/services/aws_backup`
  and confirm there is **no** resulting diff in the README.
- `checkov -d modules/services/aws_backup` (locally; CI runs on schedule) —
  expect no new findings.
- Manual confirmation:
  - With `enable_organization_backup = false` (default): `validate`/`plan`
    succeed and **no** `organization_backup_plan` instance is planned.
  - With `enable_organization_backup = true`: `validate`/`plan` succeed and
    exactly one `module.organization_backup_plan["this"]` instance is planned.

## 9. Open questions
- **Instance key choice (`"this"`).** This spec recommends the conventional
  `"this"` single-instance key. Any stable string key works; if CODEOWNERS
  prefer a more descriptive key (e.g. `"enabled"`), the only consequence is the
  resulting instance address. Because the enabled path does not function on
  1.10+ today, there is no existing-state cost to choosing the key now.

## 10. Acceptance criteria
- `modules/services/aws_backup/main.tf` line 276 no longer uses a `list(bool)`;
  the `for_each` on `module "organization_backup_plan"` evaluates to a
  `set(string)` (e.g. `toset(["this"])` when enabled, `toset([])` when disabled).
- `tofu validate` and `tofu plan` (and the `terraform` equivalents) succeed on
  OpenTofu/Terraform 1.10+ for the module's default configuration, where they
  previously failed with `Invalid for_each argument`.
- With `enable_organization_backup = false`, no `organization_backup_plan`
  instance is created; with `enable_organization_backup = true`, exactly one is
  created.
- `var.enable_organization_backup` is unchanged (`bool`, default `false`); no
  variables or outputs are added or removed.
- `tofu fmt -check` passes and `modules/services/aws_backup/README.md` is
  unchanged after regenerating terraform-docs.
- No new Checkov/tfsec suppressions are introduced.
