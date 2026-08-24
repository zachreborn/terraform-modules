# Spec: feat(aws/ram): support list of resource ARNs for multi-resource shares
**Issue:** #442
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The `modules/aws/ram/` module wraps a single AWS RAM share. Today it accepts a
single `resource_arn` (`string`) and declares a single
`aws_ram_resource_association.this` resource, so each share can distribute
exactly one resource. When operators need to share several resources org-wide
(e.g. the `zpa-app-connectors` and `cisco-switches` managed prefix lists), they
must instantiate the module once per resource, producing multiple RAM shares
and extra management overhead.

AWS RAM natively supports multiple `aws_ram_resource_association` records per
share. This spec exposes that at the module level by replacing the scalar
`resource_arn` input with a `resource_arns` (`list(string)`) input driving a
`for_each` over the association resource, so one share can be the authoritative
org-wide distribution point for many resources. See issue #442 for the
originating discussion and the `aws_prod_opstooling` real-world use case (two
prefix-list shares consolidated into one via a `moved` block, with no resource
recreation).

## 2. Non-goals
- No change to `aws_ram_resource_share.this` or its inputs
  (`allow_external_principals`, `name`, `permission_arns`, `tags`).
- No change to `aws_ram_principal_association.this` or the `principal` /
  organization-ARN fallback behaviour.
- No new outputs beyond what is required to expose the now-multiple
  associations (see § 4).
- No backward-compatibility shim preserving the old `resource_arn` name; the
  rename is intentional and breaking (see § 5).
- No authoring of the caller-side `moved` blocks for downstream consumers such
  as `aws_prod_opstooling`; that migration lives with the caller, not this
  module.

## 3. Affected module path(s)
- `modules/aws/ram/` (existing) — `main.tf`, `variables.tf`, `outputs.tf`,
  `README.md`, and a new `tests/` directory.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Remove:
- `resource_arn` (`string`, required) — deleted.

Add:
- `resource_arns` — `list(string)`, required. Description: "List of resource
  ARNs to associate with the resource share." No default (caller must supply at
  least one ARN for a share to be meaningful).

Unchanged:
- `allow_external_principals` — `bool`, default `false`.
- `name` — `string`, required.
- `permission_arns` — `list(string)`, default `null`.
- `principal` — `string`, default `null`.
- `tags` — `map(string)`, existing default map.

No `validation { ... }` block is planned for `resource_arns` (an empty list is a
legal, if unusual, input that simply produces zero associations; ARN-format
validation is left to the provider). See § 8 for the consequence on the test
plan.

### `outputs.tf`
Unchanged:
- `arn` — the ARN of the resource share (`aws_ram_resource_share.this.arn`).
- `id` — the ID of the resource share (`aws_ram_resource_share.this.id`).

Add:
- `resource_association_ids` — the IDs of the created
  `aws_ram_resource_association.this` instances, expressed as a map keyed by
  resource ARN (`{ for k, v in aws_ram_resource_association.this : k => v.id }`).
  This surfaces the now-multiple associations so callers can reference them and
  so tests can assert per-ARN wiring.

### `main.tf`
- `terraform {}` block — unchanged (`required_version >= 1.0.0`,
  `aws >= 6.0.0`).
- `data "aws_organizations_organization" "current_org"` — unchanged; still backs
  the principal fallback.
- `resource "aws_ram_resource_share" "this"` — unchanged.
- `resource "aws_ram_resource_association" "this"` — gains
  `for_each = toset(var.resource_arns)`; `resource_arn = each.value` and
  `resource_share_arn = aws_ram_resource_share.this.arn`. This converts the
  block from a single instance to a keyed set.
- `resource "aws_ram_principal_association" "this"` — unchanged; still uses the
  `var.principal != null ? var.principal :
  data.aws_organizations_organization.current_org.arn` fallback.

No tagging-pattern change is required (only the share resource is tagged, and
that is unchanged). No lifecycle ignores are introduced.

## 5. Breaking-change assessment
- Breaking: **yes**.
- The required input `resource_arn` (`string`) is renamed to `resource_arns`
  (`list(string)`). Every caller of `modules/aws/ram/` must update their module
  block. Migration is mechanical: `resource_arn = module.foo.arn` becomes
  `resource_arns = [module.foo.arn]`.
- Because the association resource changes from a single instance
  (`aws_ram_resource_association.this`) to a `for_each` set
  (`aws_ram_resource_association.this["<arn>"]`), callers who wish to avoid
  destroy/recreate of the existing association must add a `moved` block in their
  own configuration, e.g.:
  ```hcl
  moved {
    from = module.example.aws_ram_resource_association.this
    to   = module.example.aws_ram_resource_association.this["arn:aws:...:resource"]
  }
  ```
  The module itself does not ship these `moved` blocks because the target key is
  caller-specific.
- Per `AGENTS.md` § Release & Tag Strategy, this must land as a `feat!:` /
  `BREAKING CHANGE:` commit so release-please cuts a **MAJOR** version bump.

## 6. Checkov / tfsec considerations
- New suppressions: none. Converting a single association to a `for_each` set
  introduces no new security-relevant surface; `allow_external_principals`
  already defaults to `false`.
- Existing suppressions affected: none (the module currently has no inline
  suppressions).

## 7. terraform-docs impact
Yes. The `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/ram/README.md` will
change:
- The `resource_arn` input row is removed and a `resource_arns`
  (`list(string)`, required) row is added.
- A new `resource_association_ids` output row is added.
- The hand-written "Simple Example" usage block above the generated section
  must be updated to `resource_arns = [module.transit_gateway.arn]` and should
  gain a multi-resource example (e.g. two managed-prefix-list ARNs in one
  share). Regenerate with `terraform-docs` via pre-commit (or the per-module
  command in `AGENTS.md`) and commit the result.

## 8. Testing
- `tofu -chdir=modules/aws/ram init -backend=false && tofu -chdir=modules/aws/ram validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/ram` (locally; CI runs on schedule)
- Native `tofu test` plan (required — see `AGENTS.md` § Module Design
  Specifications § 6, Native Test Coverage). The module currently ships **no**
  `tests/` directory; the implementation must add one (start from
  `modules/module_template/tests/`). All cases must run offline via
  `mock_provider` / `mock_resource` for `aws_ram_resource_share`,
  `aws_ram_resource_association`, `aws_ram_principal_association`, and the
  `aws_organizations_organization` data source, following the
  `modules/aws/organizations/tests/` pattern. Required `run` blocks:
  - **Valid baseline (single ARN)** — `command = plan` with `name` and a
    single-element `resource_arns`. Assert `output.arn` / `output.id` are
    non-null, `length(aws_ram_resource_association.this) == 1`, and
    `length(output.resource_association_ids) == 1`.
  - **Multiple ARNs (`for_each` fan-out)** — `resource_arns` with two or more
    distinct ARNs. Assert
    `length(aws_ram_resource_association.this) == length(var.resource_arns)`,
    that each supplied ARN is a key of `output.resource_association_ids`, and
    that each association's `resource_arn` equals its map key.
  - **Empty list (`for_each` zero branch)** — `resource_arns = []`. Assert
    `length(aws_ram_resource_association.this) == 0` and
    `length(output.resource_association_ids) == 0` while the share itself
    (`output.arn`) still plans successfully.
  - **Principal fallback branch (unset)** — `principal = null`. Assert the
    `aws_ram_principal_association.this` principal resolves to the mocked
    organization ARN.
  - **Principal explicit branch (set)** — `principal` set to an explicit ARN.
    Assert the `aws_ram_principal_association.this` principal equals the
    supplied value (exercises the other side of the `var.principal != null`
    conditional).
  - `expect_failures` cases: **none** — no `validation { ... }` rules are
    planned for this module (see § 4). If the implementer adds a validation
    block (e.g. non-empty `resource_arns`), they must add one valid-baseline
    case plus one `expect_failures = [var.resource_arns]` case per rule.
  - Wiring assertions: not applicable — this module calls no submodules; all
    resources are declared inline.
  Do not weaken any assertion, delete a `run` block, or mock away the behaviour
  under test to force a pass. A failing case signals a real bug in the module
  code — fix the root cause and re-run `tofu test` until every case passes for
  the right reason.

## 9. Open questions
- Should the `resource_association_ids` output be keyed by ARN (proposed) or a
  plain list of IDs? Keyed-by-ARN is proposed because it makes per-resource
  references and test assertions unambiguous; reviewers may prefer a simple
  list. Resolvable before merge.
- Should a `validation` block enforce a non-empty `resource_arns`? Proposed
  answer is no (an empty share is legal and the test plan covers the zero
  branch), but reviewers may want to require at least one ARN. Resolvable before
  merge.

## 10. Acceptance criteria
- [ ] `variable "resource_arn"` is removed and replaced with
  `variable "resource_arns"` of type `list(string)`.
- [ ] `aws_ram_resource_association.this` uses `for_each = toset(var.resource_arns)`
  with `resource_arn = each.value`.
- [ ] A `resource_association_ids` output exposes the created associations.
- [ ] `tofu -chdir=modules/aws/ram validate` passes and `tofu fmt` is clean.
- [ ] A `tests/` directory is added covering the § 8 cases and passes offline
  via `tofu init -backend=false && tofu test`.
- [ ] `README.md` usage example is updated to the list syntax (single- and
  multi-resource examples) and the `terraform-docs` block is regenerated.
- [ ] The change lands as a `feat!:` / breaking commit so release-please cuts a
  MAJOR version bump, and the breaking change plus caller `moved`-block
  migration are documented.
