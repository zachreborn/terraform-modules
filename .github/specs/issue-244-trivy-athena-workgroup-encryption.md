# Spec: fix(aws/athena/workgroup): add Trivy suppression for caller-controlled encryption (AVD-AWS-0006)
**Issue:** #244
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
The `Test/Linter` CI job (super-linter slim-v8.6.0, which bundles Trivy) fails with a HIGH finding on the Athena workgroup module:

```
AVD-AWS-0006 (HIGH): Workgroup does not have encryption configured.
```

This is a false positive. The module already exposes encryption as a caller-controlled option via `var.encryption_option`, which gates a `dynamic "encryption_configuration"` block inside `result_configuration` (`modules/aws/athena/workgroup/main.tf:51-57`). Trivy's static analysis cannot evaluate dynamic block conditions or variable defaults, so it flags the resource as unencrypted regardless of how the caller configures it.

This is the same class of false positive handled by the `.checkov.yaml` "CONFIGURABLE BY CALLER" section and by existing `#tfsec:ignore:` inline comments elsewhere in the repo (e.g., `modules/aws/vpc/main.tf:72`, `modules/aws/vpc/main.tf:221`).

Failing CI run: https://github.com/zachreborn/terraform-modules/actions/runs/26485694247

## 2. Non-goals
- Changing the module's default encryption behaviour (e.g., defaulting `encryption_option` to `"SSE_S3"`). The module intentionally defers this to the caller.
- Refactoring the Athena workgroup module or adding new variables/outputs.
- Suppressing any other Trivy findings beyond AVD-AWS-0006 on this specific resource.

## 3. Affected module path(s)
- `modules/aws/athena/workgroup/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes.

### `outputs.tf`
No changes.

### `main.tf`
Add a single Trivy inline ignore comment directly above the `aws_athena_workgroup` resource block:

```hcl
#trivy:ignore:AVD-AWS-0006 # Encryption is caller-controlled via var.encryption_option; static analysis cannot evaluate the dynamic block
resource "aws_athena_workgroup" "this" {
```

This follows the same inline-comment pattern used by `#tfsec:ignore:` elsewhere in the repo (e.g., `modules/aws/vpc/main.tf`). No other lines in the file change.

## 5. Breaking-change assessment
- Breaking: no
- The change adds a comment only. No inputs, outputs, resource arguments, or runtime behaviour are modified. Callers require zero changes.

## 6. Checkov / tfsec considerations
- New suppressions: none (this is a Trivy suppression, not Checkov/tfsec).
- Existing suppressions affected: none.
- The `.checkov.yaml` file is not modified. AVD-AWS-0006 is a Trivy-specific rule ID that is not present in Checkov's check catalogue; the inline `#trivy:ignore:` directive is the correct mechanism.

## 7. terraform-docs impact
No. The auto-generated `<!-- BEGIN_TF_DOCS -->` block is not affected because no variables, outputs, or resource signatures change. Only a comment line is added.

## 8. Testing
- `tofu -chdir=modules/aws/athena/workgroup init -backend=false && tofu -chdir=modules/aws/athena/workgroup validate` — must still pass (comment-only change).
- `tofu fmt -check -diff -recursive` — must still pass (comments don't affect formatting).
- `trivy config --severity HIGH modules/aws/athena/workgroup/` — AVD-AWS-0006 should no longer appear.
- CI `Test/Linter → Linted: TRIVY` job must pass on the implementation PR.

## 9. Open questions
None — the approach is straightforward and consistent with existing repo patterns.

## 10. Acceptance criteria
- [ ] `#trivy:ignore:AVD-AWS-0006` comment is present above `resource "aws_athena_workgroup" "this"` in `modules/aws/athena/workgroup/main.tf`.
- [ ] `Test/Linter → Linted: TRIVY` passes on CI without suppressing other Trivy findings.
- [ ] No functional change to the module behaviour — no variables, outputs, or resource arguments are modified.
- [ ] `tofu validate` and `tofu fmt -check` continue to pass for the module.
