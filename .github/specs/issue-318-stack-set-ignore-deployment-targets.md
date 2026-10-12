# Spec: feat(cloudformation/stack_set): add `ignore_deployment_targets_changes` variable to enable clean import of SERVICE_MANAGED instances
**Issue:** #318
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The `modules/aws/cloudformation/stack_set` module creates an
`aws_cloudformation_stack_set` plus a single `aws_cloudformation_stack_set_instance.this`.
The instance's `deployment_targets` block is configured from the `accounts`,
`account_filter_type`, `accounts_url`, and `organizational_unit_ids` inputs.

When importing an **existing SERVICE_MANAGED** StackSet instance, the AWS
`DescribeStackInstance` API does not return `deployment_targets` content — the
field comes back empty. Because `deployment_targets` is a **ForceNew** attribute
in the AWS provider, the import succeeds but the very next plan shows a forced
destroy + create:

```
-/+ resource "aws_cloudformation_stack_set_instance" "this" {
      ~ deployment_targets = [] -> [{ organizational_unit_ids = ["r-tcoa"] }]  # forces replacement
```

For the org-wide `Datadog-AWS-Integration` StackSet (21 accounts, OU target
`r-tcoa`, `us-west-2`) this would de-register every account and re-register it
with new ExternalIds — a significant monitoring disruption. Issue #318 requests
an opt-in flag that lets callers import such instances without the destructive
replace. This builds on #314, which added `stack_set_instance_region`.

### Important implementation constraint (drives the design below)
The issue proposes gating `ignore_changes` on the new variable directly:

```hcl
lifecycle {
  ignore_changes = var.ignore_deployment_targets_changes ? [deployment_targets] : []
}
```

This is **not valid** Terraform/OpenTofu. The `lifecycle` block (including
`ignore_changes`) accepts **literal values only** — it is evaluated while the
dependency graph is built, before arbitrary expressions are resolved, so
variables, conditionals, and interpolation are rejected with
`A single static variable reference is required`. This is identical behaviour in
Terraform (>= 1.0) and OpenTofu (>= 1.6), confirmed by the HashiCorp
[`lifecycle` reference](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle)
("only literal values can be used because the processing happens too early for
arbitrary expression evaluation").

The established, dual-tool-compatible workaround is to declare **two copies** of
the instance resource — one with the static `lifecycle.ignore_changes` block and
one without — and select between them with `count` driven by the new boolean.
The proposed design uses that pattern.

## 2. Non-goals
- No change to `aws_cloudformation_stack_set.this` (the StackSet itself).
- No change to the `accounts` / `account_filter_type` / `accounts_url` /
  `organizational_unit_ids` inputs or to the `deployment_targets` block contents.
- Not adding new `outputs.tf` entries. Current outputs expose only the StackSet
  (`arn`, `name`, `id`), not the instance; surfacing instance attributes is out
  of scope.
- Not auto-detecting `permission_model == "SERVICE_MANAGED"` to toggle the
  behaviour — the flag is an explicit, caller-controlled opt-in.
- Not changing the module to support managing multiple instances / a map of
  instances (separate concern).
- No import automation (`import {}` blocks) — the module documents the manual
  import workflow; it does not perform the import.

## 3. Affected module path(s)
- `modules/aws/cloudformation/stack_set/` (existing)
  - `variables.tf` — add one variable.
  - `main.tf` — add a second instance resource + `count` toggle + `moved` block.
  - `README.md` — regenerate terraform-docs; add a Notes / Design Decisions entry
    and a usage/import example.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Add one variable (verbatim shape from the issue):

```hcl
variable "ignore_deployment_targets_changes" {
  description = "When true, ignores changes to deployment_targets on the stack set instance. Use when importing a pre-existing SERVICE_MANAGED StackSet instance whose deployment_targets the AWS API does not return on describe. Setting this prevents a ForceNew replace on import."
  type        = bool
  default     = false
}
```

No other variables change.

### `outputs.tf`
Unchanged. (If instance outputs are ever added, they must `coalesce`/`concat`
across the two count-toggled instance resources so the value resolves regardless
of which copy is active — explicitly out of scope here.)

### `main.tf`
Resource block names and meta-argument shape (bodies unchanged from current
module unless noted):

- `aws_cloudformation_stack_set.this` — **unchanged**.
- `aws_cloudformation_stack_set_instance.this` — **add** a count meta-argument so
  it is created only in the default (non-ignored) case. Arguments
  (`call_as`, `stack_set_instance_region`, `stack_set_name`, the
  `deployment_targets` block) are otherwise unchanged.
  ```hcl
  resource "aws_cloudformation_stack_set_instance" "this" {
    count = var.ignore_deployment_targets_changes ? 0 : 1
    # ...existing arguments + deployment_targets block (unchanged)...
  }
  ```
- `aws_cloudformation_stack_set_instance.ignore_deployment_targets` — **new**
  resource with the *same* argument set, created only when the flag is true, plus
  a static lifecycle ignore:
  ```hcl
  resource "aws_cloudformation_stack_set_instance" "ignore_deployment_targets" {
    count = var.ignore_deployment_targets_changes ? 1 : 0
    # ...same arguments + deployment_targets block as .this...
    lifecycle {
      ignore_changes = [deployment_targets]
    }
  }
  ```
- `moved` block — migrate existing state from the un-indexed address to the
  indexed default-path address so current callers (flag defaults to `false`) do
  **not** see a destroy/recreate when they upgrade:
  ```hcl
  moved {
    from = aws_cloudformation_stack_set_instance.this
    to   = aws_cloudformation_stack_set_instance.this[0]
  }
  ```

Notes carried into the README "Notes / Design Decisions" section:
- Set the flag **at import time**. Flipping it on an *already-managed* instance
  moves state between `.this[0]` and `.ignore_deployment_targets[0]`, which
  Terraform plans as a destroy + create (the addresses differ) — the same
  disruption the flag is meant to avoid. The intended workflow is: set
  `ignore_deployment_targets_changes = true`, then
  `terraform import module.<name>.aws_cloudformation_stack_set_instance.ignore_deployment_targets[0] <stack_set_name>,<ou-or-account>,<region>`.
- While the flag is `true`, subsequent changes to `accounts` /
  `organizational_unit_ids` / `account_filter_type` / `accounts_url` are **not**
  applied to the live instance (they are ignored). Targeting changes then require
  toggling the flag back off (a replace) or an out-of-band update.

## 5. Breaking-change assessment
- **Breaking: no — provided the `moved` block ships with the change.**
- Default `false` preserves the current runtime behaviour for every existing
  caller.
- Adding `count` to `aws_cloudformation_stack_set_instance.this` changes its
  state address from `.this` to `.this[0]`. Without mitigation Terraform would
  destroy and recreate the instance on the next apply. The `moved` block
  (§4) converts this into a no-op state move, so existing callers see **no plan
  diff** after upgrading.
- Migration for callers: none required — the `moved` block is automatic. Callers
  wishing to use the new behaviour set `ignore_deployment_targets_changes = true`
  and import into the `.ignore_deployment_targets[0]` address.
- Version note: `moved` blocks require Terraform >= 1.1 / OpenTofu >= 1.6. The
  module declares `required_version = ">= 1.0.0"`, but `AGENTS.md` explicitly
  sanctions `moved` as a standard construct (identical across OpenTofu 1.6+ and
  Terraform 1.5+). See Open Questions for the fallback if the maintainers want to
  preserve a strict 1.0.x floor.

## 6. Checkov / tfsec considerations
- **New suppressions: none.** The change adds a boolean input, a duplicate of an
  existing resource type, a `count` toggle, a static `lifecycle.ignore_changes`,
  and a `moved` block — none of which introduce a resource type or attribute that
  trips a Checkov/tfsec policy.
- **Existing suppressions affected: none.** No entries in `.checkov.yaml` or
  `.trivyignore` reference this module.

## 7. terraform-docs impact
Yes — the auto-generated `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/cloudformation/stack_set/README.md` will change:
- **Inputs**: a new `ignore_deployment_targets_changes` row (`bool`, default
  `false`, not required).
- **Resources**: a new
  `aws_cloudformation_stack_set_instance.ignore_deployment_targets` row alongside
  the existing `aws_cloudformation_stack_set_instance.this` row.
- **Outputs**: unchanged.
The README must be regenerated locally (pre-commit `terraform_docs` hook or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/cloudformation/stack_set`)
and committed, or the `Verify - terraform-docs` CI job will fail.

## 8. Testing
- `tofu -chdir=modules/aws/cloudformation/stack_set init -backend=false`
  (Terraform equivalent also valid).
- `tofu -chdir=modules/aws/cloudformation/stack_set validate`.
- `tofu fmt -check -diff -recursive`.
- `terraform-docs ... inject modules/aws/cloudformation/stack_set` produces no
  diff after the change is committed.
- `checkov -d modules/aws/cloudformation/stack_set` (locally; CI runs on a
  schedule) reports no new findings.
- Behavioural validation (manual / plan-only, no live apply required for the
  spec):
  - With `ignore_deployment_targets_changes = false` (default), an existing
    state at `aws_cloudformation_stack_set_instance.this` plans **no changes**
    after upgrade (the `moved` block resolves the address change).
  - With the flag `true`, `terraform plan` creates
    `aws_cloudformation_stack_set_instance.ignore_deployment_targets[0]` and not
    `.this[0]`; after importing the existing instance into that address, the plan
    is clean (no ForceNew replace) even though describe returns empty
    `deployment_targets`.

## 9. Open questions
- **`moved` block vs. documented manual `state mv`.** Recommendation: ship the
  `moved` block (seamless, no caller action). If the maintainers want to keep a
  strict `>= 1.0.0` floor for tools older than the `moved` feature, the
  alternative is to document a one-time `terraform state mv` in the README and
  the CHANGELOG instead — please confirm the preference.
- **Second resource name.** Proposed
  `aws_cloudformation_stack_set_instance.ignore_deployment_targets`. Confirm or
  suggest an alternative (e.g. `this_ignore_targets`).
- **Import-address documentation.** Confirm the StackSet-instance import ID
  format to document
  (`<stack_set_name>,<account_id_or_ou_id>,<region>` plus `--call-as` where the
  caller is a delegated admin).

## 10. Acceptance criteria
The implementation PR must satisfy all of the following:
1. `variables.tf` declares `ignore_deployment_targets_changes` (`bool`,
   `default = false`) with the description from §4.
2. `main.tf` implements the gated duplicate-resource pattern: `.this` carries
   `count = var.ignore_deployment_targets_changes ? 0 : 1`; a new
   `.ignore_deployment_targets` carries the inverse count and a static
   `lifecycle { ignore_changes = [deployment_targets] }`; both resources share an
   identical argument set and `deployment_targets` block.
3. A `moved` block migrates `aws_cloudformation_stack_set_instance.this` →
   `aws_cloudformation_stack_set_instance.this[0]` so existing callers see no
   destroy/recreate.
4. With the flag at its default (`false`), an existing deployment plans **no
   changes** after upgrade.
5. With the flag `true`, an imported pre-existing SERVICE_MANAGED instance
   (empty `deployment_targets` on describe) produces a **clean plan** — no
   ForceNew replacement.
6. `tofu validate` and `tofu fmt -check` pass; `terraform-docs` output is
   regenerated and committed (Inputs + Resources tables updated); `checkov`
   reports no new findings.
7. The README "Notes / Design Decisions" section documents: the literal-only
   `ignore_changes` constraint and why two resources exist; the import workflow
   and import-address format; and the caveat that, while enabled, changes to the
   targeting inputs are ignored.
