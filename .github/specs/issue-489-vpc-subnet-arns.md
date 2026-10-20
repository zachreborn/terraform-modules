# Spec: feat(aws/vpc): output subnet ARNs for all subnet tiers
**Issue:** #489
**Status:** Spec approved — implementation complete in PR (this branch)
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The `modules/aws/vpc` module exports subnet **IDs** for every tier
(`private`, `public`, `db`, `dmz`, `mgmt`, `workspaces`) and already exports
`vpc_arn` plus a single subnet ARN list, `private_subnet_arns`. Consumers that
need subnet ARNs for other tiers (notably Cloud WAN VPC attachments, which take
`subnet_arns = list(string)`) must assemble ARNs in locals from IDs or reach for
other workarounds.

This change adds parallel `*_subnet_arns` outputs for the remaining tiers so
callers can address attachment inputs directly from module outputs.

See: https://github.com/zachreborn/terraform-modules/issues/489

## 2. Non-goals
- Changing existing ID, CIDR, route table, or gateway outputs.
- Renaming or restructuring `private_subnet_arns`.
- Map- or AZ-keyed ARN outputs (keep the existing ordered-list pattern).
- Changes to `modules/aws/cloud_wan/vpc_attachment` itself.
- Building ARNs via string interpolation; use the provider `arn` attribute on
  each `aws_subnet` resource.

## 3. Affected module path(s)
- `modules/aws/vpc/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes.

### `outputs.tf`
Keep existing outputs. Add five new list outputs matching the ID pattern:

- **`public_subnet_arns`** — `aws_subnet.public_subnets[*].arn`
  - description: `List of ARNs of public subnets`
- **`db_subnet_arns`** — `aws_subnet.db_subnets[*].arn`
  - description: `List of ARNs of database subnets`
- **`dmz_subnet_arns`** — `aws_subnet.dmz_subnets[*].arn`
  - description: `List of ARNs of DMZ subnets`
- **`mgmt_subnet_arns`** — `aws_subnet.mgmt_subnets[*].arn`
  - description: `List of ARNs of management subnets`
- **`workspaces_subnet_arns`** — `aws_subnet.workspaces_subnets[*].arn`
  - description: `List of ARNs of WorkSpaces subnets`

Existing **`private_subnet_arns`** remains:

- value: `aws_subnet.private_subnets[*].arn`
- description: `List of ARNs of private subnets`

Empty / disabled tiers return `[]`, consistent with `*_subnet_ids`.

### `main.tf`
No changes. Subnet resources already exist per tier; only outputs are added.

## 5. Breaking-change assessment
- Breaking: **no**
- Purely additive outputs. Callers that do not reference the new outputs are
  unaffected. `private_subnet_arns` behavior is unchanged.

## 6. Checkov / tfsec considerations
- New suppressions: **none** — output declarations only.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
**Yes** — `modules/aws/vpc/README.md` `<!-- BEGIN_TF_DOCS -->` Outputs table
gains the five new `*_subnet_arns` entries. Regenerate via
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/vpc`
(or `pre-commit run --all-files`) and commit the result. Also add a short
Cloud WAN-style usage example outside the generated block showing
`subnet_arns = module.vpc.private_subnet_arns` (and noting other tier outputs).

## 8. Testing
- `tofu -chdir=modules/aws/vpc init -backend=false && tofu -chdir=modules/aws/vpc validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/vpc` (locally; CI runs on schedule)
- Native `tofu test` in `modules/aws/vpc/tests/vpc.tftest.hcl`:
  - Extend `baseline_plans_with_defaults` with assertions that each new
    `*_subnet_arns` output equals the corresponding
    `aws_subnet.<tier>[*].arn` (mirror existing `private_subnet_arns` assert).
  - Extend `empty_public_subnets_list_disables_igw_even_when_enabled` (or an
    equivalent empty-list case) so `public_subnet_arns` is empty when
    `public_subnets_list = []`.
  - Do not weaken existing assertions.

## 9. Open questions
- None. Scope and shape were confirmed against the issue (all tiers, parallel
  lists, Cloud WAN as primary consumer).

## 10. Acceptance criteria
- [ ] `public_subnet_arns`, `db_subnet_arns`, `dmz_subnet_arns`,
      `mgmt_subnet_arns`, and `workspaces_subnet_arns` outputs exist and return
      `aws_subnet.<tier>[*].arn`
- [ ] Output shape matches existing ID lists (ordered lists; empty tier → `[]`)
- [ ] `private_subnet_arns` remains available and unchanged in behavior
- [ ] README / terraform-docs regenerated; Cloud WAN-style usage example added
- [ ] VPC native tests assert the new ARN outputs
- [ ] `tofu fmt` / `tofu validate` / `tofu test` pass for `modules/aws/vpc`
