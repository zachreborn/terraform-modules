# Spec: AWS Guardduty Organization - auto_enable deprecated
**Issue:** #26
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
The `aws_guardduty_organization_configuration` resource's `auto_enable`
argument was deprecated in AWS provider v5.0.0 in favour of
`auto_enable_organization_members` and **removed entirely** in v6.0.0
(hashicorp/terraform-provider-aws#31152, #42251).

Callers using module library v2.11.0 saw the deprecation warning:

```
Warning: Argument is deprecated
  auto_enable = var.auto_enable
Use auto_enable_organization_members instead
```

The resource-level argument migration (`auto_enable` →
`auto_enable_organization_members`) was applied to the module in v2.12.2
(commit `021a634b`). The `auto_enable` variable was removed and replaced
with `auto_enable_organization_members` (type `string`, valid values
`ALL` / `NEW` / `NONE`).

However, two housekeeping items remain:

1. **Provider version constraint** — `main.tf` still declares
   `aws >= 4.0.0`. Since the module already relies on
   `auto_enable_organization_members` (introduced in v5.0.0 and the only
   option in v6.0.0), and `AGENTS.md` mandates `aws >= 6.0.0` for AWS
   modules, the constraint must be bumped.
2. **README usage example** — the README example still shows the old
   module invocation without `auto_enable_organization_members` and does
   not demonstrate the feature-toggle variables added in v8.7.0.

See: https://github.com/zachreborn/terraform-modules/issues/26

## 2. Non-goals
- Refactoring the `aws_guardduty_organization_configuration_feature`
  resource pattern (already implemented correctly via `for_each` +
  locals).
- Migrating the deprecated `datasources` block on the
  `aws_guardduty_organization_configuration` resource — the module
  already uses separate `aws_guardduty_organization_configuration_feature`
  resources instead.
- Adding new GuardDuty features or additional configuration options
  beyond what the provider currently supports.
- Addressing the `aws_guardduty_detector` `datasources` deprecation
  (separate scope — that resource lives in `modules/aws/guardduty/detector`
  if it exists, or is a detector-level concern).

## 3. Affected module path(s)
- `modules/aws/guardduty/organization/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes. The `auto_enable_organization_members` variable already
exists with the correct type, description, default, and validation:

- `auto_enable_organization_members` — `string`, default `"ALL"`,
  valid values `ALL` / `NEW` / `NONE`

All other existing variables are unchanged.

### `outputs.tf`
No changes. The existing `id` output is sufficient.

### `main.tf`
1. **Bump provider version constraint** — change:
   ```hcl
   version = ">= 4.0.0"
   ```
   to:
   ```hcl
   version = ">= 6.0.0"
   ```
   This reflects:
   - The removal of `auto_enable` in provider v6.0.0.
   - The `AGENTS.md` baseline of `aws >= 6.0.0`.

2. **No resource block changes** — all resource blocks already use the
   correct arguments:
   - `aws_guardduty_organization_configuration.this` uses
     `auto_enable_organization_members`.
   - `aws_guardduty_organization_configuration_feature.this` uses
     `auto_enable` which is the **correct and current** argument for
     that resource (not deprecated).

### `README.md`
Update the usage example to:
- Show `auto_enable_organization_members` being passed.
- Show at least one feature-toggle variable (`enable_s3_data_events`).
- Regenerate the `<!-- BEGIN_TF_DOCS -->` block via `terraform-docs`
  (the Requirements table will reflect the new `>= 6.0.0` constraint).

## 5. Breaking-change assessment
- Breaking: **low risk, potentially yes for callers on provider < 6.0**
- Bumping `version = ">= 6.0.0"` means callers still on AWS provider
  v4.x or v5.x will be forced to upgrade. However:
  - The module already uses `auto_enable_organization_members` which
    requires provider ≥ 5.0.0, so v4.x callers were already broken.
  - Provider v6.0.0 has been GA since mid-2025; callers should upgrade.
- The variable interface is unchanged — callers already pass
  `auto_enable_organization_members` (a `string`) rather than the old
  `auto_enable` (a `bool`). This rename happened in v2.12.2 and is not
  part of this change.

## 6. Checkov / tfsec considerations
- New suppressions: **none** — no security-relevant resource
  configuration is being changed.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
Yes. The auto-generated `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/guardduty/organization/README.md` will be updated to
reflect the new `>= 6.0.0` provider constraint in the Requirements
table. This is verified by the `build.yml` CI workflow.

## 8. Testing
- `tofu -chdir=modules/aws/guardduty/organization init -backend=false && tofu -chdir=modules/aws/guardduty/organization validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/guardduty/organization` (locally; CI runs on schedule)
- Verify `terraform-docs` regenerated README matches committed version.

## 9. Open questions
- None. The core deprecation fix is already in place; only the provider
  constraint bump and README update remain.

## 10. Acceptance criteria
- [ ] `modules/aws/guardduty/organization/main.tf` declares
      `aws >= 6.0.0` in the `required_providers` block.
- [ ] No references to the deprecated `auto_enable` argument exist in
      `aws_guardduty_organization_configuration.this`.
- [ ] `README.md` usage example shows `auto_enable_organization_members`.
- [ ] `terraform-docs` auto-generated block is up to date.
- [ ] `tofu fmt -recursive` and `tofu validate` pass.
- [ ] Running `tofu plan` against the module produces no deprecation
      warnings related to `auto_enable`.
