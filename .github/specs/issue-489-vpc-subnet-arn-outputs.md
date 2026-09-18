# Spec: feat(aws/vpc): output subnet ARNs for all subnet tiers
**Issue:** #489
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
`modules/aws/vpc` creates six subnet tiers — `private`, `public`, `db`, `dmz`,
`mgmt`, and `workspaces` — each as an `aws_subnet` resource with
`count = length(var.<tier>_subnets_list)`. `modules/aws/vpc/outputs.tf` exposes
a `*_subnet_ids` list for every one of those tiers, plus `vpc_arn`, but only a
single subnet **ARN** list: `private_subnet_arns`
(`modules/aws/vpc/outputs.tf:99-102`).

Some AWS APIs take subnet ARNs rather than subnet IDs. The immediate consumer is
`modules/aws/cloud_wan/vpc_attachment`, whose `vpc_attachments` object type
declares `subnet_arns = list(string)`
(`modules/aws/cloud_wan/vpc_attachment/variables.tf:13`). Today only the private
tier can be wired straight from a module output; attaching a DMZ, mgmt, db, or
workspaces tier forces the caller to reconstruct ARNs from IDs in `locals` (or
otherwise reach around the module boundary), which duplicates resource-addressing
knowledge that belongs inside the module.

This spec adds the five missing `*_subnet_arns` outputs so every tier has ARN
parity with its existing `*_subnet_ids` output.

See: https://github.com/zachreborn/terraform-modules/issues/489

## 2. Non-goals
- **No changes to `main.tf`.** No new or modified resources, data sources,
  locals, variables, `count`/`for_each` expressions, or tags. `arn` is already a
  computed attribute on every `aws_subnet` resource the module creates.
- **No change to `private_subnet_arns`.** Its name, description, and value stay
  exactly as they are today.
- **No new aggregate output** (e.g. a single `subnet_arns` map or a flattened
  all-tier list). The issue explicitly asks to keep the existing parallel-list
  shape; an aggregate can be proposed separately if a caller needs one.
- **No retrofit of descriptions onto the pre-existing undescribed outputs**
  (`private_subnet_ids`, `public_subnet_ids`, `db_subnet_ids`, `dmz_subnet_ids`,
  `mgmt_subnet_ids`, `workspaces_subnet_ids`, `vpc_id`, the `*_route_table_ids`
  family, etc., which render as `n/a` in the README Outputs table). That cleanup
  is a separate docs PR — see § 9.
- **No changes to `modules/aws/cloud_wan/vpc_attachment`.** It already accepts
  `subnet_arns`; only the VPC module's outputs are missing.
- **No changes to any other module**, and no new subnet tiers.

## 3. Affected module path(s)
- `modules/aws/vpc/` (existing) — `outputs.tf`, `README.md`, `tests/vpc.tftest.hcl`

No other module is touched.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes. The tier lists that drive subnet creation already exist and keep
their current defaults:

- `private_subnets_list` (`list(string)`, default three `/24`s)
- `public_subnets_list` (`list(string)`, default three `/24`s)
- `db_subnets_list` (`list(string)`, default three `/24`s)
- `dmz_subnets_list` (`list(string)`, default three `/24`s)
- `mgmt_subnets_list` (`list(string)`, default three `/24`s)
- `workspaces_subnets_list` (`list(string)`, default three `/24`s)

No new variables and no new `validation { ... }` blocks are introduced.

### `outputs.tf`
Add five outputs, matching the shape, ordering, and description style of the
existing `private_subnet_arns` output. Each is an implicit `list(string)`
produced by a splat over the tier's `aws_subnet` resource:

- **`public_subnet_arns`** — value `aws_subnet.public_subnets[*].arn`;
  description `"List of ARNs of public subnets"`.
- **`db_subnet_arns`** — value `aws_subnet.db_subnets[*].arn`;
  description `"List of ARNs of database subnets"`.
- **`dmz_subnet_arns`** — value `aws_subnet.dmz_subnets[*].arn`;
  description `"List of ARNs of DMZ subnets"`.
- **`mgmt_subnet_arns`** — value `aws_subnet.mgmt_subnets[*].arn`;
  description `"List of ARNs of management subnets"`.
- **`workspaces_subnet_arns`** — value `aws_subnet.workspaces_subnets[*].arn`;
  description `"List of ARNs of WorkSpaces subnets"`.

Existing outputs — including `private_subnet_arns`, every `*_subnet_ids`
output, and `vpc_arn` — are unchanged.

Behavioural contract each new output inherits from the splat, and which the
tests in § 8 must pin down:

- **Ordering** is the `count.index` order of the tier's `aws_subnet` resource,
  which is the caller's `<tier>_subnets_list` order — the same ordering already
  guaranteed by `<tier>_subnet_ids`. Element *i* of `<tier>_subnet_arns` refers
  to the same subnet as element *i* of `<tier>_subnet_ids`.
- **Empty tiers return `[]`**, not `null`. A caller who sets
  `dmz_subnets_list = []` gets `count = 0`, so the splat yields an empty list —
  identical to today's `dmz_subnet_ids` behaviour.

### `main.tf`
No changes. The five `aws_subnet` resources the new outputs read from already
exist and are unmodified by this change:

- `aws_subnet.public_subnets` (`count = length(var.public_subnets_list)`)
- `aws_subnet.db_subnets` (`count = length(var.db_subnets_list)`)
- `aws_subnet.dmz_subnets` (`count = length(var.dmz_subnets_list)`)
- `aws_subnet.mgmt_subnets` (`count = length(var.mgmt_subnets_list)`)
- `aws_subnet.workspaces_subnets` (`count = length(var.workspaces_subnets_list)`)

No lifecycle ignores, tagging changes, or `tfsec:ignore` comments are added or
removed. `required_version` (`>= 1.0.0`) and the `aws` provider constraint
(`>= 6.0.0`) stay as-is: splat expressions and `aws_subnet.arn` long predate
both floors, so per AGENTS.md § 7 there is nothing to bump.

### `README.md` (hand-written section)
Add a Cloud WAN consumption example to the `## Usage` section — a sibling of the
existing "Setting Subnet Example" / "Disabling Unneeded Subnets" headings, placed
above the `<!-- BEGIN_TF_DOCS -->` marker. It must show `subnet_arns` fed
directly from a module output with no `locals` ARN assembly, and note that every
tier now has an equivalent output. Signature of the example:

```hcl
module "cloud_wan_vpc_attachment" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloud_wan/vpc_attachment"

  core_network_id = var.core_network_id

  vpc_attachments = {
    workload = {
      vpc_arn     = module.vpc.vpc_arn
      subnet_arns = module.vpc.private_subnet_arns
      # or module.vpc.dmz_subnet_arns / mgmt_subnet_arns / db_subnet_arns /
      # public_subnet_arns / workspaces_subnet_arns
    }
  }
}
```

## 5. Breaking-change assessment
- Breaking: **no**.
- The change is purely additive: five new output declarations. No input,
  output, resource, or default is renamed, retyped, removed, or otherwise
  modified. There is no state movement, so no `moved` blocks and no migration
  steps. Callers that ignore the new outputs see zero plan diff; the addition
  itself produces no resource changes on `apply`.
- Per the repo's SemVer rules this lands as a `feat:` → **MINOR** bump.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. Output declarations expose an existing computed
  attribute and configure no resource, so no Checkov or tfsec policy is
  implicated.
- Existing suppressions affected: **none**. The
  `#tfsec:ignore:aws-ec2-no-public-ip-subnet` comment on
  `aws_subnet.public_subnets` and the
  `#tfsec:ignore:aws-ec2-no-public-egress-sgr` comment on
  `aws_security_group.ssm_vpc_endpoint` are untouched.
- No change to `.checkov.yaml`.

## 7. terraform-docs impact
Yes, for `modules/aws/vpc/README.md` only. The `<!-- BEGIN_TF_DOCS -->` block's
**Outputs** table gains five alphabetically-sorted rows —
`db_subnet_arns`, `dmz_subnet_arns`, `mgmt_subnet_arns`, `public_subnet_arns`,
and `workspaces_subnet_arns` — each rendering the description above rather than
`n/a`. The Requirements, Providers, Modules, Resources, and Inputs tables are
unchanged, since no provider constraint, resource, or variable moves.

The implementer must regenerate the block **locally** and commit the result —
CI's `Verify - terraform-docs` job only checks for drift and does not push
fixes:

```sh
pre-commit run --all-files
# or, for this module alone:
terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/vpc
```

## 8. Testing
Commands the implementer must run and pass:

- `tofu -chdir=modules/aws/vpc init -backend=false && tofu -chdir=modules/aws/vpc validate`
- `tofu -chdir=modules/aws/vpc test`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/vpc` (locally; CI runs on schedule)

### Native `tofu test` plan
All work lands in the existing `modules/aws/vpc/tests/vpc.tftest.hcl`, whose
file-level `mock_provider "aws"` block already keeps the suite offline. **No new
`mock_resource` / `defaults` override is needed for `aws_subnet.arn`**: the new
ARN values are only read into outputs, never fed into a provider argument that
the AWS schema validates as a well-formed ARN, which is why the existing
`private_subnet_arns` assertion (`tests/vpc.tftest.hcl:133-136`) already passes
against `mock_provider`'s placeholder string. Do **not** add mock defaults that
would paper over the values being asserted.

**Valid baseline —** extend the existing `run "baseline_plans_with_defaults"`
block (defaults give three subnets per tier), asserting each new output against
the resource it is derived from, in the same style as the neighbouring
`private_subnet_arns` and `*_subnet_ids` assertions:

- `output.public_subnet_arns == aws_subnet.public_subnets[*].arn`
- `output.db_subnet_arns == aws_subnet.db_subnets[*].arn`
- `output.dmz_subnet_arns == aws_subnet.dmz_subnets[*].arn`
- `output.mgmt_subnet_arns == aws_subnet.mgmt_subnets[*].arn`
- `output.workspaces_subnet_arns == aws_subnet.workspaces_subnets[*].arn`

Plus one length assertion per tier (`length(output.<tier>_subnet_arns) == 3`) so
a silently-empty splat cannot pass the equality checks vacuously, and one
cardinality assertion pinning ARN/ID parity, e.g.
`length(output.dmz_subnet_arns) == length(output.dmz_subnet_ids)`, proving the
two lists stay index-aligned.

**Variable `validation { ... }` cases —** **none.** This change adds no
variables and no validation rules, so there is no new `expect_failures` case to
write. The existing `tests/validation.tftest.hcl` cases are unaffected and must
continue to pass unmodified.

**Conditional / `count` branches —** each tier's `aws_subnet` resource has a
`count = length(var.<tier>_subnets_list)` branch pair, so both sides need
coverage:

- *Populated side* — covered by the baseline case above (all six tiers
  non-empty).
- *Empty side, public tier* — extend the existing
  `run "empty_public_subnets_list_disables_igw_even_when_enabled"` block (which
  already sets `public_subnets_list = []` and asserts
  `length(output.public_subnet_ids) == 0`) with
  `output.public_subnet_arns == []`.
- *Empty side, remaining tiers* — add a new `run` block, e.g.
  `run "empty_subnet_tiers_return_empty_arn_lists"`, setting
  `db_subnets_list = []`, `dmz_subnets_list = []`, `mgmt_subnets_list = []`, and
  `workspaces_subnets_list = []` (mirroring the README's "Disabling Unneeded
  Subnets" example; leave `private_subnets_list`/`public_subnets_list` at their
  defaults). Assert `output.<tier>_subnet_arns == []` for each of the four
  disabled tiers, and assert the still-enabled
  `output.private_subnet_arns == aws_subnet.private_subnets[*].arn` with
  `length(...) == 3`, so the case proves the empty result is tier-scoped rather
  than a module-wide collapse.

**Meaningful outputs —** every one of the five new outputs is asserted in both
the populated and the empty branch; `private_subnet_arns` keeps its existing
baseline assertion.

**Wiring assertions —** not applicable to the new outputs. The only submodule
`modules/aws/vpc` calls is `../flow_logs`, which consumes `vpc_id` and is not
wired to any subnet ARN; its existing wiring case
(`run "enable_flow_logs_true_wires_vpc_id_into_flow_logs_module"`) is unchanged
and must keep passing. `modules/aws/cloud_wan/vpc_attachment` is a *sibling*
consumer, not a child module, so it is out of scope here — the ARN/ID
cardinality assertion above is what pins the contract that module depends on.

Every case must exercise real module behaviour. Do not weaken an assertion,
skip a `run` block, or mock away an ARN value to turn a failing case green; a
failure means the output expression is wrong and belongs fixed in
`outputs.tf`.

## 9. Open questions
- Should the pre-existing undescribed outputs (`*_subnet_ids`, `vpc_id`,
  `*_route_table_ids`, `natgw_ids`, …) gain descriptions so the README Outputs
  table stops showing `n/a`? Proposed: **no, not in this PR** — it would bury
  the five-line functional change in a large docs diff. Reviewer may split it
  into a follow-up `docs:` issue.
- Is `"List of ARNs of WorkSpaces subnets"` the preferred capitalization
  (matching the AWS service name) versus lowercase `workspaces` used in the
  variable descriptions? Proposed: use the issue's wording as written; trivially
  adjustable at review.
- Should the ARN outputs be added to `modules/aws/vpc`'s sibling VPC-shaped
  modules for consistency? Out of scope here; resolve as a follow-up issue if a
  reviewer wants it.

## 10. Acceptance criteria
- [ ] `modules/aws/vpc/outputs.tf` declares `public_subnet_arns`,
      `db_subnet_arns`, `dmz_subnet_arns`, `mgmt_subnet_arns`, and
      `workspaces_subnet_arns`, each valued `aws_subnet.<tier>[*].arn` with a
      description matching the existing `private_subnet_arns` style.
- [ ] Output shape matches the existing ID lists — ordered `list(string)`,
      index-aligned with the corresponding `*_subnet_ids` output, and `[]` for
      an empty/disabled tier.
- [ ] `private_subnet_arns` remains available and unchanged in behaviour, and
      no other existing output is modified.
- [ ] `modules/aws/vpc/main.tf` and `modules/aws/vpc/variables.tf` are
      unchanged.
- [ ] `modules/aws/vpc/tests/vpc.tftest.hcl` covers the new outputs per § 8:
      baseline equality + length assertions for all five, the ARN/ID
      cardinality assertion, `public_subnet_arns == []` in the existing
      empty-public-subnets case, and a new empty-tier case for db/dmz/mgmt/
      workspaces.
- [ ] `tofu -chdir=modules/aws/vpc init -backend=false && tofu -chdir=modules/aws/vpc test`
      passes with every pre-existing case still green and no assertion weakened.
- [ ] `modules/aws/vpc/README.md` documents Cloud WAN-style consumption without
      `locals`, e.g. `subnet_arns = module.vpc.private_subnet_arns`, and notes
      the other tier outputs.
- [ ] `terraform-docs` regenerated and committed so the README Outputs table
      lists all five new outputs with their descriptions.
- [ ] `tofu fmt -check -diff -recursive` passes.
- [ ] No breaking changes — additive only; PR title uses the `feat:`
      Conventional Commit type.
