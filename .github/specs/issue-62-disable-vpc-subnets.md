# Spec: Ability to disable VPC subnets
**Issue:** #62
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The `modules/aws/vpc` module today creates each subnet tier based solely on the
length of that tier's `*_subnets_list` variable (e.g. `aws_subnet.private_subnets`
uses `count = length(var.private_subnets_list)`). Because every `*_subnets_list`
ships with a non-empty default (three CIDRs each for private, public, db, dmz,
mgmt, and workspaces), a bare `module "vpc"` call provisions the private and
database tiers — plus their route tables and associations — unconditionally.

Some deployments (transit VPCs, public-only VPCs, etc.) do not need a private
and/or database tier. Forcing their creation wastes IP space, adds unnecessary
route table / route resources, and enlarges the blast radius of the deployment.

This spec introduces per-tier `enable_*_subnet` boolean toggles so callers can
opt out of subnet tiers they do not use, following the module's existing
`enable_*` convention (`enable_nat_gateway`, `enable_internet_gateway`,
`enable_flow_logs`, …). All toggles default to `true`, preserving current
behavior. See issue #62 for the originating discussion and the triage
classification comment.

## 2. Non-goals
- Not changing the shape, type, or defaults of any existing `*_subnets_list`,
  `*_propagating_vgws`, or other current variables.
- Not changing subnet CIDR math, AZ distribution, or naming/tagging of subnets.
- Not adding a route table association for the `mgmt` tier (the module currently
  ships `aws_route_table.mgmt_route_table` and its routes but no
  `aws_route_table_association.mgmt`; this pre-existing gap is out of scope).
- Not refactoring the tiers to a single `for_each`/map or YAML-driven input.
  This spec keeps the current per-tier resource blocks and only gates their
  `count`.
- Not altering the SSM/ECR VPC endpoint feature set beyond adding a guard for
  its existing dependency on the private tier (see §4.3).
- Not fixing the pre-existing behavior where `enable_internet_gateway = false`
  combined with a non-empty `public_subnets_list` errors on
  `aws_route_table_association.public` (tracked as an open question, §9).

## 3. Affected module path(s)
- `modules/aws/vpc/` (existing) — `variables.tf`, `main.tf`, `README.md`.
  `outputs.tf` requires no signature change (see §4.2).

## 4. Proposed design
**Signatures only — no full implementations.**

Introduce one boolean toggle per subnet tier. `enable_private_subnet` and
`enable_db_subnet` are the acceptance-criteria-mandated additions; the remaining
four (`enable_public_subnet`, `enable_dmz_subnet`, `enable_mgmt_subnet`,
`enable_workspaces_subnet`) are added in the same PR for consistency, as the
issue requests ("existing `enable_*` pattern should be followed for any other
optional subnet tiers … for consistency"). All default to `true`.

### `variables.tf`
Add to the "Subnets" section, each `type = bool`, `default = true`:
- `enable_private_subnet` — "(Optional) When true, create the private subnet
  tier and its route tables/associations. When false, none are created and
  private-tier outputs return empty lists. Defaults true."
- `enable_public_subnet` — "(Optional) When true, create the public subnet tier
  and its route table associations. When false, none are created and public-tier
  outputs return empty lists. Also gates the internet gateway / NAT gateway (see
  notes). Defaults true."
- `enable_db_subnet` — "(Optional) When true, create the database subnet tier and
  its route tables/associations. When false, none are created and db-tier outputs
  return empty lists. Defaults true."
- `enable_dmz_subnet` — "(Optional) When true, create the DMZ subnet tier and its
  route tables/associations. When false, none are created. Defaults true."
- `enable_mgmt_subnet` — "(Optional) When true, create the mgmt subnet tier and
  its route table/routes. When false, none are created. Defaults true."
- `enable_workspaces_subnet` — "(Optional) When true, create the workspaces subnet
  tier and its route tables/associations. When false, none are created. Defaults
  true."

No changes to any existing variable declarations.

### `outputs.tf`
No signature changes required. Every subnet and route-table output already uses a
splat expression (e.g. `aws_subnet.private_subnets[*].id`,
`aws_route_table.db_route_table[*].id`). When a gated resource's `count`
evaluates to `0`, the splat yields `[]`, which satisfies the acceptance criterion
that outputs for a disabled tier return an empty list rather than error. The
affected outputs (behavior only, no code change) include:
`private_subnet_ids`, `private_subnets`, `private_subnet_arns`,
`private_route_table_ids`, `availability_zone`, `public_subnet_ids`,
`public_subnets`, `public_route_table_ids`, `db_subnet_ids`,
`db_route_table_ids`, `dmz_subnet_ids`, `dmz_route_table_ids`,
`mgmt_subnet_ids`, `mgmt_route_table_ids`, `workspaces_subnet_ids`,
`workspaces_route_table_ids`, `nat_eips`, `nat_eips_public_ips`, `natgw_ids`,
`igw_id`.

### `main.tf`
No new resource blocks. The change is to gate the `count` of existing per-tier
resources on the corresponding toggle. Two shapes are used:

1. Subnets, route tables, and route table associations currently counted by list
   length gain a toggle guard:
   `count = var.enable_<tier>_subnet ? length(var.<tier>_subnets_list) : 0`
2. Routes that already carry a compound condition gain the toggle as an
   additional `&&` term (e.g. the `*_default_route_natgw` and `*_default_route_fw`
   routes).

Resources to gate, by tier:
- **private** (`enable_private_subnet`): `aws_subnet.private_subnets`,
  `aws_route_table.private_route_table`, `aws_route_table_association.private`,
  `aws_route.private_default_route_natgw`, `aws_route.private_default_route_fw`.
- **public** (`enable_public_subnet`): `aws_subnet.public_subnets`,
  `aws_route_table_association.public`, and the `local.enable_igw` expression
  (see below), which transitively gates `aws_internet_gateway.igw`,
  `aws_route_table.public_route_table`, `aws_route.public_default_route`, and
  `aws_nat_gateway.natgw`.
- **db** (`enable_db_subnet`): `aws_subnet.db_subnets`,
  `aws_route_table.db_route_table`, `aws_route_table_association.db`,
  `aws_route.db_default_route_natgw`, `aws_route.db_default_route_fw`.
- **dmz** (`enable_dmz_subnet`): `aws_subnet.dmz_subnets`,
  `aws_route_table.dmz_route_table`, `aws_route_table_association.dmz`,
  `aws_route.dmz_default_route_natgw`, `aws_route.dmz_default_route_fw`.
- **mgmt** (`enable_mgmt_subnet`): `aws_subnet.mgmt_subnets`,
  `aws_route_table.mgmt_route_table`, `aws_route.mgmt_default_route_natgw`,
  `aws_route.mgmt_default_route_fw`.
- **workspaces** (`enable_workspaces_subnet`): `aws_subnet.workspaces_subnets`,
  `aws_route_table.workspaces_route_table`,
  `aws_route_table_association.workspaces`,
  `aws_route.workspaces_default_route_natgw`,
  `aws_route.workspaces_default_route_fw`.

Updated local (public tier coupling):
- `local.enable_igw` currently `var.enable_internet_gateway && length(var.public_subnets_list) != 0`.
  Add `var.enable_public_subnet` so disabling the public tier also removes the
  IGW, public route table/route, and NAT gateway that depend on public subnets.

#### 4.3 Cross-tier dependency guard (private subnets ↔ VPC endpoints)
The SSM interface endpoints (`aws_vpc_endpoint.ec2messages`, `.kms`, `.ssm`,
`.ssm-contacts`, `.ssm-incidents`, `.ssmmessages`) and the ECR interface
endpoints (`aws_vpc_endpoint.ecr_api`, `.ecr_dkr`, `.cloudwatch`) place their
ENIs in the private subnets (`aws_subnet.private_subnets[...]`). If a caller sets
`enable_private_subnet = false` while `enable_ssm_vpc_endpoints = true` (indexes
into `private_subnets` via `var.subnet_indices`) or `enable_ecr_vpc_endpoints =
true`, the configuration errors or produces an endpoint with no subnets.

The implementation must fail fast with a clear message rather than surfacing an
index-out-of-range error. Recommended (signature-level) approach, mirroring the
existing `internet_monitor_monitor_name` precondition on
`aws_internetmonitor_monitor.this`: add a `lifecycle { precondition { … } }`
enforcing
`!(var.enable_ssm_vpc_endpoints || var.enable_ecr_vpc_endpoints) || var.enable_private_subnet`
with an error message directing the caller to enable the private tier. A natural
single home is `aws_security_group.ssm_vpc_endpoint` (always created), or the
guard may be split across the endpoint resources. The
`aws_vpc_endpoint_route_table_association.private_s3` resource already counts off
`length(aws_route_table.private_route_table[*].id)`, so it self-adjusts to `0`
when the private tier is disabled and needs no extra guard.

## 5. Breaking-change assessment
- Breaking: **no**.
- All six new variables default to `true`. With the defaults, every gated `count`
  expression reduces to its current value (`var.enable_<tier>_subnet ?
  length(list) : 0` → `length(list)`), and `local.enable_igw` is unchanged
  because `var.enable_public_subnet` defaults to `true`. Resource addresses stay
  `count`-indexed with identical indices, so existing callers see no plan diff.
- No existing variable name, type, or default changes; no outputs are renamed or
  removed. No migration or `moved` blocks are required.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. The change only gates `count` on existing
  resources; it introduces no new resource types or security-relevant arguments.
- Existing suppressions affected: **none**. The current inline suppressions
  (`#tfsec:ignore:aws-ec2-no-public-egress-sgr` on the endpoint SG egress rule
  and `#tfsec:ignore:aws-ec2-no-public-ip-subnet` on the public subnet) remain
  as-is and keep applying to their resources.

## 7. terraform-docs impact
Yes. The `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/vpc/README.md` will gain
six new rows in the Inputs table (one per new `enable_*_subnet` variable). No
Outputs-table rows change. The implementation PR must regenerate docs
(`pre-commit run --all-files` or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/vpc`)
and commit the result so the `Verify - terraform-docs` CI job passes. The
hand-written usage examples in the README should also be updated to demonstrate
disabling a tier (e.g. the transit-VPC example from the issue with
`enable_private_subnet = false` and `enable_db_subnet = false`).

## 8. Testing
- `tofu -chdir=modules/aws/vpc init -backend=false && tofu -chdir=modules/aws/vpc validate`
  (Terraform equivalents also acceptable).
- `tofu fmt -check -diff -recursive`.
- `checkov -d modules/aws/vpc` (locally; CI runs on schedule).
- Behavioral plan checks (no apply required):
  - Default plan (no new variables set) shows **zero diff** vs. current `main`.
  - With `enable_private_subnet = false`: plan shows no `aws_subnet.private_subnets`,
    `aws_route_table.private_route_table`, `aws_route_table_association.private`,
    or private `aws_route.*` resources; `private_subnet_ids` output is `[]`.
  - With `enable_db_subnet = false`: analogous zero-resource result for the db
    tier; `db_subnet_ids` output is `[]`.
  - With `enable_public_subnet = false`: no public subnets, IGW, public route
    table/route, or NAT gateway; `public_subnet_ids` and `igw_id` outputs are `[]`.
  - With `enable_private_subnet = false` and `enable_ssm_vpc_endpoints = true`
    (or `enable_ecr_vpc_endpoints = true`): plan fails fast with the precondition
    error from §4.3.

## 9. Open questions
- **Public tier scope.** Should `enable_public_subnet` be included in this PR
  given its coupling to the IGW and NAT gateway (via `local.enable_igw`), or
  should the public tier remain always-list-driven and only private/db/dmz/mgmt/
  workspaces get toggles? This spec includes it for consistency; reviewers may
  narrow scope to just the acceptance-criteria-mandated `enable_private_subnet`
  and `enable_db_subnet` if preferred.
- **Latent public association behavior.** Should the implementation also gate
  `aws_route_table_association.public` on `local.enable_igw` (turning the
  pre-existing `enable_internet_gateway = false` + non-empty `public_subnets_list`
  error into a clean zero-association result)? Proposed as an optional, non-
  breaking improvement; left out of the mandatory scope.
- **Guard placement.** Confirm the preferred location/count of the §4.3
  precondition(s) — a single guard on `aws_security_group.ssm_vpc_endpoint` vs.
  per-endpoint preconditions.

## 10. Acceptance criteria
- `modules/aws/vpc` exposes `enable_private_subnet` and `enable_db_subnet` input
  variables, each `type = bool` and `default = true` (plus, for consistency, the
  `enable_public_subnet`, `enable_dmz_subnet`, `enable_mgmt_subnet`, and
  `enable_workspaces_subnet` toggles unless reviewers narrow scope per §9).
- When a tier's variable is `false`, no subnets, route tables, or route table
  associations (and no tier routes) are created for that tier, and
  `tofu plan`/`terraform plan` shows zero resources for the disabled tier.
- Module outputs for a disabled tier return an empty list instead of erroring.
- Existing callers who do not set these variables see no plan diff (non-breaking).
- Enabling SSM or ECR VPC endpoints while the private tier is disabled fails with
  a clear precondition error rather than an index-out-of-range error.
- README usage examples and the `terraform-docs` Inputs table are updated to
  document the new variables.
