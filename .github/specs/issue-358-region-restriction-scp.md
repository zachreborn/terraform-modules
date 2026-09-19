# Spec: Add opt-in Region-restriction SCP to organizations/organization module
**Issue:** #358
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
AWS accounts have every commercial Region enabled by default. Regions a workload
never uses are unmonitored attack surface: if credentials leak (or an automation
job runs with an accidental `--region`), resources can be created where
GuardDuty, CloudTrail, Config, and cost alerting are not actively watched,
delaying detection. A `Deny` + `NotAction` + `aws:RequestedRegion` Service
Control Policy (SCP) is the standard AWS Organizations guardrail for this and
ships as the AWS Control Tower preventive control `CT.MULTISERVICE.PV.1` /
`GRREGIONDENY` ("Deny access to AWS based on the requested AWS Region").

The `modules/aws/organizations/organization` module already manages the
`aws_organizations_organization` resource and composes the `../policy` child
module for two policies today: a centralized AWS Backup policy
(`enable_organization_backup`) and an Identity Center deny SCP
(`enable_identity_center_scp`, see `modules/aws/organizations/organization/main.tf:68-92`).
The Identity Center SCP established the reusable
`enable_*_scp` / `*_scp_name` / `*_scp_description` / `attach_*_scp` /
`*_scp_target_ids` variable convention, a `for_each`-gated `../policy` call, an
inline `aws_organizations_policy_attachment` resource defaulting to the
organization root, and a `precondition` that requires `SERVICE_CONTROL_POLICY`
in `enabled_policy_types` (issue #267 / `.github/specs/issue-267-deny-identity-center-scp.md`).

This spec adds a Region-restriction SCP to the same module, following that
precedent, with two deliberate differences driven by this control's semantics:

1. It is **opt-in** (`enable_region_scp` defaults to `false`) rather than
   opt-out. There is no Region allow-list that is safe to assume for every
   caller, so defaulting it on would begin denying regional API calls org-wide
   on a caller's next `apply` with no action on their part.
2. Its policy document is **dynamic** — it interpolates the caller's
   `allowed_regions`, an optional exempted-principal condition, and an optional
   additional-actions list — so it cannot be a fully static file consumed with
   `file(...)` the way `policies/deny_identity_center_instance_scp.json` is.

The originating issue, its triage classification comment, and the proposed
inputs/outputs are tracked at
https://github.com/zachreborn/terraform-modules/issues/358.

## 2. Non-goals
- No changes to the `modules/aws/organizations/policy` child module — it already
  supports `type = "SERVICE_CONTROL_POLICY"` and is composed as-is.
- No new standalone `policy_attachment` child module. Consistent with
  `identity_center_scp`, the `aws_organizations_policy_attachment` is declared
  inline in this module (attaching to the org's own root is intrinsic to this
  module's domain).
- Not a wrapper around AWS Control Tower's managed Region-deny control. This
  module manages a plain `aws_organizations_policy`; it does not manage Control
  Tower, landing zones, or the `CT.MULTISERVICE.PV.1` managed control. The
  Control Tower policy is used only as the reference for the `NotAction`
  global-service list.
- No automatic mutation of the caller-supplied `enabled_policy_types` (the
  module will not silently inject `SERVICE_CONTROL_POLICY`); the dependency is
  enforced via a `precondition` and documented, matching `identity_center_scp`.
- No Resource Control Policy (RCP) variant and no `aws:PrincipalRegion` /
  service-endpoint-based variants — only a `SERVICE_CONTROL_POLICY` keyed on
  `aws:RequestedRegion`.
- No enforcement of the management-account exemption (SCPs never apply to the
  management account; this is documented in the README, not enforced in code).
- No changes to other organization submodules (`account`, `ou`,
  `delegated_admin`, `delegated_resource_policy`).

## 3. Affected module path(s)
- `modules/aws/organizations/organization/` (existing — `variables.tf`,
  `outputs.tf`, `main.tf`, `README.md`)
- `modules/aws/organizations/organization/policies/deny_regions_scp.json` (new
  file — the Region-deny SCP document; a `templatefile` template, not a static
  document — see §4 `main.tf` and §9)

It composes the existing `modules/aws/organizations/policy/` module (no change
to that module).

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
New variables to add to `modules/aws/organizations/organization/variables.tf`
(under a new `# Region Restriction Service Control Policy` section header):
- `enable_region_scp` — `bool`, default `false`. Opt-in toggle. When `true`,
  creates the Region-deny SCP via the `../policy` module. Deliberately defaults
  `false` (unlike `enable_identity_center_scp`).
- `allowed_regions` — `list(string)`, **no default**. The Regions where regional
  service actions remain allowed (e.g. `["us-east-1", "us-west-2"]`). A
  `validation` block requires a non-empty list **when** `enable_region_scp` is
  `true` (the rule must remain satisfiable when the feature is disabled, e.g.
  `!var.enable_region_scp || length(var.allowed_regions) > 0`).
- `region_scp_name` — `string`, default `"DenyAccessOutsideApprovedRegions"`.
  Name passed to the `../policy` module.
- `region_scp_description` — `string`, default a descriptive string (e.g.
  "Denies regional AWS service actions outside the approved Regions in
  var.allowed_regions, exempting global services.").
- `attach_region_scp` — `bool`, default `true`. When `true`, attaches the
  created SCP to `region_scp_target_ids` (defaulting to the organization root);
  when `false`, the policy is created but not attached. Mirrors
  `attach_identity_center_scp`.
- `region_scp_target_ids` — `list(string)`, default `null`. Optional list of org
  root / OU / account IDs to attach to. When `null` and `attach_region_scp` is
  `true`, attaches to `aws_organizations_organization.org.roots[0].id`. Mirrors
  `identity_center_scp_target_ids`.
- `region_scp_exempted_principal_arns` — `list(string)`, default `[]`. IAM
  principal ARNs (wildcards allowed, e.g. `arn:aws:iam::*:role/BreakGlassRole`)
  excluded from the deny via an `ArnNotLike` condition on `aws:PrincipalARN`, so
  break-glass / execution roles are not locked out.
- `region_scp_exempted_actions` — `list(string)`, default `[]`. Additional
  actions merged into the built-in global-service `NotAction` list, for callers
  who depend on global services not covered out of the box.

The existing `tags` variable is reused for the created policy (no change).

### `outputs.tf`
New outputs to add to `modules/aws/organizations/organization/outputs.tf`
(mirroring the `identity_center_scp_*` outputs, all `try(...)`-guarded so they
resolve to `null`/`[]` when the feature is disabled):
- `region_scp_id` — the SCP policy ID, or `null` when `enable_region_scp` is
  `false`.
- `region_scp_arn` — the SCP policy ARN, or `null` when disabled.
- `region_scp_attachment_target_ids` — list of target IDs the SCP was attached
  to; empty when attachment or creation is disabled.

### `main.tf`
New blocks to add to `modules/aws/organizations/organization/main.tf` under a
new `# Region Restriction Service Control Policy` section header:
- A `locals` block that assembles the policy content and resolves attachment
  targets:
  - The `NotAction` list = a built-in list of global-service action prefixes
    (see below) concatenated with `var.region_scp_exempted_actions` (deduped).
  - The `aws:RequestedRegion` `StringNotEquals` condition value =
    `var.allowed_regions`.
  - The optional `ArnNotLike` condition on `aws:PrincipalARN`, included only when
    `length(var.region_scp_exempted_principal_arns) > 0`.
  - `region_scp_attachment_target_ids` — resolved exactly like the existing
    `identity_center_scp_attachment_target_ids` local: the caller-supplied
    targets when set, otherwise `[aws_organizations_organization.org.roots[0].id]`,
    gated on `var.enable_region_scp && var.attach_region_scp`.
- `module "region_scp"` — sources `../policy`, gated with
  `for_each = var.enable_region_scp ? { "region_scp" = "true" } : {}`
  (mirrors `identity_center_scp`). Arguments: `content` = the rendered policy
  document (see rendering note below), `description = var.region_scp_description`,
  `name = var.region_scp_name`, `type = "SERVICE_CONTROL_POLICY"`,
  `tags = var.tags`.
- `resource "aws_organizations_policy_attachment" "region_scp"` — declared
  inline; `for_each` over `toset(local.region_scp_attachment_target_ids)` so it
  only creates attachments when both `enable_region_scp` and `attach_region_scp`
  are `true`. `policy_id` references `module.region_scp["region_scp"].id`. A
  `lifecycle { precondition { ... } }` fails with a clear message when
  `enable_region_scp` is `true` but `"SERVICE_CONTROL_POLICY"` is not present in
  `coalesce(var.enabled_policy_types, [])` — identical shape to the existing
  `identity_center_scp` precondition.

**Policy rendering (design note).** Because the document is dynamic, the static
`file(...)` approach used by `identity_center_scp` does not apply. The proposed
approach is `templatefile("${path.module}/policies/deny_regions_scp.json", { ... })`,
passing the pre-`jsonencode`d `NotAction` list, the `allowed_regions` list, and
the (possibly empty) exempted-principal condition assembled in `locals`. The
template renders a single `Deny` statement of the following shape (global-service
`NotAction` list abbreviated here — the implementation must use the current AWS
Control Tower `CT.MULTISERVICE.PV.1` / `GRREGIONDENY` reference list, which
exempts non-regional/global services such as IAM, STS, Organizations, Route 53,
CloudFront, WAF/WAFv2/Shield, Global Accelerator, AWS Support, and
Billing/Budgets/Cost Explorer/CUR):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAccessOutsideApprovedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "sts:*",
        "organizations:*",
        "route53:*",
        "cloudfront:*",
        "waf:*",
        "wafv2:*",
        "shield:*",
        "globalaccelerator:*",
        "support:*",
        "budgets:*",
        "ce:*",
        "cur:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-east-1", "us-west-2"]
        },
        "ArnNotLike": {
          "aws:PrincipalARN": ["arn:aws:iam::*:role/BreakGlassRole"]
        }
      }
    }
  ]
}
```
The `ArnNotLike` key is present only when `region_scp_exempted_principal_arns`
is non-empty. Keys within the single `Condition` block are AND-ed, so the deny
applies when the request Region is not allowed **and** the caller is not an
exempted principal. Building the document via `jsonencode(...)` in `locals`
instead of `templatefile` is an acceptable alternative (see §9); either way the
committed `policies/deny_regions_scp.json` artifact is the source of the
`NotAction` reference list.

## 5. Breaking-change assessment
- Breaking: **no.** `enable_region_scp` defaults to `false`, so existing callers
  get a clean `tofu plan` with zero new resources and no behavioral change until
  they explicitly opt in.
- Scope when a caller opts in (`enable_region_scp = true`):
  - They must supply a non-empty `allowed_regions` (enforced by the variable
    `validation`).
  - Their organization must have `"SERVICE_CONTROL_POLICY"` in
    `enabled_policy_types` or the apply fails fast via the `precondition` (same
    pattern as `identity_center_scp`).
  - They should confirm `region_scp_exempted_principal_arns` covers break-glass
    and cross-Region automation roles before attaching to production OUs, and
    should typically include `us-east-1` in `allowed_regions` because some global
    features route through it.

## 6. Checkov / tfsec considerations
- New suppressions: **none.** The change adds an `aws_organizations_policy` (via
  the existing `../policy` module) and an `aws_organizations_policy_attachment`;
  these resource types are not flagged by the repo's Checkov/tfsec policy, and
  the SCP is security-positive (a deny guardrail).
- Existing suppressions affected: **none.**

## 7. terraform-docs impact
- Yes. The `<!-- BEGIN_TF_DOCS -->` block in
  `modules/aws/organizations/organization/README.md` will change to include the
  new inputs (`enable_region_scp`, `allowed_regions`, `region_scp_name`,
  `region_scp_description`, `attach_region_scp`, `region_scp_target_ids`,
  `region_scp_exempted_principal_arns`, `region_scp_exempted_actions`), the new
  outputs (`region_scp_id`, `region_scp_arn`,
  `region_scp_attachment_target_ids`), the new `region_scp` `../policy` module
  call, and the new `aws_organizations_policy_attachment.region_scp` resource.
  The hand-written portion of the README gains a usage example and a
  prerequisites note (see §10). The block must be regenerated with
  `terraform-docs` and committed.
- No other module READMEs change (`modules/aws/organizations/policy` is composed
  unmodified).

## 8. Testing
- `tofu -chdir=modules/aws/organizations/organization init -backend=false && tofu -chdir=modules/aws/organizations/organization validate`
- `tofu fmt -check -diff -recursive`
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/organizations/organization`
  (or `pre-commit run --all-files`) and commit the regenerated block.
- `checkov -d modules/aws/organizations/organization` (locally; CI runs on
  schedule).
- Manual review of the rendered plan:
  - `enable_region_scp = false` (default) → zero new resources.
  - `enable_region_scp = true` with a valid `allowed_regions` → plans the SCP +
    root attachment; the rendered `content` is valid JSON with the `aws:RequestedRegion`
    condition, the merged `NotAction` list, and the `ArnNotLike` block present
    only when `region_scp_exempted_principal_arns` is non-empty.
  - `enable_region_scp = true` with empty `allowed_regions` → fails the variable
    `validation`.
  - `enable_region_scp = true` without `"SERVICE_CONTROL_POLICY"` in
    `enabled_policy_types` → fails the `precondition`.

## 9. Open questions
- **Policy rendering mechanism:** `templatefile` reading
  `policies/deny_regions_scp.json` (recommended, keeps a reviewable JSON
  artifact and satisfies the issue's "add a policy file" requirement) vs.
  building the document inline with `jsonencode(...)` in `locals`. Both are
  acceptable; implementation should pick one and keep the committed
  `deny_regions_scp.json` as the authoritative `NotAction` reference.
- **`us-east-1` handling:** the module will **not** auto-inject `us-east-1` into
  `allowed_regions` (that would silently change caller intent). The README will
  instead document that `us-east-1` is commonly required. Flagged for reviewer
  confirmation.
- **`NotAction` list source:** the exact global-service list should be copied
  from the current AWS Control Tower `CT.MULTISERVICE.PV.1` / `GRREGIONDENY`
  reference at implementation time rather than frozen in this spec, since AWS
  updates it as new global services ship.
- **Precondition placement:** mirrors `identity_center_scp` by living on the
  attachment resource, so it does not fire when `attach_region_scp = false`.
  Reviewer decision on whether creation (not just attachment) should also be
  guarded; creating a `SERVICE_CONTROL_POLICY` already requires the type enabled
  on the org, so the provider surfaces an error in that edge case regardless.
- **Default exempted principals:** default is `[]` (no assumptions about role
  names). The README will recommend adding break-glass /
  `AWSControlTowerExecution` / `OrganizationAccountAccessRole` ARNs. Flagged for
  reviewer confirmation that no default exemption should be baked in.

## 10. Acceptance criteria
- [ ] New `enable_region_scp` variable (`bool`, default `false`) added to
  `modules/aws/organizations/organization`.
- [ ] New `allowed_regions` variable (`list(string)`, no default) added, with a
  `validation` requiring a non-empty list when `enable_region_scp` is `true`.
- [ ] When enabled, an `aws_organizations_policy` of type
  `SERVICE_CONTROL_POLICY` is created via the existing `../policy` module from a
  new `policies/deny_regions_scp.json` template, denying regional service
  actions (via `NotAction`) outside `var.allowed_regions`, modeled on the AWS
  Control Tower `CT.MULTISERVICE.PV.1` reference `NotAction` list.
- [ ] `region_scp_exempted_principal_arns` is wired into an `ArnNotLike`
  condition on `aws:PrincipalARN` so break-glass / execution roles are not
  denied.
- [ ] `region_scp_exempted_actions` is merged into the policy's `NotAction`
  list so callers can add global services beyond the built-in list.
- [ ] Attachment behavior mirrors `identity_center_scp`: attached to the
  organization root by default, overridable via `region_scp_target_ids`,
  skippable via `attach_region_scp = false`.
- [ ] The `SERVICE_CONTROL_POLICY` / `enabled_policy_types` prerequisite is
  enforced via a `precondition`, consistent with the existing
  `identity_center_scp` attachment resource.
- [ ] Module outputs expose `region_scp_id`, `region_scp_arn`, and
  `region_scp_attachment_target_ids` (null/empty when disabled).
- [ ] `README.md` updated with a usage example and a prerequisites note
  covering: SCPs never apply to the management account, `us-east-1` is commonly
  needed even for non-primary workloads because some global features route
  through it, and the recommendation to roll this out via a Sandbox/non-production
  OU before Production/Root. Regenerated `terraform-docs` block committed.
- [ ] `tofu fmt -check -diff -recursive` and the `Build` + `Test` CI jobs pass.
