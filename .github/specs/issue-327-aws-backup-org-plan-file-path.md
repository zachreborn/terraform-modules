# Spec: bug(aws_backup): Missing org_backup_plan.json asset in v8.20.1 module package causes Invalid function argument on validate
**Issue:** #327
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
The `modules/services/aws_backup` module conditionally instantiates an
organization-wide backup plan through a child module block,
`module "organization_backup_plan"` (`modules/services/aws_backup/main.tf` (273-280)).
That block passes its policy document via:

```hcl
content = file("org_backup_plan.json")
```

Callers consuming the module via `?ref=v8.20.1` report that `tofu validate` /
`tofu plan` fails unconditionally — even with the default
`enable_organization_backup = false` — with:

```
│ Error: Invalid function argument
│   on .terraform/modules/aws_prod_backups/modules/services/aws_backup/main.tf line 278, in module "organization_backup_plan":
│  278:   content = file("org_backup_plan.json")
│ Invalid value for "path" parameter: no file exists at "org_backup_plan.json"; ...
```

The issue (https://github.com/zachreborn/terraform-modules/issues/327) attributes
this to the `org_backup_plan.json` asset being absent from the released package
and proposes bundling it. Investigation shows the premise is **incomplete**, and
there are in fact two distinct defects:

1. **Bare relative path (the reported blocker).** `file()` resolves a relative
   path against the *root module / process working directory*, **not** the child
   module's own directory. To reference a file shipped inside a module you must
   prefix the path with `${path.module}`. Because the call uses the bare path
   `"org_backup_plan.json"`, OpenTofu/Terraform looks for the file in the
   caller's root directory (the Scalr runner's working dir), does not find it,
   and raises `no file exists`. The path argument is a constant, so it is
   evaluated **statically** at validate time regardless of the `for_each` toggle
   added in #320 — hence the failure fires for every caller even when the
   feature is disabled. The file `modules/services/aws_backup/org_backup_plan.json`
   **is** in fact present in the `v8.20.1` tag (verified via
   `git ls-tree -r --name-only v8.20.1`), so "missing from the package" is not
   the true cause; the missing `${path.module}` prefix is.

2. **`org_backup_plan.json` is not valid JSON (latent correctness defect).** The
   file's contents are not a JSON document — they are an HCL expression,
   `jsonencode({ ... })`, containing `${var.*}` interpolations, `$$account`
   placeholders, and references to variables that **do not exist** in this
   module (`var.aws_prod_region`, `var.aws_dr_region`;
   `modules/services/aws_backup/variables.tf` declares no such inputs). `file()`
   returns file contents **verbatim with no interpolation**, so even once the
   path is corrected, enabling `enable_organization_backup = true` would feed an
   uninterpolated `jsonencode(...)` string — not a rendered policy — to
   `aws_organizations_resource_policy.content`
   (`modules/aws/organizations/delegated_resource_policy/main.tf:15`). The file
   is therefore unusable as a `file()` target in its current form; it appears to
   be a `jsonencode({...})` expression that was mistakenly extracted from
   `main.tf` into a `.json` file.

A robust fix must address the reported error (defect 1) and should also resolve
defect 2 so the enabled path produces a valid policy, since shipping a fix that
merely relocates the broken file would leave org-backup callers silently broken
at apply time. The recommended approach removes the `file()` indirection
entirely by rendering the policy inline with `jsonencode(...)`, which both fixes
the path error (no `file()` call remains) and restores interpolation.

This is a continuation of the same upgrade path as #320 (the `for_each`
`list(bool)` fix, resolved in `v8.20.1`); #327 is the next blocker after that.

## 2. Non-goals
- **No change to `var.enable_organization_backup`.** Its type (`bool`), default
  (`false`), description, and toggle semantics are unchanged. This fix targets
  the `content` argument and its source, not the enable toggle (already fixed in
  #320).
- **No change to the `for_each` expression** on
  `module "organization_backup_plan"` — that was addressed by #320 and is out of
  scope here.
- **No changes to the child module**
  `modules/aws/organizations/delegated_resource_policy` or its `content` / `tags`
  inputs. It already accepts an arbitrary policy string.
- **No broader refactor** of the `aws_backup` module (KMS keys, IAM, vaults,
  vault locks, the `aws_backup_plan` / `aws_backup_selection` resources). Only
  the organization-plan policy-document source is in scope.
- **No change to the regional backup behaviour** of the non-organization
  (`aws_backup_plan.plan` / `ec2_plan`) resources.
- **No map/YAML fan-out** for multiple organization backup plans
  (AGENTS.md §5 targets modules managing many like resources; this manages an
  optional single instance).

## 3. Affected module path(s)
- `modules/services/aws_backup/` (existing)
  - `modules/services/aws_backup/main.tf` — replace the `content` argument source
    on `module "organization_backup_plan"` (line 278) and add the supporting
    `locals` / data sources described below.
  - `modules/services/aws_backup/org_backup_plan.json` — **deleted** under the
    recommended design (the broken, non-JSON file is no longer referenced).
  - `modules/services/aws_backup/variables.tf` — only if the optional
    caller-override variable (recommended design, optional addition) is adopted.
  - `modules/services/aws_backup/README.md` — terraform-docs regeneration (see §7).

## 4. Proposed design
**Signatures only — no full implementations.**

### Recommended design: render the policy inline, delete the broken file
Eliminate the `file()` call so there is no path to get wrong and no static
file to keep in sync, and render the org backup policy with `jsonencode(...)`
from variables plus data sources.

#### `variables.tf`
No **required** changes. The existing inputs already supply the policy's
dynamic values:

- **`backup_plan_name`** — `string`, existing default `"prod_backups"`.
- **`hourly_backup_schedule` / `daily_backup_schedule` / `monthly_backup_schedule`**
  — `string`, existing defaults.
- **`hourly_backup_retention` / `daily_backup_retention` / `monthly_backup_retention`
  / `dr_backup_retention`** — `number`, existing defaults.
- **`backup_plan_start_window` / `backup_plan_completion_window`** — `number`,
  existing defaults.
- **`tags`** — `map(any)`, existing default.

Optional (recommended) addition for caller flexibility, kept non-breaking:

- **`organization_backup_plan_content`** — `string`, `default = null`,
  description: "(Optional) A fully-rendered AWS organization backup policy JSON
  document. When null (default), the module generates the policy from the
  schedule/retention inputs." The implementation uses this value when non-null
  and otherwise falls back to the generated `local`.

The previously-referenced but undeclared `var.aws_prod_region` /
`var.aws_dr_region` are **not** added as inputs; regions are derived from the
configured provider aliases via data sources (below) so no new required inputs
are introduced.

#### `outputs.tf`
No required changes. The module currently exposes only the four vault ARNs
(`modules/services/aws_backup/outputs.tf`). Optionally, an output exposing the
organization policy id may be added:

- **`organization_backup_plan_policy_id`** (optional) — the
  `aws_organizations_resource_policy` id from the child module, or `null` when
  `enable_organization_backup = false`. Implementer should guard the reference
  with the `for_each` instance key (`try(module.organization_backup_plan["this"].id, null)`).

#### `main.tf`
- Add data sources (scoped to the existing aliased providers) to supply the
  account id and region values the policy needs:
  - `data "aws_caller_identity" "current"` — `provider = aws.prod_region`
    (replaces the `$$account` placeholder).
  - `data "aws_region" "prod"` — `provider = aws.prod_region` (replaces
    `var.aws_prod_region`).
  - `data "aws_region" "dr"` — `provider = aws.dr_region` (replaces
    `var.aws_dr_region`).
- Add a `locals` block declaring `organization_backup_plan` — a
  `jsonencode({ ... })` of the org backup policy, built from the variables above
  and the data sources. This carries over the structure currently sitting in
  `org_backup_plan.json` (plans → rules → selections → advanced_backup_settings)
  but with real interpolation instead of literal text.
- Change the child module call so `content` references the rendered local
  (or, if the optional override is adopted,
  `coalesce(var.organization_backup_plan_content, local.organization_backup_plan)`):
  ```hcl
  module "organization_backup_plan" {
    source   = "../../aws/organizations/delegated_resource_policy"
    for_each = var.enable_organization_backup ? toset(["this"]) : toset([])

    content = local.organization_backup_plan
    tags    = var.tags
  }
  ```
- Delete `modules/services/aws_backup/org_backup_plan.json`.
- The `for_each` toggle (`toset(["this"]) : toset([])`) and `tags = var.tags` are
  unchanged. No `lifecycle` change and no tagging-pattern change are introduced.
  The `terraform {}` block (`required_version = ">= 1.0.0"`, `aws >= 4.0.0`) is
  unchanged.

### Alternative A (minimal, NOT sufficient alone): fix only the path
Change `file("org_backup_plan.json")` to `file("${path.module}/org_backup_plan.json")`.
This resolves the reported validate/plan error for all callers (the default
disabled path never instantiates the child resource). It does **not** fix
defect 2: enabling org backup would pass uninterpolated `jsonencode(...)` text
to the policy. Acceptable only as a stop-gap if CODEOWNERS explicitly want to
defer the content fix to a follow-up; the recommended design is preferred.

### Alternative B: caller-supplied content only
Replace `file(...)` with a required-or-optional `var.organization_backup_plan_content`
(`string`) and delete the file, with no module-generated default. If the variable
is given a `default` it is non-breaking; making it required would be a breaking
change (see §5). This pushes the policy authoring burden entirely onto callers
and is less convenient than the recommended generated default; it is essentially
the recommended design without the generated `local` fallback.

## 5. Breaking-change assessment
- Breaking: **no** for the default and only currently-functional configuration
  (`enable_organization_backup = false`).
- Default path: today the module fails to `validate`/`plan` for all callers; after
  the fix it succeeds with **zero** `organization_backup_plan` instances — no
  state change, no migration. The `file()` failure that affected every caller is
  removed.
- Enabled path (`enable_organization_backup = true`): the current code cannot
  produce a working policy (either `file()` fails to resolve, or it resolves to
  non-JSON `jsonencode(...)` text referencing undefined variables), so there is no
  functioning deployment to migrate. The recommended design first makes this path
  actually work. The instance key remains `module.organization_backup_plan["this"]`
  (unchanged from #320).
- The optional `organization_backup_plan_content` variable defaults to `null`, so
  adding it is non-breaking. Alternative B is only breaking if the variable is
  made **required**; this spec recommends a default to keep it non-breaking.
- Deleting `org_backup_plan.json` is non-breaking: nothing references the file
  once the recommended design lands (it is consumed only by the `file()` call
  being removed), and it was never independently consumable as JSON.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. The change relocates/regenerates a policy-document
  string and adds read-only `aws_caller_identity` / `aws_region` data sources; it
  touches no encryption, networking, public-access, or IAM-policy-permission
  surface that would trip a new Checkov/tfsec check.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
Expected change is **minimal**:
- The **Modules** table (name + source + version) is unaffected — the
  `organization_backup_plan` row does not encode `count`/`for_each`, `content`,
  or data sources.
- The **Resources** table will gain the new data sources
  (`aws_caller_identity`, two `aws_region`) if terraform-docs is configured to
  list data sources for this module.
- The **Inputs** table changes only if the optional
  `organization_backup_plan_content` variable (and/or the optional output) is
  added.
Per AGENTS.md, the implementer must regenerate docs locally
(`pre-commit run --all-files`, or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/services/aws_backup`)
and commit the result, since CI (`Verify - terraform-docs`) verifies but does
not auto-commit.

## 8. Testing
- `tofu -chdir=modules/services/aws_backup init -backend=false && tofu -chdir=modules/services/aws_backup validate`
  (equivalently the `terraform -chdir=...` forms). Must pass on OpenTofu/
  Terraform 1.10+, where it currently fails with `Invalid function argument`.
- `tofu fmt -check -diff -recursive` (equivalently `terraform fmt ...`).
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/services/aws_backup`
  and commit any resulting README diff.
- `checkov -d modules/services/aws_backup` (locally; CI runs on schedule) —
  expect no new findings.
- Manual confirmation:
  - With `enable_organization_backup = false` (default): `validate`/`plan`
    succeed and **no** `organization_backup_plan` instance is planned, with no
    `file()`/path error.
  - With `enable_organization_backup = true`: `validate`/`plan` succeed, exactly
    one `module.organization_backup_plan["this"]` instance is planned, and its
    `content` is a fully-rendered JSON document with all `var.*` / account / region
    values interpolated (no literal `jsonencode(`, `$$account`, or `${var...}`
    text remaining).

## 9. Open questions
- **Recommended vs. minimal scope.** The recommended design fixes both the path
  error and the broken policy content (and deletes the dead file). If CODEOWNERS
  prefer to ship only the reported validate fix now (Alternative A) and track the
  content/interpolation defect as a separate issue, that is viable but leaves the
  enabled path non-functional. Please confirm scope.
- **Include the optional override variable / output?** The
  `organization_backup_plan_content` input and `organization_backup_plan_policy_id`
  output are proposed as optional, non-breaking additions. Confirm whether to
  include them or keep the change strictly to the bug fix.
- **Policy semantics.** The existing `org_backup_plan.json` content models an AWS
  Organizations *backup policy* document, but the child module manages an
  `aws_organizations_resource_policy` (a delegated resource policy). Confirm the
  intended resource/policy shape so the regenerated `jsonencode(...)` matches the
  child resource's expected schema. (Resolving this does not change the signatures
  above.)

## 10. Acceptance criteria
- `tofu validate` and `tofu plan` (and the `terraform` equivalents) succeed on
  OpenTofu/Terraform 1.10+ for the module's default configuration
  (`enable_organization_backup = false`), where they previously failed with
  `Invalid function argument` / `no file exists at "org_backup_plan.json"`.
- The `content` passed to `module "organization_backup_plan"` no longer depends
  on a bare-relative `file("org_backup_plan.json")` call; under the recommended
  design no `file()` call remains and `org_backup_plan.json` is deleted.
- With `enable_organization_backup = true`, exactly one
  `module.organization_backup_plan["this"]` instance is planned and its `content`
  is a fully-rendered JSON policy with all variable, account-id, and region values
  interpolated (no literal `jsonencode(`, `$$account`, or undefined `var.*`
  references).
- With `enable_organization_backup = false`, no `organization_backup_plan`
  instance is created.
- `var.enable_organization_backup` is unchanged (`bool`, default `false`). Any
  added input (`organization_backup_plan_content`) is optional with a default,
  keeping the change non-breaking; no required inputs are added or removed.
- `tofu fmt -check` passes and `modules/services/aws_backup/README.md` is
  regenerated via terraform-docs and committed.
- No new Checkov/tfsec suppressions are introduced.
