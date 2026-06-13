# Spec: tfe_workspace execution_mode deprecated
**Issue:** #38
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
The `modules/terraform/workspace` module sets `execution_mode` directly on the
`tfe_workspace.this` resource (`modules/terraform/workspace/main.tf:21`). As of
`hashicorp/tfe` >= 0.42.0 (introduced by provider PR #1159, Dec 2023), the
`execution_mode` and `agent_pool_id` arguments on `tfe_workspace` are
**deprecated** in favor of the dedicated `tfe_workspace_settings` resource.
Every `tofu plan` / `terraform plan` now emits:
```
Warning: Argument is deprecated
  Use resource tfe_workspace_settings to modify the workspace execution
  settings. This attribute will be removed in a future release of the provider.
```
The attribute is scheduled for removal in a future provider release, so the
module will eventually break without a code change. See issue #38 for the full
report and reproduction.
The current module also passes `agent_pool_id` directly to `tfe_workspace`
(`modules/terraform/workspace/main.tf:16`), which is deprecated in the same way
and must move alongside `execution_mode`.

## 2. Non-goals
- Migrating `global_remote_state` and `remote_state_consumer_ids` off
  `tfe_workspace`. These are *also* deprecated on `tfe_workspace` in newer
  provider versions, but issue #38 scopes the fix to `execution_mode` (and the
  closely coupled `agent_pool_id`). They are tracked as a follow-up (see Open
  questions).
- Adopting `tfe_organization_default_settings` for org-wide execution defaults.
- Adding the additional optional attributes that `tfe_workspace_settings`
  exposes (e.g. `assessments_enabled`, `auto_apply`, `description`, `tags`),
  which would duplicate properties already managed on `tfe_workspace` and risk
  permanent drift.
- Changing the module's public variable surface, validation rules, or defaults.
- Writing an explicit state-migration `moved {}` block (the change is across two
  different resource types, which `moved` does not support).

## 3. Affected module path(s)
- `modules/terraform/workspace/` (existing)

This is a Terraform-only module (`modules/terraform/` uses the `hashicorp/tfe`
provider and is not OpenTofu-compatible per `AGENTS.md`).

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No new variables. No changes to existing variable names, types, descriptions,
defaults, or validation. The existing `execution_mode` and `agent_pool_id`
variables are retained and re-plumbed to the new resource:
- `execution_mode` (string, default `"remote"`, regex validation
  `remote|local|agent`) — unchanged signature; now consumed by
  `tfe_workspace_settings`.
- `agent_pool_id` (string, default `null`) — unchanged signature; now consumed
  by `tfe_workspace_settings`.

### `outputs.tf`
- `id` — unchanged (`tfe_workspace.this.id`).
- (Optional, additive) `execution_mode` — the effective execution mode from
  `tfe_workspace_settings.this.execution_mode`.
- (Optional, additive) `workspace_settings_overwrites` — the read-only
  `tfe_workspace_settings.this.overwrites` attribute, useful for callers that
  need to know whether the setting is explicit or inherited from org defaults.

These outputs are additive only and may be deferred; they do not affect existing
callers.

### `main.tf`
- `terraform {}` block — unchanged. `tfe` provider constraint stays at
  `>= 0.42.0` (the version that introduced `tfe_workspace_settings`).
- `resource "tfe_workspace" "this"` — **remove** the `execution_mode` argument
  and **remove** the `agent_pool_id` argument. All other arguments (including
  the `vcs_repo {}` block) remain unchanged.
- `resource "tfe_workspace_settings" "this"` — **new** resource:
  - `workspace_id = tfe_workspace.this.id`
  - `execution_mode = var.execution_mode`
  - `agent_pool_id = var.agent_pool_id`
- `resource "tfe_team_access" "this"` — unchanged.
- `resource "tfe_variable" "tfc_aws_provider_auth"` — unchanged.
- `resource "tfe_variable" "tfc_aws_run_role_arn"` — unchanged.

No `count`/`for_each` is required on `tfe_workspace_settings` (one settings
resource per workspace). No lifecycle ignores are introduced. Tagging
conventions do not apply to TFE resources.

Per the current provider docs, `agent_pool_id` on `tfe_workspace_settings`
requires `execution_mode = "agent"` and must be `null` otherwise — this matches
the module's existing `agent_pool_id` default of `null`, so the default path
(execution_mode `remote`) remains valid.

## 5. Breaking-change assessment
- Breaking: **no** to the module's public interface — variable names, types,
  defaults, validation, and the `id` output are all preserved.
- State impact: on first apply after upgrading, callers will see a one-time
  plan that removes `execution_mode` (and `agent_pool_id`) from the
  `tfe_workspace.this` resource and creates a new `tfe_workspace_settings.this`
  resource. This is an in-place settings change managed by the provider, not a
  workspace replacement, but it is a non-empty plan that callers should review
  and apply. The migration requires no change to caller `module {}` blocks.

## 6. Checkov / tfsec considerations
- New suppressions: none.
- Existing suppressions affected: none. (The module has no inline
  Checkov/tfsec suppressions, and TFE resources are not covered by the AWS
  security checks configured in `.checkov.yaml`.)

## 7. terraform-docs impact
Yes — `modules/terraform/workspace/README.md` `<!-- BEGIN_TF_DOCS -->` block
will change because a new resource (`tfe_workspace_settings.this`) is added to
the Resources list. If the optional outputs in §4 are added, the Outputs table
will also change. No inputs change. The README must be regenerated via
`terraform-docs` (pre-commit) during implementation so the `Verify -
terraform-docs` CI job passes.

## 8. Testing
- `terraform -chdir=modules/terraform/workspace init -backend=false`
- `terraform -chdir=modules/terraform/workspace validate`
- `terraform fmt -check -diff -recursive` (or `tofu fmt`, though this module is
  Terraform-only)
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/terraform/workspace`
- Manual confirmation: against a workspace that previously emitted the
  `execution_mode` deprecation warning, `terraform plan` produces no
  deprecation warnings related to `execution_mode`, and the workspace's
  execution mode is correctly managed by `tfe_workspace_settings`.
- `checkov -d modules/terraform/workspace` (locally; CI runs on schedule).

## 9. Open questions
- Should `global_remote_state` and `remote_state_consumer_ids` (also deprecated
  on `tfe_workspace`) be migrated to `tfe_workspace_settings` in the same PR, or
  tracked as a separate issue? This spec proposes deferring them to keep the fix
  focused on the reported warning.
- Should the additive `execution_mode` / `workspace_settings_overwrites` outputs
  be included now, or left out to minimize the diff? Recommended: include them
  since they are zero-risk and surface the new resource.

## 10. Acceptance criteria
- `execution_mode` is no longer set on `tfe_workspace.this`; it is managed by a
  new `tfe_workspace_settings.this` resource referencing
  `tfe_workspace.this.id`.
- `agent_pool_id` is plumbed through `tfe_workspace_settings.this` (verified
  against current provider docs) rather than `tfe_workspace.this`.
- Running `tofu plan` / `terraform plan` against a previously-warning workspace
  produces no deprecation warnings related to `execution_mode`.
- The module's public variables, defaults, validation, and the `id` output are
  unchanged (no caller `module {}` edits required).
- `README.md` is regenerated and the `Verify - terraform-docs` CI job passes.
- `terraform validate` and `terraform fmt -check` pass.
