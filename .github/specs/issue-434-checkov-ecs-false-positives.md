# Spec: Checkov CKV_AWS_224 and CKV_AWS_97 false positives on ECS cluster/task_definition modules
**Issue:** #434
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix
## 1. Background
The repo-wide Checkov Linter step (super-linter's Checkov integration in `test.yml`) is failing on `main`, and — because super-linter scans the whole repo rather than a PR diff — that failure surfaces on every open and future PR regardless of which files it touches (it was first observed on PR #433, which only modernizes `modules/aws/vpc` and never touches ECS). Two findings against pre-existing code are the cause:
- `CKV_AWS_224` — "Ensure ECS Cluster logging is enabled and client to container communication uses CMK" — FAILED on `module.cluster.aws_ecs_cluster.this` (`modules/aws/ecs/cluster/main.tf:210-269`).
- `CKV_AWS_97` — "Ensure Encryption in transit is enabled for EFS volumes in ECS Task definitions" — FAILED on `module.task_definition.aws_ecs_task_definition.this` (`modules/aws/ecs/task_definition/main.tf:93-203`).
Both are Checkov static-analysis false positives, not real security gaps. The modules already implement the underlying control securely by default; Checkov's HCL evaluator simply cannot statically resolve the value through the intervening indirection:
- **CKV_AWS_224**: Checkov's [`ECSClusterLoggingEncryptedWithCMK.py`](https://github.com/bridgecrewio/checkov/blob/main/checkov/terraform/checks/resource/aws/ECSClusterLoggingEncryptedWithCMK.py) requires it to statically resolve a literal `kms_key_id` plus `cloud_watch_encryption_enabled == true` inside the `configuration` block. In this module the key flows through a local (`local.kms_key_arn = module.kms[0].arn`, `modules/aws/ecs/cluster/main.tf:153`) and a triple-nested `dynamic` structure (`configuration` > `execute_command_configuration` > `log_configuration`, `modules/aws/ecs/cluster/main.tf:229-259`). At runtime, with the module's defaults (`create_kms_key = true`, `enable_execute_command_logging = true`, `cloud_watch_encryption_enabled = true`, `execute_command_logging = "OVERRIDE"`), both a CMK-backed `kms_key_id` and CloudWatch log encryption are genuinely enabled. This check has a documented upstream history of dynamic-block/graph-resolution bugs (bridgecrewio/checkov#2985, #4921, #6265).
- **CKV_AWS_97**: Checkov's [`ECSTaskDefinitionEFSVolumeEncryption.py`](https://github.com/bridgecrewio/checkov/blob/main/checkov/terraform/checks/resource/aws/ECSTaskDefinitionEFSVolumeEncryption.py) requires a literal `transit_encryption == "ENABLED"` inside `volume > efs_volume_configuration`. This module's `var.volumes` object type declares `transit_encryption = optional(string, "ENABLED")` — secure by default — but the value is threaded through a caller-supplied `list(object(...))` variable (default `[]`) via a doubly-nested `dynamic "volume" > dynamic "efs_volume_configuration"` block (`modules/aws/ecs/task_definition/main.tf:139-188`), which Checkov cannot resolve back to the object type's default.
The repo already uses inline `checkov:skip` comments for exactly this class of false positive: `modules/aws/ecs/cluster/main.tf:37-39` (`CKV_AWS_111`/`356`/`109` on the KMS key policy) and `modules/aws/ecs/main.tf:105` (`CKV_AWS_65`, container insights not statically resolvable through the `any`-typed cluster object). This spec applies the same, narrowly-scoped pattern to the two new findings.
## 2. Non-goals
- No change to either module's runtime behavior, defaults, public variable/output interface, or resource structure.
- No refactoring of the `dynamic` block nesting or the `local.kms_key_arn` indirection to make Checkov resolve the values (would be a large, risky change for zero security benefit).
- No global `.checkov.yaml` `skip-check` entry for `CKV_AWS_224` or `CKV_AWS_97`. A global suppression would silence these checks across the entire repo, including on future modules where the finding could be legitimate. The two findings are specific to these two resource blocks, so a resource-scoped inline skip is the correct granularity. (This alternative is documented here and explicitly rejected; see § 6.)
- No changes to any other ECS submodule (`service`, `capacity_provider`, the `ecs` wrapper) beyond what is required to keep their tests/docs green (expected: nothing).
## 3. Affected module path(s)
- `modules/aws/ecs/cluster/` (existing) — inline suppression on `aws_ecs_cluster.this`.
- `modules/aws/ecs/task_definition/` (existing) — inline suppression on `aws_ecs_task_definition.this`.
## 4. Proposed design
**Signatures only — no full implementations.** This is a comment-only change; no HCL logic, variables, outputs, or resource arguments are added or modified.
### `variables.tf`
No changes in either module. All relevant controls already exist as variables with secure defaults:
- Cluster: `create_kms_key` (default `true`), `enable_execute_command_logging` (default `true`), `execute_command_logging` (default `"OVERRIDE"`), `cloud_watch_encryption_enabled` (default `true`).
- Task definition: `volumes` — `transit_encryption = optional(string, "ENABLED")` inside the `efs_volume_configuration` object.
### `outputs.tf`
No changes in either module.
### `main.tf`
Add one inline `checkov:skip` comment inside each flagged resource block, following the existing repo pattern (`# checkov:skip=<ID>:<rationale>` placed inside the resource body, as already done at `modules/aws/ecs/cluster/main.tf:37-39`):
- `modules/aws/ecs/cluster/main.tf`, inside `resource "aws_ecs_cluster" "this"` (the block at lines 210-269): add
  `# checkov:skip=CKV_AWS_224:<rationale — CMK-backed kms_key_id and cloud_watch_encryption_enabled are enabled by default; Checkov cannot statically resolve the value through local.kms_key_arn (module.kms[0].arn) and the triple-nested dynamic configuration/execute_command_configuration/log_configuration blocks>`.
- `modules/aws/ecs/task_definition/main.tf`, inside `resource "aws_ecs_task_definition" "this"` (the block at lines 93-203): add
  `# checkov:skip=CKV_AWS_97:<rationale — volumes' efs_volume_configuration defaults transit_encryption to "ENABLED"; Checkov cannot resolve the object-type default through the caller-supplied list(object) var.volumes and the nested dynamic volume/efs_volume_configuration blocks>`.
No `count`/`for_each`, lifecycle, or tagging changes. The existing `lifecycle { precondition { ... } }` on `aws_ecs_task_definition.this` (lines 197-202) is untouched.
Rationale comments must state *why* the finding is a false positive (secure-by-default value + the specific static-resolution limitation), matching the tone and format of the existing `CKV_AWS_111`/`356`/`109` and `CKV_AWS_65` skips already in the ECS tree.
## 5. Breaking-change assessment
- Breaking: **no**.
- Comment-only change. No public interface, default, or generated resource changes; no caller migration required. Per the repo's Conventional Commit bump rules this is a `fix:` (PATCH).
## 6. Checkov / tfsec considerations
- **New suppressions**: two, both inline and resource-scoped, each documented with a false-positive rationale:
  - `CKV_AWS_224` on `modules/aws/ecs/cluster/main.tf` `aws_ecs_cluster.this` — CMK-backed exec-command logging + CloudWatch encryption are on by default; static analyzer cannot trace the value through a local + triple-nested `dynamic` blocks.
  - `CKV_AWS_97` on `modules/aws/ecs/task_definition/main.tf` `aws_ecs_task_definition.this` — EFS `transit_encryption` defaults to `"ENABLED"`; static analyzer cannot trace the object-type default through `list(object)` + nested `dynamic` blocks.
- **Global `.checkov.yaml` alternative — rejected**: adding `CKV_AWS_224` / `CKV_AWS_97` to the root `skip-check` list would disable both checks repo-wide (including on future ECS or task-definition modules where a real violation could occur). Inline skips keep the suppression scoped to the two resources that genuinely need it and keep the rationale next to the code, consistent with the existing ECS suppressions. If review prefers the global scope, it must be added under `.checkov.yaml` with a documented comment matching the file's existing format — but inline is the recommended scope.
- **Existing suppressions affected**: none. The existing `CKV_AWS_111`/`356`/`109` skips on the KMS policy document and the `CKV_AWS_65` skip on the wrapper cluster object remain unchanged.
- **tfsec**: no tfsec suppressions involved; the repo's static-analysis gate here is Checkov.
## 7. terraform-docs impact
None. The change adds only comments inside resource bodies; it does not touch `variables.tf` or `outputs.tf`, so the auto-generated `<!-- BEGIN_TF_DOCS -->` blocks for `modules/aws/ecs/cluster`, `modules/aws/ecs/task_definition`, and the `modules/aws/ecs` wrapper are unchanged. `terraform-docs` verification in CI should pass without regeneration.
## 8. Testing
Validation and formatting (run for both affected modules):
- `tofu -chdir=modules/aws/ecs/cluster init -backend=false && tofu -chdir=modules/aws/ecs/cluster validate`
- `tofu -chdir=modules/aws/ecs/task_definition init -backend=false && tofu -chdir=modules/aws/ecs/task_definition validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/ecs/cluster` and `checkov -d modules/aws/ecs/task_definition` — both must report `Failed checks: 0` for the two targeted IDs, and `checkov -d modules/aws/ecs` (the wrapper, which is how super-linter reaches these resources via the calling file) must no longer surface `CKV_AWS_224` or `CKV_AWS_97`.
Native `tofu test` plan (see `AGENTS.md` § Module Design Specifications § 6). Because this is a comment-only change, the goal is to **prove the pre-existing secure-by-default behavior is still in place** (i.e. that the suppressions describe reality) without weakening or removing any existing case. The existing suites are:
- `modules/aws/ecs/cluster/tests/main.tftest.hcl`
- `modules/aws/ecs/task_definition/tests/main.tftest.hcl`
- `modules/aws/ecs/tests/wiring.tftest.hcl`
Neither the cluster nor the task_definition module declares any variable `validation { ... }` blocks (the task_definition uses a resource-level `lifecycle { precondition }` instead), so there are no `validation`-rule `expect_failures` cases to add. Cases the implementation must ensure exist and pass (extend the existing files; do not delete or loosen existing assertions):
- **Valid baseline (both modules)** — a normal `command = plan` run succeeds. Already present as `fargate_defaults_plan_succeeds` in each suite; must remain green.
- **CKV_AWS_224 behavior assertion (cluster)** — add/keep assertions on `aws_ecs_cluster.this` proving that, under module defaults, the exec-command configuration is CMK-backed and CloudWatch-encrypted: assert `local.kms_key_arn`/`output.kms_key_arn` is non-null, and assert the planned `configuration[0].execute_command_configuration[0].kms_key_id` is set and `log_configuration[0].cloud_watch_encryption_enabled == true`. This documents that the suppressed finding is a false positive.
- **Conditional branches (cluster)** — one `run` per side of each toggle that gates the flagged block:
  - `create_kms_key = true` (default) vs `create_kms_key = false` with a BYO `kms_key_arn` — the existing `bring_your_own_kms_key_does_not_create_one` covers the false side; keep it.
  - `enable_execute_command_logging = true` (default, emits the `execute_command_configuration` block) vs `false` (block omitted) — add a case asserting the `configuration`/`execute_command_configuration` block is absent when disabled.
  - `create_cloud_watch_log_group` true vs false (existing `bring_your_own_log_group_does_not_create_one` covers the false side; keep it).
- **CKV_AWS_97 behavior assertion (task_definition)** — add a `run` supplying `var.volumes` with an `efs_volume_configuration` that omits `transit_encryption`, then assert the planned `volume[*].efs_volume_configuration[0].transit_encryption == "ENABLED"` (proves the secure object-type default is applied). Add a companion `run` with an explicit `transit_encryption = "ENABLED"` to cover the caller-supplied path.
- **Conditional branches (task_definition)** — cover both sides of the volume `dynamic` toggles: the default `volumes = []` baseline (no `volume` block) and at least one `volume` with an `efs_volume_configuration`. Also keep the existing `create_task_role` / `create_execution_role` conditional coverage. The `lifecycle { precondition }` failure path (`task_role_policy_json` set with `create_task_role = false`) should be exercised with an `expect_failures` (or an equivalent error-asserting) `run` block if not already present.
- **Meaningful output assertions** — keep the existing assertions on `output.kms_key_arn` and `output.cloud_watch_log_group_name` (cluster) and the task_definition outputs (e.g. `arn`/`family`/role ARNs); do not reduce them to non-null-only checks.
- **Wiring assertions (wrapper)** — `modules/aws/ecs/tests/wiring.tftest.hcl` must still prove the wrapper passes the created CMK ARN and log-group name into the cluster submodule and role ARNs into the task_definition submodule. Since Checkov reports the findings via the wrapper's calling file (`modules/aws/ecs/main.tf`), keep the kitchen-sink wiring run green as evidence the composed path is unaffected.
All tests must run offline via `mock_provider` / `mock_resource` (matching the existing ECS suites) so `tofu init -backend=false && tofu test`, run from each module directory, passes with no credentials. Do not weaken, skip, or mock away any assertion to force a pass — every case must exercise real module behavior.
## 9. Open questions
- Suppression scope: inline resource-level `checkov:skip` (recommended, matching existing ECS pattern) vs a documented global `.checkov.yaml` entry. This spec recommends inline; reviewers should confirm before implementation. If global is preferred, it does not change the test plan.
- Whether reviewers want the CKV_AWS_224/CKV_AWS_97 "secure-by-default" assertions added as brand-new `run` blocks or folded into the existing `fargate_defaults_plan_succeeds` runs. Either satisfies the coverage requirement; implementation may choose the lower-churn option.
## 10. Acceptance criteria
- [ ] `Test/Linter` (Checkov, via super-linter) passes cleanly on `main` — `CKV_AWS_224` and `CKV_AWS_97` no longer FAIL.
- [ ] If fixed via suppression, each `checkov:skip` comment documents *why* the finding is a false positive, matching the existing pattern in `modules/aws/ecs/cluster/main.tf` (`CKV_AWS_111`/`356`/`109`) and `modules/aws/ecs/main.tf` (`CKV_AWS_65`); and/or a documented global suppression is added to `.checkov.yaml` if reviewers choose that scope.
- [ ] If fixed via remediation instead, the change does not alter either module's existing secure-by-default behavior (CMK-backed exec-command logging, EFS transit encryption default `"ENABLED"`).
- [ ] Existing tests for both modules (`modules/aws/ecs/cluster/tests`, `modules/aws/ecs/task_definition/tests`, `modules/aws/ecs/tests/wiring.tftest.hcl`) still pass, extended per § 8 to assert the secure-by-default behavior the suppressions describe.
- [ ] `tofu fmt -check -diff -recursive` is clean and `terraform-docs` verification passes (no README regeneration needed).
