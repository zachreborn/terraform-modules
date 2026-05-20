# Spec: feat(security_group): expose tags_all output
**Issue:** #210
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
Callers of `modules/aws/security_group` that need the fully merged tag set
(provider `default_tags` + module-level tags) must currently recompute the
merge externally. AWS exposes the effective tags on every resource via the
read-only `tags_all` attribute. Adding a single output that surfaces
`aws_security_group.sg.tags_all` lets callers reference the authoritative
tag map directly, eliminating duplication and drift risk.

See: https://github.com/zachreborn/terraform-modules/issues/210

## 2. Non-goals
- Renaming or refactoring the existing `aws_security_group.sg` resource.
- Adding `tags_all` outputs to other AWS modules (can be done in a
  follow-up if the pattern proves useful).
- Changing the existing tagging logic or the `tags` variable contract.

## 3. Affected module path(s)
- `modules/aws/security_group/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes. Existing variables remain as-is:

- `description` (string, default `"Terraform created SG"`)
- `name` (string, required)
- `tags` (map, default `{}`)
- `vpc_id` (string, required)

### `outputs.tf`
Add one new output after the existing `id` and `name` outputs:

- **`tags_all`**
  - type: `map(string)` (implicit from the attribute)
  - value: `aws_security_group.sg.tags_all`
  - description: `"A map of tags assigned to the security group, including provider default tags"`

Existing outputs (`id`, `name`) are unchanged.

### `main.tf`
No changes. The resource `aws_security_group.sg` already exists and
exposes the `tags_all` computed attribute natively. No new resources,
data sources, locals, count/for_each patterns, lifecycle rules, or
tagging changes are required.

> **Note:** The issue body references `aws_security_group.this.tags_all`,
> but the actual resource name in the module is `aws_security_group.sg`.
> The implementation must use `aws_security_group.sg.tags_all`.

## 5. Breaking-change assessment
- Breaking: **no**
- This is a purely additive change — a new output is declared. No
  existing inputs, outputs, or resources are modified or removed.
  Callers that do not reference the new output are unaffected.

## 6. Checkov / tfsec considerations
- New suppressions: **none** — adding an output declaration does not
  introduce any security-relevant resource configuration.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
Yes. The auto-generated `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/security_group/README.md` will be updated to include the
new `tags_all` output in the Outputs table. This happens automatically
via the `build.yml` CI workflow — no manual README edits are needed.

## 8. Testing
- `terraform -chdir=modules/aws/security_group init -backend=false && terraform -chdir=modules/aws/security_group validate`
- `terraform fmt -check -diff -recursive`
- `checkov -d modules/aws/security_group` (locally; CI runs on schedule)
- Verify the new output appears in `terraform-docs` generated output.

## 9. Open questions
- None. The change is straightforward and self-contained.

## 10. Acceptance criteria
- [ ] `modules/aws/security_group/outputs.tf` declares a new `tags_all`
      output sourcing from `aws_security_group.sg.tags_all`.
- [ ] Output description follows the same style as existing outputs.
- [ ] `terraform-docs` auto-update keeps the README in sync (handled by
      `build.yml`).
- [ ] No breaking changes — this is additive only.
- [ ] `terraform fmt -recursive` and `terraform validate` pass.
