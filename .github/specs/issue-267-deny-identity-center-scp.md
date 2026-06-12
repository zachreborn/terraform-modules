# Spec: Add default SCP to organization module denying sso:CreateInstance in member accounts
**Issue:** #267
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
AWS allows individual member (child) accounts to create their own account-level
IAM Identity Center (formerly AWS SSO) instances. In a multi-account
organization this enables "shadow" Identity Center instances that bypass
centralized access governance, complicate auditing, and create
security/compliance drift.

The `modules/aws/organizations/organization` module currently manages the
`aws_organizations_organization` resource and conditionally composes the
`../policy` child module to create a centralized AWS Backup policy via the
`enable_organization_backup` opt-in toggle (see
`modules/aws/organizations/organization/main.tf:38-48`). It does not yet manage
any Service Control Policy (SCP).

This spec adds an opt-out default SCP that denies `sso:CreateInstance`
organization-wide, so Identity Center can only be managed from the management
account / delegated administrator. It follows the existing
`enable_organization_backup` / `centralized_backup` precedent: a boolean toggle
gates a `for_each` call to the `../policy` module, with the policy document
loaded from a JSON file under the module's `policies/` directory (consistent
with `policies/enable_backup_policy.json`, consumed via `file(...)`).

The originating issue, its triage classification comment, and the proposed
inputs/outputs are tracked at
https://github.com/zachreborn/terraform-modules/issues/267.

## 2. Non-goals
- No changes to the `modules/aws/organizations/policy` child module — it already
  supports `type = "SERVICE_CONTROL_POLICY"` and is used as-is.
- No new standalone `policy_attachment` child module. There is no
  organization-level attachment module today (the only
  `aws_organizations_policy_attachment` usage lives inline in
  `modules/services/aws_backup_organization/main.tf:153`). Attaching a policy to
  the organization's own root is intrinsic to this module's domain, so the
  attachment is declared inline here rather than as a cross-cutting child module.
- No support for denying additional `sso:*` actions or other identity-governance
  controls beyond `sso:CreateInstance`. The policy document is fixed to the
  statement provided in the issue.
- No automatic mutation of the caller-supplied `enabled_policy_types` value (the
  module will not silently inject `SERVICE_CONTROL_POLICY`); the dependency is
  enforced via a precondition and documented instead (see §5 and §9).
- No changes to other organization submodules (`account`, `ou`,
  `delegated_admin`, `delegated_resource_policy`).

## 3. Affected module path(s)
- `modules/aws/organizations/organization/` (existing — variables, outputs,
  main, README)
- `modules/aws/organizations/organization/policies/deny_identity_center_instance_scp.json`
  (new file — the SCP document)

It composes the existing `modules/aws/organizations/policy/` module (no change to
that module).

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
New variables to add to
`modules/aws/organizations/organization/variables.tf`:
- `enable_identity_center_scp` — `bool`, default `true`. Opt-out toggle. When
  `true`, creates the deny-`sso:CreateInstance` SCP via the `../policy` module.
  Mirrors `enable_organization_backup`.
- `identity_center_scp_name` — `string`, default
  `"DenyMemberAccountIdentityCenter"`. Name passed to the `../policy` module.
- `identity_center_scp_description` — `string`, default a descriptive string
  (e.g. "Denies sso:CreateInstance org-wide so member accounts cannot create
  account-level IAM Identity Center instances."). Passed to `../policy`.
- `attach_identity_center_scp` — `bool`, default `true`. When `true`, attaches
  the created SCP to the targets in `identity_center_scp_target_ids` (defaulting
  to the organization root). When `false`, the policy is created but not
  attached (matching the create-only backup precedent).
- `identity_center_scp_target_ids` — `list(string)`, default `null`. Optional
  list of org root / OU / account IDs to attach the SCP to. When `null` and
  `attach_identity_center_scp = true`, the module attaches to the organization
  root (`aws_organizations_organization.org.roots[0].id`).

Existing `tags` variable is reused for the created policy (no change).

### `outputs.tf`
New outputs to add to
`modules/aws/organizations/organization/outputs.tf`:
- `identity_center_scp_id` — the SCP policy ID, or `null` when the toggle is
  `false` (read via `one(...)`/try over the `for_each`-gated module instance).
- `identity_center_scp_arn` — the SCP policy ARN, or `null` when disabled.
- `identity_center_scp_attachment_target_ids` — list of target IDs the SCP was
  attached to, empty when attachment is disabled.

### `main.tf`
New blocks to add to
`modules/aws/organizations/organization/main.tf` (under a new
`# Identity Center Service Control Policy` section header following the repo
comment-header convention):
- `module "identity_center_scp"` — sources `../policy`, gated with
  `for_each = var.enable_identity_center_scp ? { "identity_center_scp" = "true" } : {}`
  (mirrors the `centralized_backup` pattern). Arguments:
  `content = file("policies/deny_identity_center_instance_scp.json")`,
  `description = var.identity_center_scp_description`,
  `name = var.identity_center_scp_name`,
  `type = "SERVICE_CONTROL_POLICY"`, `tags = var.tags`.
- `resource "aws_organizations_policy_attachment" "identity_center_scp"` —
  declared inline (same organizations domain; no separate attachment module
  exists). `for_each` over the resolved target IDs only when both
  `var.enable_identity_center_scp` and `var.attach_identity_center_scp` are
  `true` (default targets to `aws_organizations_organization.org.roots[0].id`
  when `identity_center_scp_target_ids` is `null`). `policy_id` references the
  `identity_center_scp` module output.
- A `precondition` (on the attachment resource or via a `terraform_data`/`check`
  block) that fails with a clear message when `enable_identity_center_scp` is
  `true` but `SERVICE_CONTROL_POLICY` is not present in
  `var.enabled_policy_types`, so callers get an actionable error instead of an
  opaque provider failure.

New policy document file
`modules/aws/organizations/organization/policies/deny_identity_center_instance_scp.json`
containing exactly the statement from the issue:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyMemberAccountInstances",
            "Effect": "Deny",
            "Action": [
                "sso:CreateInstance"
            ],
            "Resource": "*"
        }
    ]
}
```

## 5. Breaking-change assessment
- Breaking: **yes** (behavioral, opt-out default).
- Because `enable_identity_center_scp` defaults to `true`, existing callers will
  create the new SCP on their next apply, and — because
  `attach_identity_center_scp` also defaults to `true` — will attach it to the
  organization root, beginning to deny `sso:CreateInstance` in member accounts.
- The apply will **fail** for callers whose organization does not have
  `SERVICE_CONTROL_POLICY` in `enabled_policy_types` (today the variable defaults
  to `null`). The new precondition surfaces this as a clear error.
- Migration options for callers who want to preserve current behavior:
  - Set `enable_identity_center_scp = false` (no new resources; clean plan), or
  - Set `attach_identity_center_scp = false` to create-but-not-attach (matches
    the backup precedent and has no enforcement effect), and
  - Ensure `enabled_policy_types` includes `"SERVICE_CONTROL_POLICY"` before
    enabling enforcement.

## 6. Checkov / tfsec considerations
- New suppressions: **none.** The change adds an `aws_organizations_policy` (via
  the existing `../policy` module) and an `aws_organizations_policy_attachment`;
  these resource types are not flagged by the repo's Checkov/tfsec policy, and
  the SCP is security-positive (a deny statement).
- Existing suppressions affected: **none.**

## 7. terraform-docs impact
- Yes. The `<!-- BEGIN_TF_DOCS -->` block in
  `modules/aws/organizations/organization/README.md` will change to include the
  new inputs (`enable_identity_center_scp`, `identity_center_scp_name`,
  `identity_center_scp_description`, `attach_identity_center_scp`,
  `identity_center_scp_target_ids`), the new outputs
  (`identity_center_scp_id`, `identity_center_scp_arn`,
  `identity_center_scp_attachment_target_ids`), and the new `../policy` module
  call. A usage example and a prerequisite note about
  `enabled_policy_types = ["SERVICE_CONTROL_POLICY"]` will be added to the
  hand-written portion of the README.
- No other module READMEs change (`modules/aws/organizations/policy` is used
  unmodified).

## 8. Testing
- `tofu -chdir=modules/aws/organizations/organization init -backend=false && tofu -chdir=modules/aws/organizations/organization validate`
- `tofu fmt -check -diff -recursive`
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/organizations/organization`
  (or `pre-commit run --all-files`) and commit the regenerated block.
- `checkov -d modules/aws/organizations/organization` (locally; CI runs on
  schedule).
- Manual review of the rendered `for_each` gating: confirm that
  `enable_identity_center_scp = false` produces zero new resources in
  `tofu plan`, and that the default (`true`) path plans the policy + root
  attachment.

## 9. Open questions
- **Attachment behavior (resolved):** the SCP will be **attached to the
  organization root by default** (`attach_identity_center_scp = true`,
  `identity_center_scp_target_ids = null` → root), since the issue's stated
  intent ("block creation … within any child organizations") requires the
  policy to be attached to take effect. Callers may override targets or disable
  attachment.
- **`enabled_policy_types` dependency (resolved):** the module will **not**
  auto-inject `SERVICE_CONTROL_POLICY` into `enabled_policy_types`; instead a
  precondition fails fast with a clear message and the README documents the
  prerequisite. Implementation may revisit whether to also add
  `"SERVICE_CONTROL_POLICY"` to the `enabled_policy_types` default — flagged for
  reviewer decision, as changing that default is itself a broader behavioral
  change.

## 10. Acceptance criteria
- [ ] New `enable_identity_center_scp` variable (`bool`, default `true`) added to
  `modules/aws/organizations/organization`.
- [ ] When `true` (default), an `aws_organizations_policy` of type
  `SERVICE_CONTROL_POLICY` containing the provided deny-`sso:CreateInstance`
  statement is created via the `../policy` module, sourced from
  `policies/deny_identity_center_instance_scp.json` loaded with `file(...)`.
- [ ] When `false`, no new resources are created and existing callers get a
  clean `tofu plan` (non-breaking for opt-out callers).
- [ ] Attachment behavior is implemented and documented: the SCP is attached to
  the organization root by default, with `attach_identity_center_scp` and
  `identity_center_scp_target_ids` to override.
- [ ] Module outputs expose the SCP `id` and `arn` (null when disabled) plus the
  attachment target IDs.
- [ ] The `SERVICE_CONTROL_POLICY` prerequisite is enforced via a precondition
  and documented in the README.
- [ ] `README.md` updated with a usage example and regenerated `terraform-docs`
  block.
- [ ] `tofu fmt -check -diff -recursive` and the `Build` + `Test` CI jobs pass.
