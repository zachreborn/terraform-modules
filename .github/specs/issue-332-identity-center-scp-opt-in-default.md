# Spec: fix(organizations/organization): default `enable_identity_center_scp` to `false` (opt-in)
**Issue:** #332
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
v8.20.2 added the Identity Center deny SCP feature to
`modules/aws/organizations/organization` (implemented from spec #267). The
toggle `enable_identity_center_scp` was introduced as an **opt-out** default
(`default = true`, `modules/aws/organizations/organization/variables.tf:47-51`).
When enabled, the module:
1. Creates a `SERVICE_CONTROL_POLICY` via the `../policy` child module
   (`modules/aws/organizations/organization/main.tf:68-78`), and
2. Attaches it to the organization root via
   `aws_organizations_policy_attachment.identity_center_scp`
   (`modules/aws/organizations/organization/main.tf:80-92`), which carries a
   `precondition` requiring `"SERVICE_CONTROL_POLICY"` to be present in
   `var.enabled_policy_types`.

`enabled_policy_types` defaults to `null`
(`modules/aws/organizations/organization/variables.tf:18-22`), and SCP support
is **not** enabled on most organizations. As a result, any existing caller that
upgrades to v8.20.2 without explicitly setting `enable_identity_center_scp =
false` **and** without adding `"SERVICE_CONTROL_POLICY"` to `enabled_policy_types`
hits a plan-time failure:

```
Error: Resource precondition failed

  on .terraform/modules/.../organization/main.tf, in resource "aws_organizations_policy_attachment":
  precondition: enable_identity_center_scp is true but "SERVICE_CONTROL_POLICY" is not present
  in enabled_policy_types.
```

This breaks virtually all pre-existing callers on upgrade because the
prerequisite was not required before this version. The originating issue, its
triage classification, and acceptance criteria are tracked at
https://github.com/zachreborn/terraform-modules/issues/332.

The #267 spec explicitly acknowledged this as a breaking opt-out default (§5 of
`.github/specs/issue-267-deny-identity-center-scp.md`). Issue #332 resolves it by
flipping the default to **opt-in** (`false`), matching the sibling
`enable_organization_backup` precedent (`bool`, default `false`,
`modules/aws/organizations/organization/variables.tf:81-85`) and the fact that
the SCP has a hard prerequisite (`SERVICE_CONTROL_POLICY`) that cannot be safely
assumed for arbitrary callers.

Issue #332 references #331 — a separate `file()` path-resolution bug — as a
co-occurring blocker. #331 is tracked and fixed independently and is out of scope
here (see §2).

## 2. Non-goals
- **Not removing the SCP feature.** The `../policy` module call, the attachment
  resource, the precondition, all five `identity_center_scp*` /
  `attach_identity_center_scp` variables, and the three `identity_center_scp*`
  outputs remain. Only the `enable_identity_center_scp` default changes.
- **Not changing the precondition logic.** The precondition at
  `modules/aws/organizations/organization/main.tf:87-90` must keep firing when a
  caller explicitly opts in (`enable_identity_center_scp = true`) without
  `SERVICE_CONTROL_POLICY` enabled. Its guard already short-circuits when the
  toggle is `false`.
- **Not auto-injecting `SERVICE_CONTROL_POLICY`** into the `enabled_policy_types`
  default (same decision as #267 §2/§9 — the module does not silently mutate
  caller policy types).
- **Not changing the `attach_identity_center_scp` default** (`true`). It is gated
  by `enable_identity_center_scp`, so it has no effect while the feature is
  opt-out.
- **Not changing the `../policy` child module** or any other organization
  submodule (`account`, `ou`, `delegated_admin`, `delegated_resource_policy`).
- **Not fixing #331** (the `file()` path bug) — separate issue, separate PR.

## 3. Affected module path(s)
- `modules/aws/organizations/organization/` (existing)
  - `modules/aws/organizations/organization/variables.tf` — flip the
    `enable_identity_center_scp` default and update its description.
  - `modules/aws/organizations/organization/README.md` — update the hand-written
    "Identity Center Service Control Policy" section to describe opt-in behavior
    and regenerate the `<!-- BEGIN_TF_DOCS -->` block.

No change to `main.tf` or `outputs.tf` (see §4).

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
One existing variable changes; no variables are added, removed, or retyped.
- `enable_identity_center_scp` — `bool`, **default changes from `true` to
  `false`**. Description updated to state the feature is opt-in / disabled by
  default (e.g. "Defaults to false." in place of "Defaults to true.") while
  retaining the note that enabling it requires `SERVICE_CONTROL_POLICY` in
  `enabled_policy_types`.

All other variables are unchanged, including `attach_identity_center_scp`
(`bool`, `true`), `identity_center_scp_name`, `identity_center_scp_description`,
`identity_center_scp_target_ids`, `enabled_policy_types`, and `tags`.

### `outputs.tf`
No changes. The three SCP outputs already resolve safely when the feature is
disabled:
- `identity_center_scp_id` —
  `try(module.identity_center_scp["identity_center_scp"].id, null)` → `null` when
  disabled.
- `identity_center_scp_arn` — `try(..., null)` → `null` when disabled.
- `identity_center_scp_attachment_target_ids` — comprehension over the
  `for_each`-gated attachment → `[]` when disabled.

### `main.tf`
No changes. The existing gating already produces the correct opt-in behavior once
the default is `false`:
- `module "identity_center_scp"` uses
  `for_each = var.enable_identity_center_scp ? { "identity_center_scp" = "true" } : {}`
  → zero instances when disabled (no policy created).
- `local.identity_center_scp_attachment_target_ids` resolves to `[]` when the
  toggle is `false` → `aws_organizations_policy_attachment.identity_center_scp`
  has zero instances (no attachment).
- The attachment `precondition`
  (`condition = !var.enable_identity_center_scp || contains(coalesce(var.enabled_policy_types, []), "SERVICE_CONTROL_POLICY")`)
  evaluates to `true` — and is not instantiated — when the toggle is `false`, so
  default callers no longer hit the precondition error.

## 5. Breaking-change assessment
- Breaking: **mostly restorative; narrowly breaking for v8.20.2 opt-out
  adopters.**
- **For the vast majority of callers** (those who never set the flag and were
  broken on the v8.20.2 upgrade, or who pinned below v8.20.2): flipping the
  default to `false` **restores the pre-v8.20.2 contract**. They get a clean
  `tofu plan`/`validate` with no new resources and no precondition error. This is
  the intended fix.
- **For the narrow set of callers** who, during the brief v8.20.2 window,
  accepted the opt-out default by also adding `"SERVICE_CONTROL_POLICY"` to
  `enabled_policy_types` and successfully applied: after this patch the SCP and
  its root attachment would be **destroyed** on the next apply unless they now set
  `enable_identity_center_scp = true` explicitly. Migration for them is a single
  line: `enable_identity_center_scp = true`.
- **Callers who already set `enable_identity_center_scp` explicitly** (either
  value) are unaffected.
- Release/commit guidance: this is a regression fix for a default introduced one
  patch release earlier. Recommend a `fix:` Conventional Commit with an explicit
  CHANGELOG upgrade note documenting the opt-in default and the one-line migration
  for v8.20.2 opt-out adopters. Whether the narrow destroy-on-upgrade case
  warrants a `fix!:` / `BREAKING CHANGE:` (MAJOR) bump versus a documented `fix:`
  (PATCH) is flagged for reviewer/release decision (see §9); the AGENTS.md release
  rules drive the actual version.

## 6. Checkov / tfsec considerations
- New suppressions: **none.** The change only alters a variable default; it
  adds/removes no resources and no security-relevant arguments. (Checkov/tfsec do
  not flag `aws_organizations_policy` / `aws_organizations_policy_attachment` in
  this repo, per #267 §6.)
- Existing suppressions affected: **none.**
- Note: flipping the default makes the out-of-the-box AWS posture *less*
  restrictive (no deny SCP unless opted in). This is a deliberate trade-off to
  deliver a working upgrade path, consistent with the opt-in
  `enable_organization_backup` precedent. It is an AWS-posture default, not a
  Checkov/tfsec check, so no suppressions are involved.

## 7. terraform-docs impact
- Yes. Regenerating the `<!-- BEGIN_TF_DOCS -->` block in
  `modules/aws/organizations/organization/README.md` will change the
  `enable_identity_center_scp` input's **Default** column from `true` to `false`
  (and its Description if reworded).
- **Pre-existing drift:** the committed block currently predates the #267
  implementation — it does not list the `identity_center_scp*` /
  `attach_identity_center_scp` inputs, the `identity_center_scp*` outputs, the
  `identity_center_scp` module call, or the
  `aws_organizations_policy_attachment.identity_center_scp` resource. A fresh
  `terraform-docs` run (which CI's `Verify - terraform-docs` job enforces) will
  therefore **also add those rows**. The implementer must regenerate and commit
  the block so CI passes.
- The hand-written "Identity Center Service Control Policy" section (currently
  "By default this module creates and attaches a Service Control Policy…") must
  be reworded to reflect opt-in (disabled by default), and the example that
  presents `enable_identity_center_scp = true` as "the defaults" must be corrected
  to show it as an explicit opt-in.
- No other module READMEs change.

## 8. Testing
- `tofu -chdir=modules/aws/organizations/organization init -backend=false && tofu -chdir=modules/aws/organizations/organization validate`
  (equivalently `terraform -chdir=... ...`).
- `tofu fmt -check -diff -recursive` (equivalently `terraform fmt ...`).
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/organizations/organization`
  (or `pre-commit run --all-files`) and commit the regenerated block.
- `checkov -d modules/aws/organizations/organization` (locally; CI runs on
  schedule).
- Manual `tofu plan` verification:
  - Default (flag unset, `enabled_policy_types` without SCP): **no** new
    resources, **no** precondition error, clean plan.
  - `enable_identity_center_scp = true` with `enabled_policy_types` lacking
    `"SERVICE_CONTROL_POLICY"`: precondition **fails** with the documented
    message.
  - `enable_identity_center_scp = true` with `"SERVICE_CONTROL_POLICY"` present:
    policy created and attached to the root.

## 9. Open questions
- **SemVer / commit type:** should the destroy-on-upgrade impact for the narrow
  v8.20.2 opt-out-adopter set be released as `fix:` (PATCH, with an upgrade note)
  or as a breaking `fix!:` / `BREAKING CHANGE:` (MAJOR)? Recommended: `fix:` with
  an explicit CHANGELOG upgrade note; final call deferred to reviewer /
  release-please.
- **README example scope:** confirm the hand-written README example should be
  updated to present the SCP as opt-in (recommended) rather than left advertising
  the old opt-out default.
- No open questions on the code change itself — the one-line default flip fully
  satisfies the acceptance criteria given the existing gating/precondition logic.

## 10. Acceptance criteria
Mirrors the issue's acceptance criteria:
1. **Clean upgrade path** — an existing caller referencing the patched version
   with no new arguments passes `tofu validate` and `tofu plan` with no errors and
   no unexpected resource additions.
2. **Opt-in behavior** — when `enable_identity_center_scp` is not explicitly set,
   no `"SERVICE_CONTROL_POLICY"` entry is required in `enabled_policy_types`, and
   no SCP resource is created or attached.
3. **Precondition only fires when opted in** — the `SERVICE_CONTROL_POLICY`
   precondition triggers only when a caller explicitly sets
   `enable_identity_center_scp = true`; it must not trigger for default callers.
4. **CHANGELOG / upgrade notes** — the SCP feature is documented as opt-in; any
   version that intentionally defaults `enable_identity_center_scp = true` is
   labeled a breaking change with a clear upgrade path.
5. `enable_identity_center_scp` defaults to `false` in
   `modules/aws/organizations/organization/variables.tf`, and the variable
   description reflects the opt-in default.
6. `tofu fmt -check -diff -recursive` passes and the regenerated
   `modules/aws/organizations/organization/README.md` terraform-docs block is
   committed (so the `Build` / `Verify - terraform-docs` and `Test` CI jobs pass).
7. No new Checkov/tfsec suppressions are added.
