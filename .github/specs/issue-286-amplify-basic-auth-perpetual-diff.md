# Spec: fix(aws/amplify): suppress perpetual basic_auth_credentials diff via lifecycle.ignore_changes
**Issue:** #286
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/amplify` produces a **perpetual diff** on `basic_auth_credentials`. Every `tofu plan` / `terraform plan` reports `~ update in-place` for the credential-bearing resources even when the configured value never changes. Applies succeed but never converge, creating permanent plan noise that can mask real drift.

The module already base64-encodes the supplied `username:password` value correctly before passing it to the provider (`modules/aws/amplify/main.tf:68`, `:87`, `:135`), so this is **not** a module misconfiguration. The non-convergence is upstream provider/AWS behaviour tracked in [hashicorp/terraform-provider-aws#29200](https://github.com/hashicorp/terraform-provider-aws/issues/29200) (open, still reproducible on `aws` provider v6.x):

1. Terraform sends `base64("user:password")`.
2. AWS re-encrypts the password server-side and stores `base64("user:<encrypted-blob>")`; the plaintext is never persisted.
3. On read, `GetApp` / `GetBranch` return `base64("user:<encrypted-blob>")`, which never equals the configured value.
4. Terraform sees a permanent mismatch and reports `update in-place` on every run.

Because the affected resources live **inside** this module, a consumer cannot inject `ignore_changes` from its calling configuration — `lifecycle` meta-arguments are not settable across the module boundary. The fix must therefore live in the module itself.

Affected resources:
- `aws_amplify_app.this` — top-level `basic_auth_credentials` (`main.tf:68`) and `auto_branch_creation_config[0].basic_auth_credentials` (`main.tf:87`).
- `aws_amplify_branch.this` — `basic_auth_credentials` (`main.tf:135`).

Branches/apps that do **not** set credentials never drift; only credential-bearing resources are affected.

See: https://github.com/zachreborn/terraform-modules/issues/286

## 2. Non-goals
- Adding, removing, or retyping any input variable or output (the module interface is unchanged).
- Ignoring any attribute other than `basic_auth_credentials` — `enable_basic_auth` and all other arguments must continue to reconcile normally.
- Auto-detecting or auto-applying genuine credential rotations. The upstream bug makes the read round-trip impossible to reconcile, so rotations are intentionally suppressed (see §5).
- Making `ignore_changes` conditional per branch or per app. `ignore_changes` only accepts a static list, so it cannot be gated on `enable_basic_auth`.
- Changing the existing `base64encode(...)` encoding logic (already correct).
- Touching `aws_amplify_domain_association.this`, the `amplify_notifications_sns` submodule, or the `amplify_notifications_event` submodule.

## 3. Affected module path(s)
- `modules/aws/amplify/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No new variables; no type or default changes. Description-only updates are recommended so the rotation caveat is discoverable in the auto-generated docs (see §7 for the terraform-docs trade-off):
- `basic_auth_credentials` (`string`, default `null`) — append a note that genuine rotations are not auto-applied (see §5 rotation procedure).
- `auto_branch_creation_config` (`object({...})`, default `null`) — extend the inline comment on its `basic_auth_credentials` attribute with the same caveat.
- `branches` (`map(object({...}))`, required) — extend the inline comment on its `basic_auth_credentials` attribute with the same caveat.

### `outputs.tf`
No changes.

### `main.tf`
Two edits only; no new resources, data sources, locals, or child modules.

- `aws_amplify_app.this`: extend the **existing** `lifecycle {}` block (which currently holds two `precondition` blocks at `main.tf:117-126`) with an `ignore_changes` list:
  ```hcl
  lifecycle {
    ignore_changes = [
      basic_auth_credentials,
      auto_branch_creation_config[0].basic_auth_credentials,
    ]
    # existing precondition blocks remain unchanged
  }
  ```
- `aws_amplify_branch.this` (`for_each` over `var.branches`): add a **new** `lifecycle {}` block:
  ```hcl
  lifecycle {
    ignore_changes = [basic_auth_credentials]
  }
  ```

The `for_each` patterns, `dynamic` blocks, `base64encode(...)` expressions, and the `tags` handling are all unchanged.

## 5. Breaking-change assessment
- Breaking: **no**. No input variable, output, or resource address is added, removed, or renamed. Callers need no configuration changes; on upgrade the perpetual diff simply disappears.
- **Behavioural change (non-breaking, must be documented):** once `ignore_changes` is in place, Terraform/OpenTofu will no longer apply a genuine credential rotation. When the credential actually changes, the operator must either temporarily remove the `ignore_changes` entry, taint/replace the resource (`tofu apply -replace=...`), or update the value in the Amplify console. This is the accepted workaround for the upstream bug and must be captured in the README (see §10).

## 6. Checkov / tfsec considerations
- New suppressions: **none**. Adding `lifecycle.ignore_changes` introduces no security-relevant resource configuration, so no new Checkov, tfsec, or Trivy inline ignores are required.
- Existing suppressions affected: **none**. `.checkov.yaml` is not modified.

## 7. terraform-docs impact
- The `main.tf` changes alone (the two `lifecycle.ignore_changes` blocks) do **not** change the auto-generated `<!-- BEGIN_TF_DOCS -->` block: terraform-docs documents providers, modules, resources, inputs, and outputs, and `lifecycle` meta-arguments are not reflected — the Resources table and Inputs/Outputs tables are unaffected.
- **However**, if the implementer applies the recommended `variables.tf` description/comment updates (§4), the Inputs table inside the auto-generated block **will** change and must be regenerated (`pre-commit run --all-files`, or the per-module `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/amplify`). The `Verify - terraform-docs` CI job will fail if the committed README is stale.
- Any manual rotation-caveat prose added to the README's usage/notes area lives **outside** the `BEGIN_TF_DOCS`/`END_TF_DOCS` markers and is not touched by terraform-docs.

## 8. Testing
- `tofu -chdir=modules/aws/amplify init -backend=false && tofu -chdir=modules/aws/amplify validate` (Terraform equivalents also acceptable).
- `tofu fmt -check -diff -recursive`.
- `checkov -d modules/aws/amplify` (locally; CI runs on schedule).
- `pre-commit run --all-files` to confirm terraform-docs is in sync (relevant only if variable descriptions change per §7).
- Functional check against a real app/branch with basic auth enabled:
  - First-time create sets `basic_auth_credentials` + `enable_basic_auth` correctly.
  - Immediately re-running `plan` after a successful `apply` is idempotent — neither `aws_amplify_app.this` (incl. its `auto_branch_creation_config` block) nor `aws_amplify_branch.this` appears as `~ update in-place`.
- Confirm `ignore_changes = [auto_branch_creation_config[0].basic_auth_credentials]` is accepted when `var.auto_branch_creation_config` is `null` (the block is a 0-or-1 `dynamic`), i.e. `validate`/`plan` succeed with no auto-branch config set.

## 9. Open questions
- Confirm during implementation that OpenTofu/Terraform accept the nested `ignore_changes` reference `auto_branch_creation_config[0].basic_auth_credentials` when the dynamic block is absent (empty `for_each`). Expected behaviour: accepted with nothing to ignore, but this must be validated rather than assumed.
- Decide where the rotation caveat lives: appended to the variable descriptions (changes the auto-generated docs, more discoverable) versus a manual README notes section only (keeps the `BEGIN_TF_DOCS` block byte-identical). Recommendation: do both — a short caveat on the descriptions plus a dedicated "Rotating basic auth credentials" notes subsection.
- `ignore_changes` is static, so the branch-level block applies to every entry in the `var.branches` `for_each`. Branches without credentials have nothing to ignore, so this is acceptable; it should be noted in the README.

## 10. Acceptance criteria
- [ ] Running `tofu plan` / `terraform plan` with an **unchanged** `basic_auth_credentials` value reports **no changes** to `aws_amplify_app.this` (including its `auto_branch_creation_config` block) or `aws_amplify_branch.this`.
- [ ] Re-running `plan` immediately after a successful `apply` is idempotent — neither resource appears as `~ update in-place`.
- [ ] First-time creation still works: setting `basic_auth_credentials` + `enable_basic_auth` on a new app/branch applies correctly on create (the `ignore_changes` only suppresses subsequent drift, not the initial value).
- [ ] The module `README.md` documents the rotation caveat — a genuine credential change requires temporarily removing `ignore_changes`, tainting/replacing the resource, or updating the value in the Amplify console.
- [ ] No breaking interface changes — no variables or outputs are added, removed, or retyped.
- [ ] `tofu validate` and `tofu fmt -check` continue to pass for the module, and terraform-docs is regenerated if any variable descriptions changed.
