# Spec: fix(aws/organizations): resolve spurious accounts ordering drift (ignore_changes and output edits are ineffective)
**Issue:** #190
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
The `aws_organizations_organizational_unit.this` resource in `modules/aws/organizations/ou` and the `aws_organizations_organization.org` resource in `modules/aws/organizations/organization` both expose a computed `accounts` attribute that the AWS provider types as an **ordered `list`**. The AWS Organizations API returns accounts in a non-deterministic order, so a reorder between runs surfaces under the "Objects have changed outside of OpenTofu/Terraform" section of a plan — the same account appearing as both removed (`-`) and added (`+`) purely because its index changed, even though no account has moved. A `list` is positionally compared while a `set` is not, but the attribute type is provider-defined and cannot be overridden in the module.
`accounts` is a **read-only computed attribute**: it is never settable in the module configuration, and Terraform/OpenTofu cannot modify it regardless of plan content.

### Confirmed reproduction
The drift reproduces on the reported toolchain (OpenTofu 1.12.1, `hashicorp/aws` 6.4.0). A `tofu plan` with no pending configuration changes reported `accounts` reordering under "Objects have changed outside of OpenTofu" for three managed resources at once:
- `module.dev_ou.aws_organizations_organizational_unit.this`
- `module.staging_ou.aws_organizations_organizational_unit.this`
- `module.slfcu_organization.aws_organizations_organization.org`
The churn appeared after new accounts (e.g. `dev.opstooling`, `test.opstooling`) were created, which caused the API to return the list in a new order. No accounts were moved. This confirms the symptom is real on the supported toolchain (and is not filtered out by the post-Terraform-1.2 plan-relevance behavior).

### Why `ignore_changes = [accounts]` does not work
Issue #190 and the first draft of this spec proposed adding `ignore_changes = [accounts]` to each `lifecycle {}` block. That mechanism does **not** work for this attribute, for two independent reasons:
1. **`ignore_changes` is a documented no-op on computed-only attributes.** When a `Computed` (non-`Optional`) attribute is listed in `ignore_changes`, OpenTofu/Terraform ignores the entry and emits `Warning: Redundant ignore_changes element` — *"The attribute `accounts` is decided by the provider alone and therefore there can be no configured value to compare with. Including this attribute in `ignore_changes` has no effect."* See [hashicorp/terraform#30517](https://github.com/hashicorp/terraform/issues/30517) and the identical real-world case in [cloudflare/terraform-provider-cloudflare#7099](https://github.com/cloudflare/terraform-provider-cloudflare/issues/7099).
2. **`ignore_changes` does not govern the "changed outside" notice anyway.** `ignore_changes` only affects the configuration-vs-state comparison that produces planned actions. The "Objects have changed outside" section reports the prior-state-vs-refreshed-remote comparison performed during refresh — a separate mechanism. Per HashiCorp core maintainer apparentlymart, the only built-in lever that disables refresh-time drift detection is the global `-refresh=false` flag — see [discuss.hashicorp.com #24776](https://discuss.hashicorp.com/t/objects-have-changed-outside-of-terraform-ignore-changes-ignored/24776).
The `modules/aws/amplify` precedent (issue #286) is **not** analogous: it ignores `basic_auth_credentials`, a **configurable input** that AWS mutates server-side — the legitimate `ignore_changes` use case. `accounts` has no configurable counterpart.

### Why editing `outputs.tf` does not work either
Sorting or removing the `accounts` output cannot fix this drift:
- The notice is reported against the **managed resources** (`aws_organizations_organization.org` / `aws_organizations_organizational_unit.this`), not against any output. Outputs never appear in the "Objects have changed outside" section.
- A managed resource persists **all** of its computed attributes in state regardless of whether anything references them, so `…org.accounts` would still be stored and still drift on refresh **even if the `accounts` output were deleted**.
- Outputs are derived projections evaluated from resource state; they do not participate in refresh drift detection. `sort(...)` on the output only changes what downstream consumers see, leaving the resource's stored list (and the prior-vs-refreshed comparison) untouched.
Sorting the output by `id` remains a reasonable *independent* enhancement for any downstream consumer that iterates the list positionally, but it is orthogonal to this issue and is out of scope here.

Affected resources (existing `lifecycle {}` blocks that must be preserved exactly):
- `modules/aws/organizations/ou/main.tf:11-18` — `aws_organizations_organizational_unit.this`, existing `lifecycle { create_before_destroy = true }`.
- `modules/aws/organizations/organization/main.tf:15-23` — `aws_organizations_organization.org`, existing `lifecycle { prevent_destroy = true }`.
See: https://github.com/zachreborn/terraform-modules/issues/190

## 2. Non-goals
- Adding, removing, renaming, or retyping any input variable or output. The public interface of both modules is unchanged.
- Adding `ignore_changes = [accounts]` (or any `ignore_changes` entry for a computed-only attribute). It is a no-op and only adds a warning; see §1.
- Editing `outputs.tf` (sorting or removing the `accounts` outputs) as a fix for the drift. It does not work; see §1. The existing `accounts` outputs (`ou/outputs.tf:1-4`, `organization/outputs.tf:4-7`) are retained so callers can still read the account list.
- Changing the existing `lifecycle` meta-arguments already present — `create_before_destroy = true` on the OU and `prevent_destroy = true` on the organization must be preserved exactly.
- Retyping `accounts` from `list` to `set`. The attribute type is provider-defined and cannot be overridden in the module.
- Touching any other resource or child module in the organization module (`module.centralized_root`, `module.centralized_backup`, `module.identity_center_scp`, `aws_organizations_policy_attachment.identity_center_scp`).

## 3. Affected module path(s)
- `modules/aws/organizations/ou/` (existing)
- `modules/aws/organizations/organization/` (existing)

## 4. Proposed design
**There is no clean in-module fix.** Reproduction is confirmed (§1), and both candidate in-module mechanisms — `ignore_changes` and output edits — are ineffective for a read-only computed attribute. The resolution is therefore a combination of upstream escalation and documentation rather than a `.tf` change.

### Resolution options (in priority order)
- **Provider-side fix (preferred, durable):** the real fix lives in `hashicorp/aws` — e.g. a plan modifier such as `UseStateForUnknown`, sorting the returned list, or treating order as insignificant. This module cannot change provider plan behavior. Search for an existing upstream issue for non-deterministic `accounts` ordering on `aws_organizations_organization` / `aws_organizations_organizational_unit`; open one if none exists, and link it from #190.
- **Caller-side operational guidance:** document that the noise is cosmetic and can be quieted at invocation time with `-refresh=false` (or simply reviewed and ignored). This is a CLI flag and cannot be baked into the module.
- **Accept as known cosmetic drift (recommended default):** add a short human-authored note to each module README (outside the `BEGIN_TF_DOCS`/`END_TF_DOCS` markers) explaining the behavior, that it is harmless (the attribute is read-only and the module never manages membership), and that there is no in-module suppression.

### `variables.tf`
No changes to either module. No variables are added, removed, or retyped.

### `outputs.tf`
No changes to either module. The existing `accounts` outputs are retained (editing them does not address the drift; see §1):
- `ou/outputs.tf`: `accounts`, `arn`, `id` — unchanged.
- `organization/outputs.tf`: `accounts`, `master_account_arn`, `master_account_email`, `master_account_id`, `arn`, `id`, `roots`, `identity_center_scp_id`, `identity_center_scp_arn`, `identity_center_scp_attachment_target_ids` — unchanged.

### `main.tf`
No resource-argument or `lifecycle` change. The existing `lifecycle {}` blocks (`create_before_destroy = true` on the OU, `prevent_destroy = true` on the organization) are preserved exactly. `ignore_changes = [accounts]` must **not** be added. The only file that may change under this spec is each module's `README.md` (a documentation note), which alters no `.tf`.

## 5. Breaking-change assessment
- Breaking: **no**. This spec proposes no interface change — no input variable, output, or resource address is added, removed, or renamed.
- Behavioural note: reconciliation is unchanged. Under the recommended "accept as cosmetic drift" option the only change is a README note. The `accounts` outputs continue to expose the most recently refreshed value.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. No security-relevant resource configuration changes, so no new Checkov, tfsec, or Trivy inline ignores are required, and `.checkov.yaml` is not modified.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
**None.** No variable, output, or resource address changes, so the `<!-- BEGIN_TF_DOCS -->` blocks in both module READMEs remain byte-identical and the `Verify - terraform-docs` CI job passes without regeneration. Any human-authored note about the cosmetic drift lives outside the `BEGIN_TF_DOCS`/`END_TF_DOCS` markers and is not managed by terraform-docs.

## 8. Testing
- Reproduction (done): on OpenTofu 1.12.1 / `hashicorp/aws` 6.4.0, `tofu plan` with no pending changes reports `accounts` reordering under "Objects have changed outside of OpenTofu" for `aws_organizations_organizational_unit.this` (dev/staging OUs) and `aws_organizations_organization.org`. Attach the captured plan output to #190.
- Negative confirmation (illustrative): adding `ignore_changes = [accounts]` produces a `Redundant ignore_changes element` warning and the drift notice persists; sorting/removing the `accounts` output leaves the resource-level notice unchanged. These confirm why neither in-module approach is pursued.
- If a README note is added: run `pre-commit run --all-files` (or per-module `terraform-docs`) to confirm the `BEGIN_TF_DOCS` blocks remain byte-identical; `tofu fmt -check -diff -recursive` stays clean (no `.tf` changed).
- `checkov -d modules/aws/organizations/ou` and `checkov -d modules/aws/organizations/organization` (locally; CI runs on schedule).
- Confirm `prevent_destroy = true` (organization) and `create_before_destroy = true` (OU) remain in effect.

## 9. Open questions
- Is there an existing upstream `hashicorp/aws` issue for non-deterministic `accounts` ordering on `aws_organizations_organization` / `aws_organizations_organizational_unit`? If not, do we open one and track it from #190?
- Is the team comfortable resolving #190 as "documented cosmetic drift + upstream provider issue" (no `.tf` change), given that no effective in-module mechanism exists?
- Optional/separate: should the `accounts` outputs be sorted by `id` as a general consumer-friendliness improvement (tracked independently of this drift issue)?

## 10. Acceptance criteria
- [ ] `ignore_changes = [accounts]` is NOT added to either module (it is a no-op for a computed-only attribute and emits a `Redundant ignore_changes element` warning).
- [ ] `outputs.tf` is not edited as a drift fix; the `accounts` outputs are retained.
- [ ] The existing `lifecycle {}` blocks are preserved exactly — `create_before_destroy = true` on the OU and `prevent_destroy = true` on the organization.
- [ ] The reproduction evidence (plan output on OpenTofu 1.12.1 / `aws` 6.4.0) is recorded on #190.
- [ ] The chosen resolution is documented: an upstream `hashicorp/aws` issue is linked (or opened), and/or a README note describing the cosmetic drift is added to both modules.
- [ ] No breaking interface changes — no variables or outputs are added, removed, or retyped.
- [ ] `tofu fmt -check` is clean and (if any `.tf` changed, which is not expected) `tofu validate` passes on both modules.
