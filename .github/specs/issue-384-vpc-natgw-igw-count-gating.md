# Spec: bug(vpc): NAT-gateway routes and public route-table association crash plan when enable_internet_gateway=false or public_subnets_list is empty
**Issue:** #384
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/vpc/main.tf` derives `local.enable_igw` as
`var.enable_internet_gateway && length(var.public_subnets_list) != 0`
(`main.tf:22`). The internet gateway (`aws_internet_gateway.igw`), the public
route table (`aws_route_table.public_route_table`), the public default route
(`aws_route.public_default_route`), and the NAT gateways
(`aws_nat_gateway.natgw`) are all correctly gated on `local.enable_igw`
(`main.tf:269`, `:275`, `:282`, `:296`). A NAT gateway attaches to a public
subnet, so when there is no IGW/public subnet there are no NAT gateways.

Several dependent resources compute `count` from `var.enable_nat_gateway`
and/or a private-tier subnet-list length **without** also requiring
`local.enable_igw`. When a caller sets `enable_internet_gateway = false` (or
supplies an empty `public_subnets_list`) while leaving `enable_nat_gateway` at
its default `true`, those resources still request a positive `count` but the
NAT gateway / public route table collections they index are empty, so the plan
crashes.

Affected resources (current `count`, does not account for `local.enable_igw`):
- `aws_route.private_default_route_natgw` — `main.tf:312-317`
- `aws_route.db_default_route_natgw` — `main.tf:333-338`
- `aws_route.dmz_default_route_natgw` — `main.tf:354-359`
- `aws_route.mgmt_default_route_natgw` — `main.tf:375-380`
- `aws_route.workspaces_default_route_natgw` — `main.tf:396-401`
- `aws_route_table_association.public` — `main.tf:418-422`, which indexes
  `aws_route_table.public_route_table[0]` unconditionally even though that
  resource's own `count` is gated on `local.enable_igw`

Observed errors (from the issue):
- `Call to function "element" failed: cannot use element function with an empty list.`
  for the `*_default_route_natgw` resources referencing
  `aws_nat_gateway.natgw[*].id` (e.g. `main.tf:315`).
- `The given key does not identify an element in this collection value: the
  collection has no elements.` for `aws_route_table_association.public`
  referencing `aws_route_table.public_route_table[0]` (`main.tf:420`).

Originating issue: #384.

## 2. Non-goals
- No new variables, outputs, or features. This is strictly a `count`-gating fix.
- No change to the semantics of `aws_nat_gateway.natgw`, `aws_internet_gateway.igw`,
  `aws_route_table.public_route_table`, or `aws_route.public_default_route` —
  they already gate on `local.enable_igw` correctly and stay as-is.
- No change to the firewall routes (`*_default_route_fw`), which are gated on
  `var.enable_firewall` and are independent of NAT/IGW.
- No change to the `local.enable_igw` definition itself.
- No refactor of the module's subnet/route-table structure beyond the affected
  `count` expressions.

## 3. Affected module path(s)
- `modules/aws/vpc/` (existing) — `main.tf` (fix) and new `tests/` directory
  (this module currently has no `tests/`).

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes. No variables added, removed, or retyped. The fix reuses the
existing `var.enable_nat_gateway`, `var.enable_internet_gateway`,
`var.public_subnets_list`, and the derived `local.enable_igw`.

### `outputs.tf`
No changes. Existing outputs (`natgw_ids`, `igw_id`, `public_route_table_ids`,
`private_route_table_ids`, etc.) already tolerate empty collections via
`[*]` splat and remain valid when the affected resources have `count = 0`.

### `main.tf`
No new resource blocks. Amend the `count` expression of the six affected
resources so a NAT-gateway-dependent resource is only created when a NAT
gateway can actually exist — i.e. add the same `local.enable_igw` requirement
that already gates `aws_nat_gateway.natgw`:
- `aws_route.private_default_route_natgw` — `count` additionally requires
  `local.enable_igw`.
- `aws_route.db_default_route_natgw` — `count` additionally requires
  `local.enable_igw`.
- `aws_route.dmz_default_route_natgw` — `count` additionally requires
  `local.enable_igw`.
- `aws_route.mgmt_default_route_natgw` — `count` additionally requires
  `local.enable_igw`.
- `aws_route.workspaces_default_route_natgw` — `count` additionally requires
  `local.enable_igw`.
- `aws_route_table_association.public` — `count` additionally requires
  `local.enable_igw`, so it is skipped whenever the public route table it
  indexes (`aws_route_table.public_route_table`) is skipped.

The existing per-tier subnet-length and `var.enable_nat_gateway` conditions are
retained; the fix only conjoins `local.enable_igw`. No lifecycle-ignore or
tagging changes are involved.

## 5. Breaking-change assessment
- Breaking: no.
- For existing callers that leave `enable_internet_gateway = true` with a
  non-empty `public_subnets_list` (the module defaults), `local.enable_igw` is
  already `true`, so the amended `count` values are unchanged and no resources
  are added or destroyed — a no-op plan.
- Callers that set `enable_internet_gateway = false` (or empty
  `public_subnets_list`) currently cannot `plan` at all; after the fix they get
  a valid plan with zero NAT-gateway-dependent routes and zero public
  route-table associations. This is a fix to a previously broken configuration,
  not a regression for working ones.
- Conventional Commit type: `fix:` (PATCH bump per `AGENTS.md` release rules).

## 6. Checkov / tfsec considerations
- New suppressions: none. The fix only tightens `count` conditions and adds no
  new resources or arguments.
- Existing suppressions affected: none. The existing inline `tfsec:ignore`
  comments (`main.tf:77`, `:226`) are unrelated to the affected resources and
  remain unchanged.

## 7. terraform-docs impact
No change to the auto-generated `<!-- BEGIN_TF_DOCS -->` block: no variables or
outputs are added, removed, or re-described. The module README's
`terraform-docs` table stays byte-for-byte identical, so the
`Verify - terraform-docs` CI job will pass without regeneration. A short
human-authored note documenting the `enable_internet_gateway = false` /
empty-`public_subnets_list` behaviour may optionally be added outside the
generated markers.

## 8. Testing
This module currently has no `tests/` directory; the implementation must add
`modules/aws/vpc/tests/` (start from `modules/module_template/tests/`) with
native OpenTofu tests that run offline via `mock_provider`, following the
conventions in `modules/aws/organizations/tests/`.

Local verification commands:
- `tofu -chdir=modules/aws/vpc init -backend=false && tofu -chdir=modules/aws/vpc validate`
- `tofu -chdir=modules/aws/vpc test`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/vpc` (locally; CI runs on schedule)

Native `tofu test` plan (`modules/aws/vpc/tests/*.tftest.hcl`, `command = plan`,
`mock_provider "aws"`). Every case must supply the required `name` variable and
exercise real module behaviour — no weakened assertions or mocked-away logic:

- **Valid-baseline case** — defaults (`enable_internet_gateway = true`,
  `enable_nat_gateway = true`, non-empty public/private subnet lists). Asserts
  the plan succeeds and that the NAT-gateway-dependent routes and public
  route-table associations are created (the pre-fix behaviour for the working
  path is preserved, so this must remain green before and after the fix).
- **`enable_internet_gateway = false` branch** (the primary repro from #384,
  NAT gateway left at default-enabled) — asserts the plan succeeds with zero
  NAT-gateway-dependent routes across all tiers and zero
  `aws_route_table_association.public`. Reproduces the `element()` /
  `Invalid index` crash before the fix and passes after.
- **`public_subnets_list = []` branch** (NAT gateway left enabled) — asserts
  the plan succeeds for the same reason: `local.enable_igw` is `false`, so
  NAT-gateway-dependent routes and public associations are skipped.
- **`enable_nat_gateway = false` branch** (IGW enabled) — asserts the plan
  succeeds and that all five `*_default_route_natgw` route tiers are skipped,
  confirming the retained `var.enable_nat_gateway` half of each condition still
  works.
- **`single_nat_gateway = true` branch** (IGW + NAT enabled) — asserts the plan
  succeeds and that exactly one NAT gateway is planned, confirming the fix does
  not disturb the single-vs-per-AZ NAT sizing.
- **Meaningful-output assertions** — assert on `output.natgw_ids`,
  `output.igw_id`, `output.public_route_table_ids`,
  `output.private_route_table_ids`, and `output.public_subnet_ids`: non-empty
  in the baseline case; empty (`length(...) == 0`) for `natgw_ids`, `igw_id`,
  and `public_route_table_ids` in the `enable_internet_gateway = false` and
  `public_subnets_list = []` cases.

No new variable `validation { ... }` rules are introduced by this fix, so there
are no new `expect_failures` cases to add for the affected code path. (The
module's existing validations — e.g. `instance_tenancy`,
`cloudwatch_retention_in_days`, `subnet_indices`, and the internet-monitor
thresholds — are unaffected and out of scope for this bug fix.) This module is
not a wrapper/composition module for the affected resources, so no submodule
wiring assertions are required for the fix (the unrelated `../flow_logs` module
call is out of scope).

## 9. Open questions
- Should the new `tests/` directory aim for full §6 coverage of the whole VPC
  module in this PR, or be scoped to the bug plus baseline now and expanded
  later? Recommendation: scope to the cases above (bug repro + baseline +
  the NAT/IGW conditional branches) so the fix is verifiable, and track
  broader coverage separately. Resolvable at review.

## 10. Acceptance criteria
- The `count` expressions for the five `*_default_route_natgw` resources
  incorporate the same "NAT gateway actually created" condition as
  `aws_nat_gateway.natgw` (they additionally require `local.enable_igw`) and are
  skipped when NAT gateways are skipped.
- `aws_route_table_association.public`'s `count` incorporates `local.enable_igw`
  so it is skipped when the public route table itself is skipped.
- A `tofu test` case with `enable_internet_gateway = false` (NAT gateway left at
  its default-enabled value) plans successfully with 0 NAT-gateway-dependent
  routes and 0 public route-table associations.
- A `tofu test` case with `public_subnets_list = []` (NAT gateway left enabled)
  plans successfully for the same reason.
- The default configuration (`enable_internet_gateway = true`, non-empty
  `public_subnets_list`) produces an unchanged, no-op plan relative to
  pre-fix behaviour.
- `tofu fmt -check`, `tofu validate`, and `tofu test` pass for
  `modules/aws/vpc`, and the committed `terraform-docs` output is unchanged.
