# Spec: Module - AWS IPAM
**Issue:** #103
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
Today every VPC built from `modules/aws/vpc` requires the caller to hand-pick a static `vpc_cidr` (default `10.11.0.0/16`, see `modules/aws/vpc/variables.tf:4`). At organization scale this produces overlapping/conflicting CIDR ranges across accounts and regions (breaking VPC peering, Transit Gateway, and VPN routing), no central visibility into allocated vs. free space, and manual, error-prone IP planning per account.
AWS [VPC IPAM](https://docs.aws.amazon.com/vpc/latest/ipam/what-it-is-ipam.html) centrally plans, allocates, and monitors IP address space across an entire AWS Organization and all regions. This spec introduces a new `modules/aws/ipam` module that provisions an IPAM instance, scopes, and hierarchical pools, plus purely additive wiring into the existing `modules/aws/vpc` module so a VPC can source its CIDR from an IPAM pool. Org delegation is handled inside the IPAM module via `aws_vpc_ipam_organization_admin_account`, and cross-account pool sharing reuses the existing `modules/aws/ram` module via composition (per the "no inline cross-cutting resources" rule in `AGENTS.md`).
Originating issue: #103. Triage classified this as a feature with low breaking-change risk.

## 2. Non-goals
- Does not modify the existing `modules/aws/ram` module; cross-account sharing is achieved by the caller composing `modules/aws/ram` (or by the IPAM module calling it as a child module) — no inline RAM resources are added to other modules.
- Does not manage VPC subnet-level CIDRs from IPAM in this iteration (only the top-level VPC IPv4 CIDR via `ipv4_ipam_pool_id` / `ipv4_netmask_length`).
- Does not refactor the existing static-CIDR behavior of `modules/aws/vpc`; `vpc_cidr` and the per-tier subnet list variables remain unchanged.
- Does not create or manage the AWS Organization itself, delegated-admin trust, or member-account enrollment beyond registering the IPAM delegated admin.
- Does not implement IPAM-driven IPv6 subnet auto-assignment beyond exposing the relevant pool inputs/outputs.
- Does not create `global/` caller code that consumes these modules.

## 3. Affected module path(s)
- `modules/aws/ipam/` (new) — IPAM instance, scopes, pools, pool CIDRs, optional pool allocations, optional org delegated-admin registration, and optional RAM sharing via composition with `modules/aws/ram`.
- `modules/aws/vpc/` (existing) — additive inputs to source the VPC CIDR from an IPAM pool; no change to current default behavior.
- `modules/aws/ram/` (existing) — referenced via composition only; not modified.

## 4. Proposed design
**Signatures only — no full implementations.**

### `modules/aws/ipam` — `variables.tf`
General:
- `name` — `string` — Name for the IPAM and tag `Name` value.
- `description` — `string`, default `null` — Description of the IPAM.
- `tags` — `map(string)`, default repo-standard tag map — Tags merged with `Name`.

IPAM instance / scopes:
- `operating_regions` — `list(string)` — Regions the IPAM operates in (must include the region where the IPAM is created).
- `tier` — `string`, default `"advanced"` — IPAM tier (`free` or `advanced`); `advanced` is required for org/region features.
- `enable_private_default_scope` — `bool`, default `true` — Whether to use the default private scope.
- `enable_public_default_scope` — `bool`, default `true` — Whether to use the default public scope.
- `additional_private_scopes` — `map(object({ description = optional(string) }))`, default `{}` — Extra private scopes keyed by logical name.

Pools (scalable `map(object(...))` per the library's scalable-inputs convention):
- `pools` — `map(object({ ... }))`, default `{}` — Each pool keyed by logical name with fields:
  - `address_family` — `string` — `ipv4` or `ipv6`.
  - `scope_key` — `optional(string)` — Which scope this pool belongs to (`private`/`public`/custom key); defaults to private.
  - `parent_pool_key` — `optional(string)` — Logical key of the parent pool for hierarchical pools.
  - `locale` — `optional(string)` — Region the pool is scoped to (required for pools that allocate to VPCs).
  - `description` — `optional(string)`.
  - `provisioned_cidrs` — `optional(list(string), [])` — CIDRs to provision into the pool.
  - `allocation_default_netmask_length` — `optional(number)`.
  - `allocation_min_netmask_length` — `optional(number)`.
  - `allocation_max_netmask_length` — `optional(number)`.
  - `auto_import` — `optional(bool, false)`.
  - `publicly_advertisable` — `optional(bool)` — Public-scope IPv6 pools only.
  - `aws_service` — `optional(string)` — e.g. `ec2` for public IPv6 pools.
  - `allocation_resource_tags` — `optional(map(string), {})`.
  - `tags` — `optional(map(string), {})`.

Static allocations (optional):
- `allocations` — `map(object({ pool_key = string, cidr = optional(string), netmask_length = optional(number), description = optional(string) }))`, default `{}` — Reserved/static allocations from a pool.

Org delegation & sharing (opt-in):
- `delegated_admin_account_id` — `string`, default `null` — Account to register as IPAM delegated admin (apply from the Organization management account).
- `share_with_organization` — `bool`, default `false` — Whether to RAM-share pools with the entire organization.
- `ram_principals` — `list(string)`, default `[]` — Specific principals/OU ARNs to share pools with when not sharing org-wide.
- `ram_share_pool_keys` — `list(string)`, default `[]` — Which pool keys to share via RAM.

### `modules/aws/ipam` — `outputs.tf`
- `ipam_id` — IPAM ID.
- `ipam_arn` — IPAM ARN.
- `public_scope_id` — Default public scope ID.
- `private_scope_id` — Default private scope ID.
- `scope_ids` — Map of additional scope keys → IDs.
- `pool_ids` — Map of pool key → pool ID.
- `pool_arns` — Map of pool key → pool ARN.
- `pool_cidrs` — Map of pool key → provisioned CIDR(s).
- `allocation_cidrs` — Map of allocation key → allocated CIDR block (for feeding into the VPC module).
- `ram_share_arns` — Map of shared pool key → RAM resource-share ARN (when sharing enabled).

### `modules/aws/ipam` — `main.tf`
- `terraform {}` block: `required_version = ">= 1.0.0"`, `aws >= 6.0.0` (matches `modules/module_template`).
- `aws_vpc_ipam.this` — the IPAM instance, with a `dynamic "operating_regions"` block over `var.operating_regions`; tags via `merge(tomap({ Name = var.name }), var.tags)`.
- `aws_vpc_ipam_scope.additional` — `for_each = var.additional_private_scopes` for extra scopes (default scopes are read from `aws_vpc_ipam.this`).
- `aws_vpc_ipam_pool.this` — `for_each = var.pools`; `source_ipam_pool_id` wired from the parent pool when `parent_pool_key` is set; scope ID resolved from default/additional scopes.
- `aws_vpc_ipam_pool_cidr.this` — `for_each` over the flattened `(pool_key, cidr)` pairs from `provisioned_cidrs`.
- `aws_vpc_ipam_pool_cidr_allocation.this` — `for_each = var.allocations` for optional static allocations.
- `aws_vpc_ipam_organization_admin_account.this` — `count = var.delegated_admin_account_id != null ? 1 : 0` (must be applied from the org management account).
- RAM sharing via composition: `module "ram"` calling `modules/aws/ram` with `for_each` over `var.ram_share_pool_keys` (associating each shared pool ARN), driven by `share_with_organization` / `ram_principals` — no inline `aws_ram_*` resources.
- Locals to flatten pool/CIDR pairs and resolve parent/scope relationships.

### `modules/aws/vpc` additions (additive only)
`variables.tf` (new):
- `ipv4_ipam_pool_id` — `string`, default `null` — When set, the VPC sources its IPv4 CIDR from this IPAM pool.
- `ipv4_netmask_length` — `number`, default `null` — Netmask length to allocate from the IPAM pool.

`main.tf` (modified `aws_vpc.vpc`):
- `cidr_block` becomes conditional: `var.ipv4_ipam_pool_id == null ? var.vpc_cidr : null`.
- Add `ipv4_ipam_pool_id = var.ipv4_ipam_pool_id` and `ipv4_netmask_length = var.ipv4_netmask_length`.
- Existing references to `var.vpc_cidr` in the SSM endpoint security group ingress (`modules/aws/vpc/main.tf:55` and `:63`) and any subnet math are unaffected when callers continue using static CIDRs; when IPAM sourcing is used, callers must still supply a `vpc_cidr`/CIDR value for those SG rules (see Open questions).

## 5. Breaking-change assessment
- Breaking: **no**.
- The `modules/aws/ipam` module is brand new — no existing callers.
- The `modules/aws/vpc` change is purely additive: `ipv4_ipam_pool_id` and `ipv4_netmask_length` default to `null`, and `vpc_cidr` retains its current default (`10.11.0.0/16`). With the new variables unset, `cidr_block` resolves to `var.vpc_cidr` exactly as today. IPAM sourcing only activates when the new variables are supplied.
- Org delegation and RAM sharing are opt-in (`delegated_admin_account_id` / `share_with_organization` default to off) and do not alter current behavior of any module.
- `modules/aws/ram` is not modified.

## 6. Checkov / tfsec considerations
- New suppressions: **none anticipated.** IPAM, scopes, and pools are control-plane resources without the public-exposure or encryption checks that typically require suppression. If Checkov flags the conditional `cidr_block`/`ipv4_ipam_pool_id` pairing on `aws_vpc.vpc`, an inline suppression will be added with a documented rationale, but none is expected.
- Existing suppressions affected: none. The existing `#tfsec:ignore:aws-ec2-no-public-egress-sgr` in `modules/aws/vpc/main.tf` is unrelated and remains unchanged.

## 7. terraform-docs impact
- New `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/ipam/README.md` (auto-injected during implementation / verified by CI `build.yml`).
- The `modules/aws/vpc/README.md` `<!-- BEGIN_TF_DOCS -->` block will change to include the two new inputs (`ipv4_ipam_pool_id`, `ipv4_netmask_length`). CI `Verify - terraform-docs` will fail unless docs are regenerated and committed in the implementation PR.

## 8. Testing
- `tofu -chdir=modules/aws/ipam init -backend=false && tofu -chdir=modules/aws/ipam validate`
- `tofu -chdir=modules/aws/vpc init -backend=false && tofu -chdir=modules/aws/vpc validate`
- `tofu fmt -check -diff -recursive`
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/ipam` (and the same for `modules/aws/vpc`), or `pre-commit run --all-files`.
- `checkov -d modules/aws/ipam` (locally; CI runs on schedule).
- Module-specific: confirm hierarchical pool wiring (parent → child via `source_ipam_pool_id`), confirm a VPC plan sources its CIDR from a pool when `ipv4_ipam_pool_id`/`ipv4_netmask_length` are set, and confirm an unchanged plan for existing static-CIDR VPC callers.

## 9. Open questions
- When a VPC sources its CIDR from IPAM (CIDR not known until apply), the SSM endpoint security-group ingress rules currently reference `var.vpc_cidr` (`modules/aws/vpc/main.tf:55`, `:63`). Implementation should decide whether to keep requiring a `vpc_cidr` value for those rules, derive ingress CIDRs from `aws_vpc.vpc.cidr_block`, or make those endpoints/rules optional. Preference: reference `aws_vpc.vpc.cidr_block` so IPAM-sourced VPCs need no separate `vpc_cidr`.
- Whether the IPAM module should call `modules/aws/ram` internally for sharing or expose pool ARNs and leave sharing to the caller. Preference: internal composition gated behind `share_with_organization` / `ram_principals`, with pool ARNs still exposed as outputs for callers who prefer to share externally.
- Whether to support multiple IPAM instances per module invocation. Preference: one IPAM per module instance (typical for org-wide IPAM), pools/scopes scaled via `map(object(...))`.

## 10. Acceptance criteria
- `modules/aws/ipam` provisions an IPAM instance, public + private scopes, and one or more pools with provisioned CIDRs.
- Supports hierarchical pools (region/locale-scoped child pools) via a scalable `map(object(...))` / YAML-compatible input.
- Supports org delegated administration for IPAM (`aws_vpc_ipam_organization_admin_account`) and RAM sharing of pools across the organization via composition with `modules/aws/ram` (no inline RAM resources).
- Optional, additive integration with `modules/aws/vpc` so a VPC can source its CIDR from an IPAM pool; existing `vpc_cidr` callers remain unaffected (no breaking change).
- Exposes outputs for IPAM ID/ARN, scope IDs, pool IDs/ARNs, provisioned pool CIDRs, and allocated CIDR blocks.
- Secure / Well-Architected defaults (private scope enabled by default, least-privilege IAM, encryption where applicable).
- `modules/aws/ipam/README.md` includes a description, prerequisites, a complete `module {}` usage example, and the auto-generated `terraform-docs` block; `modules/aws/vpc/README.md` docs regenerated for the new inputs.
- Passes `tofu fmt`/`validate`, `terraform-docs` verification, and Checkov in CI.
