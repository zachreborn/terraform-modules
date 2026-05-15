# Spec: Guardduty auto_enable is deprecated
**Issue:** #37
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
When using the `modules/aws/guardduty/organization` module at `v2.11.0`, Terraform
emits a deprecation warning on `aws_guardduty_organization_configuration.this`:

```
Warning: Argument is deprecated
  auto_enable = var.auto_enable
Use auto_enable_organization_members instead
```

The AWS provider deprecated the `auto_enable` argument on
`aws_guardduty_organization_configuration` in favour of
`auto_enable_organization_members`, which accepts `ALL`, `NEW`, or `NONE`
(replacing the former boolean).

**Current state on `main`:** The core migration was completed in **v2.12.2**
(commit `021a634b`). The resource already reads
`auto_enable_organization_members = var.auto_enable_organization_members` and
the old `auto_enable` boolean variable has been removed. A subsequent release
(**v8.7.0**, commit `d3852528`) added the
`aws_guardduty_organization_configuration_feature` resource, which also
references `var.auto_enable_organization_members` via its own `auto_enable`
argument (this is *not* the deprecated attribute — it is the correct argument
name for that resource type).

**Remaining work:**
- The module's `required_providers` block still constrains `aws >= 4.0.0`.
  Per `AGENTS.md`, all AWS modules should require `aws >= 6.0.0`. Bumping the
  constraint documents the minimum provider version that supports
  `auto_enable_organization_members` and aligns with repo conventions.
- The issue should be verified closed by confirming `terraform plan` produces
  zero deprecation warnings with the current `main` code and a modern AWS
  provider version.

## 2. Non-goals
- Refactoring the GuardDuty module beyond the deprecation fix (e.g. adding new
  feature detectors, restructuring provider aliases).
- Changing default values for `auto_enable_organization_members` (current
  default `"ALL"` is appropriate).
- Modifying any module outside `modules/aws/guardduty/organization/`.

## 3. Affected module path(s)
- `modules/aws/guardduty/organization/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

The core variable/resource migration is already on `main`. The only remaining
change is the provider version constraint.

### `variables.tf`
No changes required. The current variable set is correct:

- `auto_enable_organization_members` — `string`, default `"ALL"`, validation
  `^(ALL|NEW|NONE)$` — already present, replaces the former `auto_enable` bool.

All other variables (`enable`, `finding_publishing_frequency`,
`admin_account_id`, feature-toggle bools) are unchanged.

### `outputs.tf`
No changes required. The single `id` output remains.

### `main.tf`
- **`terraform.required_providers.aws.version`**: change from `">= 4.0.0"` to
  `">= 6.0.0"` to match `AGENTS.md` conventions and document the minimum
  provider version supporting `auto_enable_organization_members`.
- All resource blocks remain unchanged:
  - `aws_guardduty_detector.this`
  - `aws_guardduty_organization_admin_account.this`
  - `aws_guardduty_organization_configuration.this` — already uses
    `auto_enable_organization_members`
  - `aws_guardduty_organization_configuration_feature.this` — uses
    `auto_enable` (correct attribute name for this resource; not deprecated)

## 5. Breaking-change assessment
- Breaking: **yes (already shipped in v2.12.2)**
- Callers that previously passed `auto_enable = true/false` must replace it
  with `auto_enable_organization_members = "ALL"` (or `"NEW"` / `"NONE"`).
  Since this break already shipped in v2.12.2, no *new* breaking change is
  introduced by this spec — only the provider floor bump from `>= 4.0.0` to
  `>= 6.0.0`, which may require callers on very old provider versions to
  upgrade.

## 6. Checkov / tfsec considerations
- New suppressions: none.
- Existing suppressions affected: none.

## 7. terraform-docs impact
Yes — the auto-generated `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/guardduty/organization/README.md` will update the **Requirements**
table to show `aws >= 6.0.0` instead of `>= 4.0.0`. CI will regenerate this
automatically on the implementation PR.

## 8. Testing
- `terraform -chdir=modules/aws/guardduty/organization init -backend=false && terraform -chdir=modules/aws/guardduty/organization validate`
- `terraform fmt -check -diff -recursive`
- `checkov -d modules/aws/guardduty/organization` (locally; CI runs on schedule)
- Confirm `terraform plan` produces no deprecation warnings with `hashicorp/aws >= 6.0.0`.

## 9. Open questions
- Should a `UPGRADE.md` or migration note be added documenting the
  `auto_enable` → `auto_enable_organization_members` change for users on
  `v2.11.0` or earlier? This is already a shipped break (v2.12.2) so it may
  not be necessary.

## 10. Acceptance criteria
- Running `terraform plan` against `modules/aws/guardduty/organization` with
  `hashicorp/aws >= 6.0.0` produces **no deprecation warnings**.
- `auto_enable_organization_members` is exposed as a variable with type
  `string`, default `"ALL"`, and validation constraining values to `ALL`,
  `NEW`, `NONE`.
- The `required_providers` block requires `aws >= 6.0.0`.
- `terraform validate` and `terraform fmt -check` pass.
- The auto-generated terraform-docs block in `README.md` reflects the updated
  provider constraint.
