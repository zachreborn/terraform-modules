# Spec: bug(organizations/organization): file() paths missing ${path.module}/ prefix cause validation failure for callers
**Issue:** #331
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
The `modules/aws/organizations/organization` module references two JSON policy
documents that are bundled inside the module via `file()`, but uses **bare
relative paths**:

```hcl
# modules/aws/organizations/organization/main.tf line 43 (module "centralized_backup")
content = file("policies/enable_backup_policy.json")

# modules/aws/organizations/organization/main.tf line 73 (module "identity_center_scp")
content = file("policies/deny_identity_center_instance_scp.json")
```

In Terraform/OpenTofu, `file()` with a relative path resolves against the
**root module / process working directory** (where `tofu`/`terraform` is
invoked), **not** the directory of the module that contains the call. The
correct pattern for referencing a file shipped inside a module is to prefix the
path with `${path.module}/`. The files **do** exist inside the module at
`modules/aws/organizations/organization/policies/`
(`enable_backup_policy.json`, `deny_identity_center_instance_scp.json`), but the
bare paths make the caller's root directory the search base, so they are never
found.

Because each `file()` call is given a **constant** string argument, the path is
evaluated **statically at validate time**, regardless of the `for_each` toggles
on either module block. This is why the line-43 call fails even though
`module "centralized_backup"` is gated behind `enable_organization_backup`
(default `false`, so its `for_each` is empty by default) — exactly the failure
shown in the issue's error output (`module centralized_backup`). The result is
an immediate, unconditional failure for every caller that upgrades to v8.20.2:

```
Error: Invalid function argument

  on .terraform/modules/.../organization/main.tf line 43, in module centralized_backup:
  43:   content = file("policies/enable_backup_policy.json")

Invalid value for "path" parameter: no file exists at "policies/enable_backup_policy.json"
```

The fix is the one proposed in the issue: prefix both paths with
`${path.module}/`. This is the same class of defect previously specced for
`modules/services/aws_backup` in `.github/specs/issue-327-aws-backup-org-plan-file-path.md`
(bare-relative `file()` path). Unlike #327, these two documents are **static**
JSON (no `${var.*}` interpolation is needed), so the correct remedy is purely
the path prefix — not a switch to `templatefile()` or inline `jsonencode(...)`.

Originating issue: https://github.com/zachreborn/terraform-modules/issues/331

## 2. Non-goals
- **No input/output surface change.** No variable is added, removed, or
  retyped; no output is added, removed, or retyped.
- **No change to the `for_each` toggles** (`enable_organization_backup`,
  `enable_identity_center_scp`) or their defaults / semantics. Only the two
  `content = file(...)` path arguments change.
- **No change to the child `../policy` module** (`modules/aws/organizations/policy`)
  or its `content` / `name` / `type` / `tags` inputs. It already accepts an
  arbitrary policy string.
- **No change to the bundled JSON files' contents.** The `enable_backup_policy.json`
  content-validity concern is explicitly out of scope for the reported path fix
  and is raised in §9 (Open questions) for a scoping decision.
- **No conversion from `file()` to `templatefile()` / inline `jsonencode(...)`.**
  These documents are static; only the path resolution is wrong.
- **No broader refactor** of the organization module (the
  `aws_organizations_organization` resource and its `prevent_destroy` lifecycle,
  `module "centralized_root"`, the SCP attachment resource / precondition, or
  the attachment-target `locals`).

## 3. Affected module path(s)
- `modules/aws/organizations/organization/` (existing)
  - `modules/aws/organizations/organization/main.tf` — the **only** file whose
    Terraform changes: add the `${path.module}/` prefix to the two `file()`
    calls (lines 43 and 73). No other file in the module is modified by the fix
    itself (see §7 for a pre-existing, separate terraform-docs note).

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
**No changes.** Every existing variable is unchanged in name, type, default, and
description. For completeness, the unchanged inputs are:
- `aws_service_access_principals` — `list(string)`, default = curated service list.
- `enabled_policy_types` — `list(string)`, default = `null`.
- `feature_set` — `string`, default = `"ALL"` (with `ALL|CONSOLIDATED_BILLING` validation).
- `enabled_features` — `list(string)`, default = `["RootCredentialsManagement", "RootSessions"]`.
- `enable_identity_center_scp` — `bool`, default = `true`.
- `identity_center_scp_name` — `string`, default = `"DenyMemberAccountIdentityCenter"`.
- `identity_center_scp_description` — `string`, default = (deny-create-instance description).
- `attach_identity_center_scp` — `bool`, default = `true`.
- `identity_center_scp_target_ids` — `list(string)`, default = `null`.
- `enable_organization_backup` — `bool`, default = `false`.
- `tags` — `map(string)`, default = `{ terraform = "true" }`.

### `outputs.tf`
**No changes.** All existing outputs are unchanged in name, value, and
description: `accounts`, `master_account_arn`, `master_account_email`,
`master_account_id`, `arn`, `id`, `roots`, `identity_center_scp_id`,
`identity_center_scp_arn`, `identity_center_scp_attachment_target_ids`.

### `main.tf`
Only the two `file()` path arguments change. No resource, module, data source,
or `locals` block is added, removed, or renamed; no `for_each`/`count`,
`lifecycle`, or tagging pattern changes.

- `module "centralized_backup"` (`source = "../policy"`; `for_each` on
  `var.enable_organization_backup` — **unchanged**): the `content` argument
  changes from `file("policies/enable_backup_policy.json")` to
  `file("${path.module}/policies/enable_backup_policy.json")`. The `description`,
  `name = "Root"`, `type = "BACKUP_POLICY"`, and `tags = var.tags` arguments are
  unchanged.
- `module "identity_center_scp"` (`source = "../policy"`; `for_each` on
  `var.enable_identity_center_scp` — **unchanged**): the `content` argument
  changes from `file("policies/deny_identity_center_instance_scp.json")` to
  `file("${path.module}/policies/deny_identity_center_instance_scp.json")`. The
  `description`, `name`, `type = "SERVICE_CONTROL_POLICY"`, and `tags` arguments
  are unchanged.
- **Unchanged blocks** (listed to bound the change): the `terraform {}` block
  (`required_version = ">= 1.0.0"`, `aws >= 5.78.0`);
  `resource "aws_organizations_organization" "org"` (including
  `lifecycle { prevent_destroy = true }`); `module "centralized_root"`; the
  `locals` block computing `identity_center_scp_attachment_target_ids`; and
  `resource "aws_organizations_policy_attachment" "identity_center_scp"`
  (including its `lifecycle.precondition`).

## 5. Breaking-change assessment
- Breaking: **no.**
- No inputs or outputs change, so no caller HCL needs to change.
- For callers currently on the broken v8.20.2, this is a pure fix: `validate` /
  `plan` begin succeeding where they currently fail with `Invalid function
  argument`. There is no state migration and no resource address change.
- The default configuration (`enable_organization_backup = false`,
  `enable_identity_center_scp = true`) is fully unblocked by the path prefix
  alone. The resolved `content` for the default-enabled `identity_center_scp`
  policy is byte-for-byte the bundled file, so no spurious plan diff is
  introduced beyond enabling the previously-failing configuration to plan at all.

## 6. Checkov / tfsec considerations
- New suppressions: **none.** The change only corrects a `file()` path argument;
  it touches no encryption, networking, public-access, or IAM-policy-permission
  surface that would trip a Checkov/tfsec check.
- Existing suppressions affected: **none.**

## 7. terraform-docs impact
- **From this fix: none.** Adding `${path.module}/` to a `file()` argument
  changes no variable, output, module call (name/source/version), resource, or
  data source, so the auto-generated `<!-- BEGIN_TF_DOCS -->` block in
  `modules/aws/organizations/organization/README.md` does not change as a result
  of the bug fix.
- **Pre-existing drift (separate from this issue, flagged for the implementer):**
  the committed README's terraform-docs block is already out of sync with the
  current code. It lists `module "centralized_backup"` but omits
  `module "identity_center_scp"`, and it omits the Identity Center SCP inputs
  (`enable_identity_center_scp`, `identity_center_scp_name`,
  `identity_center_scp_description`, `attach_identity_center_scp`,
  `identity_center_scp_target_ids`) and outputs (`identity_center_scp_id`,
  `identity_center_scp_arn`, `identity_center_scp_attachment_target_ids`) added
  in #269 (commit `dd18c286`). Per AGENTS.md the implementer is required to run
  terraform-docs; doing so will regenerate those missing rows — a diff unrelated
  to this bug. See §9 for whether to fold that regeneration into this PR.

## 8. Testing
- `tofu -chdir=modules/aws/organizations/organization init -backend=false && tofu -chdir=modules/aws/organizations/organization validate`
  (and the `terraform -chdir=...` equivalents). Must pass on OpenTofu/Terraform
  1.10+.
- **Reproduce the caller condition.** Validating from *inside* the module
  directory masks the bug (the process CWD then is the module dir, so the bare
  path happens to resolve). To exercise the real failure/fix, also `validate`
  from a small separate root module that calls this module by relative `source`,
  so the working directory differs from the module directory — this is the
  configuration in which v8.20.2 currently fails with `no file exists at
  "policies/enable_backup_policy.json"`.
- `tofu fmt -check -diff -recursive` (or `terraform fmt -check -diff -recursive`).
- `checkov -d modules/aws/organizations/organization` (locally; CI runs on
  schedule) — expect no new findings.
- Regenerate terraform-docs per AGENTS.md (`pre-commit run --all-files` or the
  per-module `terraform-docs markdown table --output-file README.md
  --output-mode inject modules/aws/organizations/organization`), noting the
  pre-existing drift in §7.
- Manual confirmation:
  - With defaults: `validate`/`plan` succeed; exactly one
    `module.identity_center_scp["identity_center_scp"]` instance is planned and
    its `content` equals the bundled `deny_identity_center_instance_scp.json`;
    no `module.centralized_backup` instance is planned
    (`enable_organization_backup = false`).
  - No `Invalid function argument` / `no file exists` error is emitted.

## 9. Open questions
- **`enable_backup_policy.json` content validity (latent, out of reported
  scope).** The file content
  `{"Root": {"Id": "...", "Arn": "...", "Name": "Root", "PolicyTypes": [{"Type": "BACKUP_POLICY", "Status": "ENABLED"}]}}`
  is **not** a valid AWS Organizations `BACKUP_POLICY` document (those use a
  top-level `plans` → `rules` schema); it resembles an organization *root
  description*. Even after the path prefix is fixed, setting
  `enable_organization_backup = true` would pass this invalid content to the
  `BACKUP_POLICY` `aws_organizations_policy`, which AWS would reject at apply.
  This parallels defect 2 in spec #327. **Should this PR also correct the policy
  content, or should it be tracked as a separate issue?** The reported bug (the
  validate failure that affects the default configuration) is fully fixed by the
  path prefix alone; `deny_identity_center_instance_scp.json` is already a valid
  SCP and needs no content change.
- **terraform-docs drift (§7).** Regenerate the stale README in this PR (keeps
  the `Verify - terraform-docs` job green but adds an Identity-Center-SCP diff
  unrelated to the path fix), or address it in a separate docs PR? Recommend the
  implementer regenerate as part of this PR since AGENTS.md requires committing
  current docs and CI verifies them.

## 10. Acceptance criteria
- Both `file()` calls in `modules/aws/organizations/organization/main.tf`
  reference `${path.module}/policies/...` so the bundled documents resolve
  relative to the module directory:
  - line 43 → `file("${path.module}/policies/enable_backup_policy.json")`
  - line 73 → `file("${path.module}/policies/deny_identity_center_instance_scp.json")`
- `tofu validate` / `tofu plan` (and the `terraform` equivalents) succeed on
  OpenTofu/Terraform 1.10+ for a caller consuming the module in its default
  configuration, where they previously failed with `Invalid function argument` /
  `no file exists at "policies/enable_backup_policy.json"`.
- With defaults, exactly one `module.identity_center_scp["identity_center_scp"]`
  instance is planned with `content` equal to the bundled
  `deny_identity_center_instance_scp.json`, and no `module.centralized_backup`
  instance is created.
- No variables, outputs, module/resource/data-source blocks, `for_each` toggles,
  or defaults change; the change is limited to the two `file()` path arguments.
- `tofu fmt -check` passes.
- No new Checkov/tfsec suppressions are introduced.
- The fix itself introduces no terraform-docs change; any regeneration of the
  pre-existing README drift (§7/§9) is committed deliberately per the scoping
  decision and leaves `modules/aws/organizations/organization/README.md`
  consistent with `terraform-docs`.
