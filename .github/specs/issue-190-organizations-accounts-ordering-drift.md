# Spec: fix(aws/organizations): suppress spurious accounts ordering drift via lifecycle.ignore_changes
**Issue:** #190
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
The `aws_organizations_organizational_unit.this` resource in `modules/aws/organizations/ou` and the `aws_organizations_organization.org` resource in `modules/aws/organizations/organization` both expose a computed `accounts` attribute that the AWS provider types as an **ordered `list`**. The AWS Organizations API does not guarantee a stable ordering when it returns accounts, so any reordering between runs surfaces as drift under the "Objects have changed outside of OpenTofu/Terraform" section of a plan even though no account has actually moved.
Because a `list` is positionally compared (`[A, B, C]` ≠ `[A, C, B]`) while a `set` is not, and because the provider fixes the attribute type as `list`, the reorder cannot be solved by retyping in the module. The same account shows up as both removed (`-`) and added (`+`) purely because its index changed. This commonly triggers right after a new account is added to an OU or organization, which causes the API to return the list in a fresh order and invalidates the previously stored sequence in state.
`accounts` is a **read-only computed attribute** — Terraform/OpenTofu cannot modify it regardless of plan content — so the noise is non-remediable through normal reconciliation. The accepted fix for this class of bug (already used elsewhere in this repo, e.g. `modules/aws/amplify` per issue #286) is to add the attribute to `lifecycle.ignore_changes` so the planner stops reporting differences it can never resolve.
Both affected resources already declare a `lifecycle {}` block, so the fix **extends** the existing block rather than introducing a new one:
- `modules/aws/organizations/ou/main.tf:11-18` — `aws_organizations_organizational_unit.this`, existing `lifecycle { create_before_destroy = true }`.
- `modules/aws/organizations/organization/main.tf:15-23` — `aws_organizations_organization.org`, existing `lifecycle { prevent_destroy = true }`.
Reported on OpenTofu 1.12.1 with `hashicorp/aws` 6.4.0.
See: https://github.com/zachreborn/terraform-modules/issues/190

## 2. Non-goals
- Adding, removing, renaming, or retyping any input variable or output. The public interface of both modules is unchanged.
- Removing or altering the existing `accounts` outputs (`ou/outputs.tf:1-4`, `organization/outputs.tf:4-7`). They remain so callers can still read the account list; `ignore_changes` only suppresses drift reporting, it does not delete the attribute from state.
- Changing the existing `lifecycle` meta-arguments already present — `create_before_destroy = true` on the OU and `prevent_destroy = true` on the organization must be preserved exactly.
- Retyping `accounts` from `list` to `set`. The attribute type is provider-defined and cannot be overridden in the module.
- Ignoring any attribute other than `accounts`. All managed arguments (`name`, `parent_id`, `tags`, `aws_service_access_principals`, `enabled_policy_types`, `feature_set`, …) must continue to reconcile normally.
- Touching any other resource or child module in the organization module (`module.centralized_root`, `module.centralized_backup`, `module.identity_center_scp`, `aws_organizations_policy_attachment.identity_center_scp`).

## 3. Affected module path(s)
- `modules/aws/organizations/ou/` (existing)
- `modules/aws/organizations/organization/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes to either module. No variables are added, removed, or retyped.
- `ou/variables.tf`: `name` (string, required), `parent_id` (string, required), `tags` (map(string), default `{ terraform = "true" }`) — all unchanged.
- `organization/variables.tf`: `aws_service_access_principals`, `enabled_policy_types`, `feature_set`, `enabled_features`, `enable_identity_center_scp`, `identity_center_scp_name`, `identity_center_scp_description`, `attach_identity_center_scp`, `identity_center_scp_target_ids`, `enable_organization_backup`, `tags` — all unchanged.

### `outputs.tf`
No changes to either module. The existing `accounts` outputs are retained:
- `ou/outputs.tf`: `accounts`, `arn`, `id` — unchanged.
- `organization/outputs.tf`: `accounts`, `master_account_arn`, `master_account_email`, `master_account_id`, `arn`, `id`, `roots`, `identity_center_scp_id`, `identity_center_scp_arn`, `identity_center_scp_attachment_target_ids` — unchanged.

### `main.tf`
Two edits only; no new resources, data sources, locals, or child modules. Each edit adds a single `ignore_changes` entry to the **existing** `lifecycle {}` block.
- `modules/aws/organizations/ou/main.tf` — `aws_organizations_organizational_unit.this`:
  ```hcl
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [accounts]
  }
  ```
- `modules/aws/organizations/organization/main.tf` — `aws_organizations_organization.org`:
  ```hcl
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [accounts]
  }
  ```
The resource arguments, the `terraform {}`/`required_providers` blocks, the tagging, and all other organization-module resources/modules are unchanged.

## 5. Breaking-change assessment
- Breaking: **no**. No input variable, output, or resource address is added, removed, or renamed. Callers need no configuration changes; on upgrade the spurious `accounts` reorder drift simply stops appearing.
- Behavioural note (non-breaking): after this change Terraform/OpenTofu will no longer surface *any* refresh-detected change to `accounts`, including legitimate membership changes, in the plan's "changed outside" section. This is acceptable and intended because `accounts` is read-only and computed — the module never manages OU/organization membership (that is owned by `aws_organizations_account` / move operations elsewhere), so suppressing its drift removes only noise. The `accounts` output continues to expose the most recently refreshed value.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. Adding `lifecycle.ignore_changes` introduces no security-relevant resource configuration, so no new Checkov, tfsec, or Trivy inline ignores are required, and `.checkov.yaml` is not modified.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
**None.** terraform-docs renders providers, modules, resources, inputs, and outputs; `lifecycle` meta-arguments (`ignore_changes`, `create_before_destroy`, `prevent_destroy`) are not reflected in any of those tables. Because no variable, output, or resource address changes, the `<!-- BEGIN_TF_DOCS -->` blocks in both module READMEs remain byte-identical and the `Verify - terraform-docs` CI job will pass without regeneration. Any optional human-authored note about the suppression would live outside the `BEGIN_TF_DOCS`/`END_TF_DOCS` markers and is not managed by terraform-docs.

## 8. Testing
- `tofu -chdir=modules/aws/organizations/ou init -backend=false && tofu -chdir=modules/aws/organizations/ou validate` (Terraform equivalents also acceptable).
- `tofu -chdir=modules/aws/organizations/organization init -backend=false && tofu -chdir=modules/aws/organizations/organization validate`.
- `tofu fmt -check -diff -recursive`.
- `checkov -d modules/aws/organizations/ou` and `checkov -d modules/aws/organizations/organization` (locally; CI runs on schedule).
- Functional verification against a real organization with multiple accounts:
  - After `apply`, add a new account to the OU/organization out of band, then re-run `plan` and confirm the `accounts` attribute no longer appears in the "Objects have changed outside" section for `aws_organizations_organizational_unit.this` or `aws_organizations_organization.org`.
  - Confirm the `accounts` output still returns the populated account list after a refresh (i.e. `ignore_changes` suppresses drift reporting without blanking the value in state).
  - Confirm `prevent_destroy = true` (organization) and `create_before_destroy = true` (OU) remain in effect.

## 9. Open questions
- Confirm during implementation that, on the reported toolchain (OpenTofu 1.12.1 / `hashicorp/aws` 6.4.0), `ignore_changes = [accounts]` on a purely computed attribute fully suppresses the "Objects have changed outside" notice. This is the documented and widely-used pattern, but it should be validated against a live plan rather than assumed.
- Confirm the `accounts` output continues to reflect the latest refreshed membership (expected: refresh still updates state; `ignore_changes` only affects diff reporting). If a stale-output concern is observed, note it in the module README.

## 10. Acceptance criteria
- [ ] `modules/aws/organizations/ou/main.tf` adds `ignore_changes = [accounts]` to the existing `lifecycle {}` block on `aws_organizations_organizational_unit.this`, preserving `create_before_destroy = true`.
- [ ] `modules/aws/organizations/organization/main.tf` adds `ignore_changes = [accounts]` to the existing `lifecycle {}` block on `aws_organizations_organization.org`, preserving `prevent_destroy = true`.
- [ ] After the fix, repeated `tofu plan` runs report no changes for the `accounts` attribute on both resources, even when the AWS API returns accounts in a different order than previously stored in state.
- [ ] Adding a new account to an OU or organization no longer causes spurious `accounts` ordering drift in subsequent `tofu plan` runs for existing resources that were not modified.
- [ ] No breaking interface changes — no variables or outputs are added, removed, or retyped; the `accounts` outputs are retained.
- [ ] `tofu validate` passes on both updated modules and `tofu fmt -check` is clean.
