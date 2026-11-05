# Spec: scalr_workspace remote_state_consumers deprecation diagnostics
**Issue:** #539
**Status:** Draft — pending CODEOWNERS review; reproduction gate in § 9 must be resolved before merge
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
[Issue #539](https://github.com/zachreborn/terraform-modules/issues/539)
reports an `Attribute Deprecated` warning on every workspace apply with
OpenTofu 1.10.7 and Scalr provider 3.20.0, even when callers omit
`remote_state_consumers`. Intentionally configured legacy values must continue
to work; warnings for that usage remain acceptable.

The current workspace submodule forwards an optional, nullable set to
`scalr_workspace.this`. It already supports `remote_state_sharing` and rejects
entries configuring both fields, including an empty consumers set. The root
module constructs `local.workspace_inputs` and calls `module.workspace`.
[Merged PR #528](https://github.com/zachreborn/terraform-modules/pull/528)
added the replacement interface; [open PR #532](https://github.com/zachreborn/terraform-modules/pull/532)
adds its root-module forwarding. At the researched checkout, the root does not
yet forward `remote_state_sharing`.

### Verified evidence and distinction from the reported hypothesis
- The provider's [v3.20.0 workspace schema](https://github.com/Scalr/terraform-provider-scalr/blob/v3.20.0/internal/provider/workspace_schemas.go)
  declares `remote_state_consumers` optional, computed, and deprecated.
  `remote_state_sharing` is optional and computed. The
  [resource validators](https://github.com/Scalr/terraform-provider-scalr/blob/v3.20.0/internal/provider/workspace_resource.go)
  declare these fields conflicting.
- The [v3.20.0 provider documentation](https://github.com/Scalr/terraform-provider-scalr/blob/v3.20.0/docs/resources/workspace.md)
  describes the legacy set, wildcard sharing, and the replacement
  `scalr_workspace_remote_state_consumer` resource.
- The provider [pins Plugin Framework v1.17.0](https://github.com/Scalr/terraform-provider-scalr/blob/v3.20.0/go.mod).
  Its [attribute validation](https://github.com/hashicorp/terraform-plugin-framework/blob/v1.17.0/internal/fwserver/attribute_validation.go)
  emits `Attribute Deprecated` only when the configured value is neither null
  nor unknown. Syntactic presence alone is therefore **not an established
  cause** for the reported versions.
- The issue's sample diagnostic points to an inline workspace resource in
  `modules/scalr/main.tf`; the current checkout instead declares it in
  `modules/scalr/workspace/main.tf`. Reconcile the actual consumed module ref,
  downloaded module contents, resolved provider, and effective input before
  changing resource topology.

This specification chooses a **state-address-preserving, null-preserving
compatibility contract**, with a reproduction gate rather than an unverified
two-resource workaround. It does not assert that the current null assignment
is defective. If the existing configuration already satisfies the contract,
the appropriate result is regression coverage and corrected guidance, not
resource churn or an artificial code change.

## 2. Non-goals
- Removing the deprecated input, converting legacy consumer sets into
  separately managed relationship resources, or changing account sharing
  defaults.
- Renaming, partitioning, or nesting workspace resources; requiring callers
  to move state merely to silence a warning.
- Suppressing CLI warnings globally, changing provider deprecation metadata,
  hiding unrelated warnings for `operations` or `vcs_repo.path`, or weakening
  validation.
- Reimplementing #532, broadening provider argument coverage, changing tags,
  or changing unrelated Scalr modules.
- Implementing Terraform/OpenTofu changes in this spec PR. This PR adds only
  this document under `.github/specs/`.

## 3. Affected module path(s)
- `modules/scalr/workspace/` (existing): `main.tf` only if a reproduced
  null-forwarding defect requires correction; descriptions in `variables.tf`,
  README guidance, and `tests/*.tftest.hcl` for regression coverage.
  `outputs.tf` retains its existing interface.
- `modules/scalr/` (existing wrapper): legacy-variable documentation and
  `tests/` wiring coverage. Any actual normalization correction is limited to
  `local.workspace_inputs`; retain the existing precedence contract.
  Modern-field forwarding depends on #532 as described in § 9.
- `modules/scalr/workspace/remote_state_consumer/` is a documentation reference,
  not an implementation target or a newly called child module.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No new workspace inputs or changed types/defaults:
- `workspaces`: existing map of workspace objects, default `{}`; creates
  workspaces keyed by caller-selected logical names. Its complete type is
  the declaration in `modules/scalr/workspace/variables.tf`, unchanged,
  including all unrelated scalar and nested attributes.
  Relevant fields:
  - `environment_id`: required `string`, existing environment ID.
  - `name`: `optional(string)`, default null; fall back to the map key.
  - `remote_state_consumers`: `optional(set(string))`, default null; deprecated
    explicit consumer IDs or `["*"]`. Omission and explicit null mean no
    configured legacy value. An empty set is an intentional legacy value,
    not null, and must not be normalized away.
  - `remote_state_sharing`: `optional(bool)`, default null; explicit true/false
    overrides account-wide sharing, while null defers to the provider.
  - `runner_image_version_id`: `optional(string)`, default null; unchanged
    container-image-version input.
- Retain all six existing validations: `auto_queue_runs`, `execution_mode`,
  `iac_platform`, `type`, consumers/sharing mutual exclusivity, and runner
  image ID format. Add no new validation rules for this fix.
- Clarify the consumers description: intentional non-null usage may warn;
  null is not a request to manage consumers; never combine legacy ownership
  with the consumer submodule for the same source workspace.

Root-module signatures remain:
- `workspace_remote_state_consumers`: `list(string)`, default null; legacy
  fallback for a workspace whose YAML entry omits the key and does not select
  the modern counterpart under #532's conflict-resolution contract. Document
  deprecation and distinguish a configured legacy fallback from an omitted input.
- `scalr_config`: required `string`; YAML environment/workspace configuration,
  unchanged.
- The modern `workspace_remote_state_sharing` input (`bool`, default null)
  and associated forwarding belong to #532, not an independently invented
  interface in this issue.

### `outputs.tf`
Preserve names, values, key sets, and effective-value semantics:
- `ids`: `map(string)` of workspace IDs.
- `has_resources`: `map(bool)` of active-resource indicators.
- `created_by`: map of provider creator-detail lists, with `email`,
  `full_name`, and `username` string fields.
- `remote_state_sharing`: `map(bool)` of effective provider values, including
  account defaults when configuration is null; do not substitute the nullable
  input for this computed output.
- Root `workspace_ids`: `map(string)` keyed by `<environment>.<workspace>`,
  still obtained from `module.workspace.ids`.
- Root `workspace_resolved_settings`, supplied by #532: map of objects with
  `remote_state_consumers`, `remote_state_sharing`, and
  `runner_image_version_id` fields; surfaces resolved nullable inputs, not
  provider-computed effective sharing. Preserve it for wiring assertions.
- No new diagnostic/public output is needed for #539.

### `main.tf`
- Retain resource signature `resource "scalr_workspace" "this"` and the
  `for_each` domain of all `var.workspaces` keys. Retain root
  `module "workspace"` with source `./workspace` and
  `workspaces = local.workspace_inputs`.
- Preserve null through the entire input chain. The root's existing
  `try(ws.remote_state_consumers, var.workspace_remote_state_consumers)`
  semantics distinguish a missing YAML key (uses fallback) from explicit
  YAML null (overrides the fallback with null). Do not replace this with
  `coalesce`, an empty set, or an account-wide default.
- After integrating #532, preserve its additional rule: a per-workspace
  modern value suppresses the conflicting global legacy default and a
  per-workspace legacy value suppresses the global modern default. Do not
  regress this to unconditional fallback; consult its resolved-settings
  tests when combining changes.
- A non-null root fallback is intentional legacy usage for entries that
  omit their own setting. It is allowed to produce the warning. Do not label
  such a case a warning from an unused input.
- Forward legacy sets unchanged, including `[]`, `["*"]`, and explicit IDs.
  Forward modern true/false without enabling legacy ownership. Do not branch
  resource identity on nullness or require input values to be known merely
  to retain the already-known workspace keys.
- Preserve every other argument, the name fallback, `tag_ids`, and optional
  `hooks`, `provider_configuration`, `terragrunt`, and `vcs_repo` blocks.
  There are no existing lifecycle ignores on this resource and none are added.
  Scalr uses tag IDs, not an AWS-style `tags` map; do not introduce a `Name`
  tag policy or inline cross-cutting resources.
- Keep workspace floors `required_version >= 1.9.0` and Scalr `>= 3.20.0`.
  No new language/provider feature requires a bump. Preserve the wrapper's
  effective dependency on the child/provider floor and #532's constraints.
- If § 9 identifies a provider-only defect rather than module
  normalization, record an upstream reproducer and revise this spec before
  approval. Do not silently substitute a provider fork, version-floor bump,
  resource split, or relationship-resource migration.

## 5. Breaking-change assessment
- **Breaking: no**, under the selected design. Public types, defaults,
  outputs, legacy semantics, and workspace state addresses remain unchanged.
- Existing direct instances stay at `scalr_workspace.this["<key>"]` inside
  their caller module; composed instances stay at
  `module.workspace.scalr_workspace.this["<environment>.<workspace>"]`
  relative to the wrapper. No `moved` blocks, imports, or `state mv` commands
  are required. Switching an existing key between modern and legacy inputs
  must not create or destroy its workspace.
- Reject the issue's suggested split as an assumed no-break solution:
  a static `moved` block cannot dynamically route arbitrary existing keys
  between two destinations by input value. Retaining `this` for one partition
  still changes addresses for the other and for later mode switches.
  Such a topology change needs a separately reviewed migration design and
  demonstrated warning benefit, not a blanket `moved` declaration.

## 6. Checkov / tfsec considerations
- New suppressions: **none**.
- Existing suppressions affected: **none**. Preserve `.checkov.yaml` and
  existing fixture annotations; do not suppress diagnostic output.
- Keep deletion protection, remote backend settings, and state-sharing
  defaults unchanged. Neither warning handling nor tests may implicitly
  broaden remote-state access.

## 7. terraform-docs impact
- Regenerate `modules/scalr/workspace/README.md` after clarifying the
  `workspaces` description. Its generated input-description block changes;
  variable types/defaults, output signatures, and resource inventory do not.
- Regenerate `modules/scalr/README.md` after documenting the deprecated root
  fallback. Its generated variable description changes; do not overwrite
  #532's documentation.
- Handwritten notes must explain omission/null/empty-set behavior, intentional
  global legacy defaults, the modern sharing/consumer-submodule alternative,
  and that no workspace state migration is needed.
- Use the repository's per-module `terraform-docs markdown table
  --output-file README.md --output-mode inject <module_path>` command.
  This spec-only PR does not regenerate or modify module READMEs.

## 8. Testing
Follow `modules/module_template/tests/` and the mocked resource, validation,
and wiring conventions in `modules/aws/organizations/tests/`. Native tests
must require neither Scalr credentials nor a live backend. Initialize provider
dependencies first; the test executions themselves must be offline.

### Workspace baseline, branches, and outputs
Extend `modules/scalr/workspace/tests/main.tftest.hcl`, preserving existing runs:
- Valid baseline: one minimal workspace, both sharing inputs omitted. Assert
  the resource key/name/environment, default deletion protection, and exact
  public output values using deterministic mock computed attributes.
- Separate cases for omitted consumers, explicit null consumers, modern
  false, modern true, legacy empty set, legacy wildcard, and legacy specific
  IDs. Assert exact configured resource values for known inputs, and all
  output key sets. A computed legacy attribute may acquire a mock value even
  when configuration is null; inspect `var.workspaces` to assert input nullness
  rather than treating computed state as proof of configuration presence.
- Mixed map: modern, legacy, and omitted entries coexist; assert exact
  consumers and sharing inputs per key and no lost or duplicate workspace.
- Empty map: zero instances and **all four** outputs are empty maps.
- Preserve present/absent coverage of `hooks`, `terragrunt`, and `vcs_repo`,
  and zero/multiple `provider_configuration` entries; preserve runner ID
  present/absent and `operations` forwarding coverage.
- Give computed `id`, `has_resources`, creator details, and unset effective
  sharing deterministic mock defaults. Assert exact IDs, false/true values,
  and all creator fields, not merely non-null results. Explicit modern
  false/true must win over mock computed defaults.
- No resource-partition branch or new conditional is introduced. Test both
  empty/nonempty `for_each` domains and both sides of each existing optional
  block condition.

### Variable validation failures
Retain and run `modules/scalr/workspace/tests/validation.tftest.hcl`.
Each negative run uses `expect_failures = [var.workspaces]` and otherwise-valid
inputs so another validation cannot accidentally satisfy the expectation:
- Invalid `auto_queue_runs`, invalid non-null `execution_mode`, invalid
  `iac_platform`, and invalid `type`: one independent run each.
- Mutual exclusivity: nonempty specific consumers plus sharing false;
  wildcard plus sharing true; empty consumers plus sharing false; add empty
  consumers plus sharing true. Retain the mixed-map conflicting-entry case.
- Runner image format: wrong prefix, different resource ID, prefix only,
  empty string, and trailing whitespace, each independently rejected.
- Preserve positive cases for null execution mode, valid runner ID, legacy
  alone, modern alone, both fields omitted, and both fields explicitly null.
  There are no new validations whose failure cases can be omitted.

### Root composition wiring
Add `modules/scalr/tests/workspace_remote_state.tftest.hcl` with mocked
environment/workspace resources, not mocked child modules:
- Assert `local.workspace_inputs` contains the exact composite keys, resolved
  environment ID, and sharing configuration actually supplied to
  `module.workspace`; also assert exact `output.workspace_ids` values.
- Distinguish missing YAML consumer key with null global fallback, missing
  key with a non-null global fallback, explicit YAML null overriding that
  fallback, and per-entry specific/empty/wildcard overrides.
- After #532 is integrated, assert modern false/true are forwarded with
  consumers null, both unset stay null, and mixed legacy/modern entries
  retain independent values. Include no-workspace and multiple-workspace
  cases. Assert exact `output.workspace_resolved_settings` values, including
  per-entry modern values suppressing global legacy defaults and the reverse.
  This output proves resolved-input wiring, not effective provider sharing;
  the workspace submodule tests prove the computed-output contract separately.
- Keep invalid-input expectations in the workspace submodule, where
  `var.workspaces` is checkable; do not pretend wrapper
  `expect_failures` can reference a nested child's variable.

### Real diagnostic and upgrade evidence
Mock providers replace real validation behavior. Native assertions alone do
**not** prove warning absence or the real legacy warning. Before approval,
record the § 9 minimal reproducer and its versions. During implementation,
capture unfiltered real-provider validate/plan diagnostics and, in a disposable
authorized Scalr environment, apply diagnostics for omitted, explicit-null,
modern false/true, and intentional legacy values. Match both the diagnostic
summary and its `remote_state_consumers` detail/path; unrelated deprecations
are outside this guarantee. Legacy cases may warn but must still work.
Do not require these live operations in the offline test suite.

Compare a pre-upgrade and post-upgrade plan for existing modern and legacy
workspaces, and for one existing key changing modes. Require unchanged IDs
and no address-driven create/delete/replacement. Preserve account sharing
behavior; a clean mock test cannot establish real account defaults.

### Implementation verification commands
- `tofu -chdir=modules/scalr/workspace init -backend=false`, then `validate`
  and `test` with the same `-chdir`.
- `tofu -chdir=modules/scalr init -backend=false`, then `validate` and `test`.
- `tofu fmt -check -diff -recursive`.
- `checkov -d modules/scalr/workspace` and `checkov -d modules/scalr`.
- Regenerate both affected module READMEs and verify generated blocks match
  committed content. Run equivalent Terraform initialization/validation for
  dual-tool compatibility.
- For this spec-only PR, check template-section completeness, Markdown,
  whitespace, and the changed-file allowlist. Do not claim runtime tests ran
  or create infrastructure to validate a documentation-only change.

## 9. Open questions
- **Merge blocker — reconcile the reported null warning.** Obtain a minimal
  reproducer using the exact consumed module commit, installed provider
  lock entry/address, OpenTofu 1.10.7, and redacted effective inputs. Determine
  whether the legacy value is null at provider configuration time or is
  populated by a root fallback/stale module. Explain the mismatch with the
  pinned framework's null/unknown warning guard. Attach diagnostic evidence
  and revise this spec with the demonstrated correction before merging;
  this unresolved draft must not trigger implementation as if a resource
  split had been validated.
- **Integration prerequisite — #532.** Rebase the implementation on its merged
  root forwarding and modern output interface before exercising modern root
  cases. If #532 is not merged, resolve ordering with CODEOWNERS before this
  spec merges; do not silently expand #539 to reimplement that PR.
- No unresolved public-interface or state-migration choice remains within
  the selected contract. If evidence requires either to change, amend and
  re-review the specification first.

## 10. Acceptance criteria
- Workspaces with omitted/null legacy consumers, whether modern sharing is
  set or both fields are unset, apply without the `remote_state_consumers`
  `Attribute Deprecated` warning, demonstrated with the real provider.
- Intentional non-null legacy values, including empty sets, wildcard, specific
  IDs, and root defaults, retain their existing behavior and may warn.
- Existing per-entry mutual-exclusivity validation and all other validations
  continue to pass their positive and negative native test cases.
- Native tests cover the null/modern and legacy configurations, all relevant
  conditional branches, exact meaningful outputs, and real wrapper wiring;
  real diagnostics are verified separately rather than inferred from mocks.
- README and variable descriptions explain caller-visible behavior and are
  regenerated with terraform-docs; no new security suppression is introduced.
- Public signatures, key sets, account sharing defaults, and
  `scalr_workspace.this` state addresses remain unchanged; no workspace
  replacement or caller state migration is caused by this fix.
- The § 9 reproduction blocker and #532 ordering are resolved before spec
  merge. If evidence shows no module defect, record that result and amend
  the issue/spec disposition rather than ship an ineffective topology change.
