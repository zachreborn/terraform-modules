# Spec: Add standalone IAM instance profile module
**Issue:** #514
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The IAM catalog (`modules/aws/iam/`) has `access_analyzer`, `group`,
`openid_connect_provider`, `password_policy`, `organizations_features`, `policy`,
`role`, `saml_provider`, `user`, and `user_policy_attachment` — but **no module
for `aws_iam_instance_profile`**. Callers who need only a profile on an existing
role therefore have two bad options:

1. Declare a raw `aws_iam_instance_profile` resource in the account/workspace
   repo, which breaks the "IAM objects live in modules" convention and gets
   copy-pasted across `aws_*` account repos; or
2. Pull in `modules/aws/session_manager`, which creates an instance profile
   (`modules/aws/session_manager/main.tf (68-72)`) **and** unconditionally
   creates an `aws_ssm_document` named `SSM-SessionManagerRunShell` — a
   region-wide singleton that collides with any pre-existing Session Manager
   preferences. That module also composes `modules/aws/iam/role`, so it *creates*
   the role rather than attaching to one the caller already owns.

This spec adds a focused, additive module that creates exactly one
`aws_iam_instance_profile` and nothing else.

Issue: https://github.com/zachreborn/terraform-modules/issues/514
Related context only: #179 (`session_manager` 2025 refresh, merged).
Provider resource:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
Provider schema:
https://github.com/hashicorp/terraform-provider-aws/blob/main/internal/service/iam/instance_profile.go

Four facts taken from the provider schema shape this spec, because none of them
are obvious from the issue:

- **The full argument surface is small and complete here.**
  `aws_iam_instance_profile` accepts only `name`, `name_prefix`, `path`, `role`,
  and `tags`. The five variables in § 4 therefore satisfy `AGENTS.md` § 1
  (complete resource coverage) with nothing omitted.
- **There is no `region` argument.** IAM is a global service, so the AWS
  provider v6 "enhanced region support" argument present on regional resources
  (e.g. `modules/aws/managed_prefix_list/variables.tf (47-51)`) does **not**
  exist on this resource. The module must not expose a `region` variable.
- **`id` is the instance profile's name.** The create path calls
  `d.SetId(aws.ToString(output.InstanceProfile.InstanceProfileName))`, so `id`
  and `name` are always the same string. `id` is still exposed (see § 4 and
  § 9) because every sibling that has one — `modules/aws/iam/policy/outputs.tf`,
  `modules/aws/iam/user/outputs.tf`, `modules/aws/iam/group/outputs.tf` — does.
- **`role` is an unvalidated, optional string in the provider.** It is applied
  via a separate `AddRoleToInstanceProfile` call *after* create, and the
  provider performs no ARN-vs-name check. Passing a role ARN therefore fails at
  **apply** time, after the profile has already been created, with an opaque IAM
  error. The module's plan-time validation (§ 4) converts that into a clear
  plan-time failure, which is the main reason the issue calls for it.

Length limits used by the validations in § 4 come from the same file:
`instanceProfileNameMaxLen = 128` and
`instanceProfileNamePrefixMaxLen = 128 - 26 = 102`
(`sdkid.UniqueIDSuffixLength` is 26).

## 2. Non-goals
- **No changes to `modules/aws/session_manager`.** No refactor to compose this
  module, no state moves, no input/output renames, no resource-address changes.
  Swapping its inline `aws_iam_instance_profile.default` for a child module call
  would be a breaking state-address change and needs its own issue, PR, and
  migration note. The optional docs-only note on that module ("not a generic
  instance-profile factory") is explicitly **not** part of this work.
- **No role creation or lookup.** The module does not create `aws_iam_role`,
  does not call `modules/aws/iam/role`, and does not use a
  `data "aws_iam_role"` lookup to resolve or verify the role. `var.role` is
  passed straight through. This keeps the module a pure wrapper and keeps
  `tofu test` fully offline.
- **No policy attachments.** No `aws_iam_role_policy_attachment`,
  `aws_iam_policy`, or inline policy. Those belong to `modules/aws/iam/role`
  and `modules/aws/iam/policy`.
- **No SSM / Session Manager resources.** No `aws_ssm_document`, no Session
  Manager preferences, no EC2 attachment. This is the whole point of the module.
- **No ARN → name coercion.** A role ARN is rejected, not silently parsed. See
  § 4 and § 9.
- **No map / YAML fan-out input** (`AGENTS.md` § 5). The issue explicitly lists
  this as out of scope for v1; callers use `for_each` on the module block. The
  resource has no cross-instance relationships, so a map input can be added
  later as a purely additive `feat:` if demand appears. See § 9.
- **No `global/` or caller changes.** Wiring any consumer onto the new module is
  out of scope.

## 3. Affected module path(s)
- `modules/aws/iam/instance_profile/` (**new**) — `main.tf`, `variables.tf`,
  `outputs.tf`, `README.md`, `tests/`

The path is taken verbatim from the issue and matches the sibling layout
(`modules/aws/iam/role`, `modules/aws/iam/policy`) — **not**
`modules/iam/instance_profile`.

No existing module is read, modified, or called. `modules/aws/iam/role` appears
only in a README usage example as the caller-side source of the role name.

## 4. Proposed design
**Signatures only — no full implementations.**

### Design decisions the implementation must honour

**Exactly one of `name` / `name_prefix` (issue AC 8).** This is a cross-variable
constraint, which a `validation { ... }` block cannot express below Terraform
1.9. It is therefore enforced with a `lifecycle { precondition }` block on the
resource, following the `modules/aws/managed_prefix_list/main.tf (33-47)`
precedent. Both failure directions — neither set, and both set — must fail at
plan time. Note that this is deliberately stricter than the provider (which
would generate a random name when both are omitted) and stricter than
`modules/aws/iam/role`, which performs no such check; see § 9.

**No composition.** `AGENTS.md` § 2 forbids declaring another domain's resources
inline, but this module declares none — a profile on a caller-supplied role is
single-domain by construction. There are no child module calls and therefore no
wiring tests in § 8.

### `variables.tf`

- **`name`** — `string`, default `null`. Name of the instance profile. Forces
  replacement. Must be unique within the account regardless of `path` or `role`.
  Exactly one of `name` / `name_prefix` is required (precondition P1).
  `validation`: when non-null, matches `^[\w+=,.@-]{1,128}$` — the provider's
  `validResourceName(128)` charset and limit.
- **`name_prefix`** — `string`, default `null`. Creates a unique name beginning
  with this prefix. Forces replacement. Exactly one of `name` / `name_prefix` is
  required (precondition P1). `validation`: when non-null, matches
  `^[\w+=,.@-]{1,102}$` — 128 minus the provider's 26-character unique suffix.
- **`path`** — `string`, default `"/"`. Path to the instance profile. Forces
  replacement. `validation`: begins and ends with `/` and is at most 512
  characters (AWS's `PathType` constraint; the provider itself does not validate
  this, so a bad value would otherwise fail at apply).
- **`role`** — `string`, **required** (no default). **IAM role *name*, not an
  ARN.** Three separate `validation` blocks so each failure names its own cause:
  1. **Non-empty** — rejects `""`.
  2. **Not an ARN** — rejects any value where `startswith(var.role, "arn:")`.
     The error message must say that the role *name* is required and show how to
     get it (`module.my_role.name`, or the last path segment of the ARN). Do
     **not** parse an ARN into a name.
  3. **Valid IAM role name** — matches `^[\w+=,.@-]{1,64}$` (AWS's
     `roleNameType`: 64 characters, `[\w+=,.@-]`). This also rejects a
     role-with-path form such as `/service/my-role`.
- **`tags`** — `map(string)`, default `{ terraform = "true" }`, matching
  `modules/aws/iam/role/variables.tf (56-62)`.

### `outputs.tf`
Every attribute the provider exports is surfaced (`AGENTS.md` § 1):

- **`arn`** — ARN assigned by AWS to the instance profile
  (`aws_iam_instance_profile.this.arn`). Issue-requested.
- **`name`** — resolved profile name, including one generated from
  `name_prefix`. Issue-requested.
- **`unique_id`** — AWS-assigned unique ID. Issue-requested.
- **`id`** — the profile's ID, which AWS sets to its name. Exposed for parity
  with sibling IAM modules; the description must state that it equals `name`.
- **`create_date`** — creation timestamp.
- **`path`** — applied path, read back off the resource.
- **`role`** — the role name attached to the profile, read back off the resource
  (`aws_iam_instance_profile.this.role`), **not** echoed from `var.role`. This
  is what lets the § 8 role-binding case assert real resource state.
- **`tags_all`** — tags including any inherited from the provider's
  `default_tags` block.

### `main.tf`

**`terraform {}` block** (`AGENTS.md` § 7 — per-module floors, each with a
one-line comment giving the reason):

- `required_version = ">= 1.2.0"` — `lifecycle { precondition }` is used for the
  `name`/`name_prefix` check and was introduced in Terraform 1.2.0. This is
  above the repo baseline `>= 1.0.0` and below `modules/aws/managed_prefix_list`'s
  `>= 1.3.0`, because no `optional()` object attributes are used. OpenTofu
  1.6.0+ satisfies it.
- `aws version = ">= 6.0.0"` — the repo baseline. Every argument and attribute
  this module touches (`name`, `name_prefix`, `path`, `role`, `tags`, `arn`,
  `create_date`, `id`, `tags_all`, `unique_id`) has existed since well before
  AWS provider 6.0; no bump is warranted and none should be added "to be safe".

**No data sources and no locals** are required.

**`resource "aws_iam_instance_profile" "this"`** — a single instance, no
`count` / `for_each`. Arguments:

- `name = var.name_prefix == null ? var.name : null`
- `name_prefix = var.name_prefix != null ? var.name_prefix : null`
  (the same mutually-exclusive idiom as
  `modules/aws/iam/role/main.tf (48-49)`, so the provider's `ConflictsWith` can
  never trip)
- `path = var.path`
- `role = var.role`
- `tags = merge(var.name != null ? tomap({ Name = var.name }) : {}, var.tags)`

The tag expression deliberately guards the `Name` key: the repo convention
(`AGENTS.md` § Code Conventions) is `merge(tomap({ Name = var.name }), var.tags)`,
but under `name_prefix` the name is null and the final name is unknown at plan
time, so an unguarded merge would emit a `Name` tag with a null value. The guard
keeps the convention for the `name` branch and omits the key entirely for the
`name_prefix` branch. Both branches are covered by § 8 cases. This is a
deliberate, documented divergence from `modules/aws/iam/role`, which sets
`tags = var.tags` with no `Name` merge at all; see § 9.

**`lifecycle { precondition ... }`** on `aws_iam_instance_profile.this`:

- **P1** — exactly one of `var.name` / `var.name_prefix` is set. The error
  message must name both variables and state that one, and only one, is
  required.

**No `lifecycle { ignore_changes = ... }`.** Nothing on this resource is mutated
outside Terraform, so the `aws_instance` ignore pattern does not apply.

**Section headers** follow the repo's `###########################` convention
(`Provider Configuration`, `Instance Profile`).

### `README.md`
Per `AGENTS.md` § 4, outside the generated block:

- **Description** — manages a single `aws_iam_instance_profile` attached to an
  existing IAM role.
- **Prerequisites** — the IAM role must already exist and must trust
  `ec2.amazonaws.com` (or the relevant service); this module neither creates nor
  verifies it.
- **Usage examples** — at minimum (a) the issue's primary case: a profile for a
  role created by `modules/aws/iam/role`, passing `module.<role>.name` into
  `role`; (b) a `name_prefix` variant; (c) a non-root `path` with custom `tags`.
- **Notes / design decisions**, which must state explicitly:
  - `role` takes a role **name**, not an ARN; an ARN fails at plan time, and
    `modules/aws/iam/role` exposes `name` for exactly this purpose.
  - **This module does not configure Session Manager** and creates no
    `aws_ssm_document`; use `modules/aws/session_manager` if you want Session
    Manager preferences (issue AC 10).
  - Exactly one of `name` / `name_prefix` must be set.
  - `id` is the profile name, so it duplicates `name`.
  - The `Name` tag is merged only when `name` is set.
- The `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers.

## 5. Breaking-change assessment
- Breaking: **no**.
- Purely additive. A brand-new module directory with no callers; no existing
  module's variables, outputs, resources, defaults, or state addresses change.
  `modules/aws/session_manager` is untouched, so its existing callers — and its
  `aws_iam_instance_profile.default` state address — are unaffected.
- The `required_version = ">= 1.2.0"` floor applies only to this new module and
  cannot affect any existing caller. It is satisfied by every supported OpenTofu
  release (1.6.0+) and by Terraform 1.2.0+.
- Conventional Commit type: `feat:` → MINOR under the repo's release-please
  rules.

## 6. Checkov / tfsec considerations
- **New suppressions: none.** No inline `#tfsec:ignore:` or `#checkov:skip=`
  comment is planned, and no new entry in the repo-root `.checkov.yaml`.
  Rationale:
  - `aws_iam_instance_profile` has no encryption, logging, public-access, or
    policy-document surface for a check to flag. The module creates no policy
    and grants no permissions, so the IAM wildcard checks (`CKV_AWS_290`,
    `CKV_AWS_355`) have nothing to evaluate — and they are globally skipped in
    `.checkov.yaml (162-164)` anyway.
  - `CKV_TF_1` (module sources must use a git URL with a commit hash) is
    globally skipped in `.checkov.yaml:16` and is moot here, since the module
    calls no child modules.
  - `skip-path: tests/` in `.checkov.yaml (10-11)` already covers the new
    `tests/` fixtures.
- **Existing suppressions affected: none.** No `.checkov.yaml` entry relates to
  instance profiles, and no existing module is touched.
- The implementation must still run
  `checkov -d modules/aws/iam/instance_profile` locally. If a check does fire,
  the fix is to correct the module — not to add a suppression — unless the
  finding is genuinely caller-controlled, in which case a new `.checkov.yaml`
  entry must be added in the same documented format as the existing ones and
  this section updated in review.

## 7. terraform-docs impact
**Yes — one new generated block, no changes to any existing one.**

- `modules/aws/iam/instance_profile/README.md` gains a fresh
  `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` block with Requirements
  (`terraform >= 1.2.0`, `aws >= 6.0.0`), Providers, Resources
  (`aws_iam_instance_profile`), Inputs (`name`, `name_prefix`, `path`, `role`,
  `tags`), and Outputs (`arn`, `create_date`, `id`, `name`, `path`, `role`,
  `tags_all`, `unique_id`). The Modules table will be empty — this module calls
  none.
- No other module's README changes; no existing module is edited.

The implementation must generate the block locally —
`pre-commit run --all-files`, or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/iam/instance_profile`
— and commit the result. The `Verify - terraform-docs` job fails on any diff and
does not auto-commit.

## 8. Testing
Standard local checks:

- `tofu -chdir=modules/aws/iam/instance_profile init -backend=false && tofu -chdir=modules/aws/iam/instance_profile validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/iam/instance_profile` (locally; CI runs on schedule)

Native `tofu test` plan (required — `AGENTS.md` § Module Design Specifications
§ 6). Every case uses `command = plan`, follows the `mock_provider` / `run` /
`expect_failures` conventions in `modules/aws/managed_prefix_list/tests/` and
`modules/aws/organizations/account/tests/validation.tftest.hcl`, and must pass
fully offline via
`tofu -chdir=modules/aws/iam/instance_profile init -backend=false && tofu -chdir=modules/aws/iam/instance_profile test`
with no credentials and no backend.

### Shared mock setup
Both test files declare:

```
mock_provider "aws" {
  mock_resource "aws_iam_instance_profile" {
    defaults = {
      arn         = "arn:aws:iam::123456789012:instance-profile/mock-profile"
      id          = "mock-profile"
      unique_id   = "AIPAMOCKUNIQUEID12345"
      create_date = "2026-01-01T00:00:00Z"
    }
  }
}
```

Mocking only the computed attributes keeps every configured argument (`name`,
`name_prefix`, `path`, `role`, `tags`) a real planned value the assertions can
test.

### `tests/main.tftest.hcl` — baseline, branches, outputs
- **`plan_succeeds_with_valid_baseline`** — only `name = "example-profile"` and
  `role = "example-role"`. Assert `aws_iam_instance_profile.this.name` equals
  the input, `name_prefix == null`, `path == "/"` (the default), and
  `role == "example-role"`. This is the required valid-baseline case
  (issue AC 1).
- **`profile_is_the_only_resource_type_planned`** — same inputs, with the
  `mock_provider` block declaring a `mock_resource` **only** for
  `aws_iam_instance_profile`. Assert that the profile planned successfully
  (`aws_iam_instance_profile.this.name` equals the input). `tofu test` cannot
  enumerate planned addresses from inside a `run` block, so the "zero
  `aws_ssm_document` / `aws_iam_role` / `aws_iam_policy` /
  `aws_iam_role_policy_attachment`" half of issue AC 1 and AC 9 is pinned by two
  mechanisms the implementation must satisfy instead, both of which are
  committed artifacts rather than reviewer memory:
  1. The module declares exactly one `resource` block (§ 4), so the
     `terraform-docs` **Resources** table committed in `README.md` lists
     `aws_iam_instance_profile` and nothing else. `Verify - terraform-docs`
     fails if that table ever drifts, which makes any added resource type a CI
     failure.
  2. Only `aws_iam_instance_profile` is mocked. Adding any other AWS resource
     to the module leaves it unmocked, and its computed attributes become
     unknown — so any test asserting on them fails rather than silently
     passing.

  Do not add a `mock_resource` for a resource type the module does not create
  in order to "cover" this case.
- **`outputs_expose_profile_attributes`** — same inputs. Assert
  `output.arn == "arn:aws:iam::123456789012:instance-profile/mock-profile"`,
  `output.id == "mock-profile"`, `output.unique_id == "AIPAMOCKUNIQUEID12345"`,
  `output.create_date == "2026-01-01T00:00:00Z"`, `output.name` equals the
  configured name, `output.path == "/"`, and `output.role == "example-role"` —
  each compared to a real expected value, never merely `!= null`. Issue AC 2.
- **`arn_output_matches_instance_profile_arn_shape`** — same inputs. Assert
  `can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:instance-profile/", output.arn))`.
  Issue AC 2's ARN-shape requirement.
- **`role_binding_matches_role_input`** — `role = "custom-role-name"`. Assert
  `aws_iam_instance_profile.this.role == "custom-role-name"` **and**
  `output.role == "custom-role-name"`. Issue AC 3.
- **`custom_path_and_tags_are_applied`** — `path = "/service-role/"`,
  `tags = { Environment = "sandbox" }`. Assert the resource's `path` equals the
  input; that `tags["Environment"] == "sandbox"`; that `tags["Name"]` equals the
  configured `name` (proving the `Name` merge); and that `tags["terraform"]` is
  **absent**, proving a caller-supplied map replaces the default rather than
  merging with it. Issue AC 4.
- **`default_tags_are_applied_when_tags_are_omitted`** — baseline inputs with no
  `tags`. Assert `tags["terraform"] == "true"` and `tags["Name"]` equals the
  configured name. Covers the default side of `var.tags`.
- **`name_prefix_branch_sets_prefix_and_omits_name`** — `name_prefix = "example-"`,
  `name` null. Assert `aws_iam_instance_profile.this.name_prefix == "example-"`,
  `aws_iam_instance_profile.this.name == null`, and that the planned `tags` map
  has **no** `Name` key — covering the other side of the guarded-merge
  conditional. Issue AC 5.
- **`name_branch_omits_name_prefix`** — `name` set, `name_prefix` null. Assert
  `name_prefix == null`. Covers the other side of the
  `var.name_prefix == null ? ... : ...` conditionals in `main.tf`.

### `tests/validation.tftest.hcl` — one case per failure mode
`expect_failures` on the variable for `validation` blocks, and on
`aws_iam_instance_profile.this` for the precondition — the pattern used in
`modules/aws/managed_prefix_list/tests/validation.tftest.hcl (80, 94)`. Every
case supplies otherwise-valid inputs so it can fail only for the reason under
test.

- **`valid_baseline_does_not_fail`** — minimal valid input; assert
  `aws_iam_instance_profile.this.role` equals the supplied role, proving the
  validations do not reject the happy path.
- **`rejects_empty_role`** — `role = ""` → `expect_failures = [var.role]`.
  Issue AC 6.
- **`rejects_role_arn`** — `role = "arn:aws:iam::123456789012:role/example"` →
  `expect_failures = [var.role]`. Issue AC 7.
- **`rejects_role_with_invalid_characters`** — e.g. `role = "bad/role name"` →
  `expect_failures = [var.role]`. Covers the charset rule distinctly from the
  empty and ARN rules.
- **`rejects_role_longer_than_64_characters`** → `expect_failures = [var.role]`.
- **`rejects_name_with_invalid_characters`** — e.g. `name = "bad name!"` →
  `expect_failures = [var.name]`.
- **`rejects_name_longer_than_128_characters`** → `expect_failures = [var.name]`.
- **`rejects_name_prefix_with_invalid_characters`** →
  `expect_failures = [var.name_prefix]`.
- **`rejects_name_prefix_longer_than_102_characters`** →
  `expect_failures = [var.name_prefix]`. Pins the provider's
  `128 - 26` prefix limit.
- **`rejects_path_without_leading_and_trailing_slash`** — e.g.
  `path = "service-role"` → `expect_failures = [var.path]`.
- **`rejects_path_longer_than_512_characters`** → `expect_failures = [var.path]`.
- **`rejects_both_name_and_name_prefix`** (P1) →
  `expect_failures = [aws_iam_instance_profile.this]`. Issue AC 8.
- **`rejects_neither_name_nor_name_prefix`** (P1) →
  `expect_failures = [aws_iam_instance_profile.this]`. Issue AC 8.

No wiring tests apply: the module calls no child modules (§ 4).

Per `AGENTS.md` § 6, if a case fails, fix the root cause in
`main.tf` / `variables.tf` / `outputs.tf` (or a demonstrably wrong expected value
in the test). Do not narrow an assertion, delete a `run` block, loosen an
`expect_failures` case, or mock away the behavior under test to force a pass.

## 9. Open questions
- **Expose `id`? (raised in triage)** This spec says **yes** —
  `modules/aws/iam/policy`, `modules/aws/iam/user`, and `modules/aws/iam/group`
  all expose `id`, so omitting it would be the inconsistent choice. The caveat
  is that AWS sets the instance profile's ID to its name, so `id` and `name` are
  always identical and `id` carries no information `name` does not. Reviewers
  should confirm they want the redundant-but-consistent output rather than
  `arn` / `name` / `unique_id` only.
- **`name` / `name_prefix` enforcement shape (raised in triage).** This spec
  enforces **exactly one** via precondition P1, matching the issue's input table
  ("one of `name` / `name_prefix`") and AC 8. Two consequences reviewers should
  weigh: (a) it is stricter than `modules/aws/iam/role`, which has the same two
  variables and enforces nothing, so "consistent with the role module" and
  "exactly one" cannot both be satisfied — this spec chooses the issue's
  explicit AC; (b) it removes the provider's "omit both and let Terraform assign
  a random unique name" behavior, a small `AGENTS.md` § 1 coverage trade made in
  favour of predictable naming. Relaxing P1 to "at most one" would restore it.
- **Should `modules/aws/iam/role` gain the same P1 precondition later?** Out of
  scope here (§ 2 forbids touching existing modules), but if reviewers want the
  stricter behavior to be the house rule, it should be filed as its own issue —
  it would be a **breaking** change for any caller currently omitting both.
- **`Name` tag merge.** This spec follows `AGENTS.md`'s "tags always merge a
  `Name` key" convention with a null guard for the `name_prefix` branch, which
  diverges from `modules/aws/iam/role` (`tags = var.tags`, no merge). The
  alternative is to match the sibling exactly and skip the merge. Reviewers
  should pick one; the tests in § 8 assert whichever is chosen and must be
  updated together with the decision.
- **Future map/`for_each` input (`AGENTS.md` § 5).** Deferred per the issue. A
  later `profiles = map(object({...}))` input would be additive only if the
  single-resource variables are retained, which is a design constraint worth
  recording now.

## 10. Acceptance criteria
- [ ] `modules/aws/iam/instance_profile/` exists with `main.tf`,
      `variables.tf`, `outputs.tf`, `README.md`, and `tests/`, following the
      repo's four-file layout and `###` section-header convention.
- [ ] With a valid `name` + `role` and defaults for `path` / `tags`, the module
      plans **exactly one** `aws_iam_instance_profile` and **zero** of
      `aws_ssm_document`, `aws_iam_role`, `aws_iam_policy`,
      `aws_iam_role_policy_attachment`, or any other resource type (issue AC 1,
      AC 9).
- [ ] `outputs.tf` exposes `arn`, `name`, and `unique_id` (the issue's required
      outputs) plus `id`, `create_date`, `path`, `role`, and `tags_all`; every
      one is asserted against a real expected value in `tests/`, and `arn`
      matches `arn:aws:iam::<account>:instance-profile/...` (issue AC 2).
- [ ] The profile's `role` attribute equals the `role` input (a role **name**),
      asserted on both the resource and `output.role` (issue AC 3).
- [ ] Custom `path` and `tags` land on the resource; `tags` defaults to
      `{ terraform = "true" }` and merges a `Name` key when `name` is set
      (issue AC 4).
- [ ] `name_prefix` with `name = null` plans a profile carrying that prefix and
      no `name` (issue AC 5).
- [ ] `role = ""` fails variable validation at plan time (issue AC 6).
- [ ] `role = "arn:aws:iam::123456789012:role/example"` fails variable
      validation at plan time with a message directing the caller to the role
      name; the module never parses an ARN into a name (issue AC 7).
- [ ] Setting both `name` and `name_prefix`, or neither, fails at plan time via
      precondition P1 (issue AC 8).
- [ ] Every argument of `aws_iam_instance_profile` — `name`, `name_prefix`,
      `path`, `role`, `tags` — is reachable from `variables.tf`, and no
      non-existent `region` variable is added (`AGENTS.md` § 1).
- [ ] `tests/` contains the valid-baseline case, one `expect_failures` case per
      `validation` rule, both precondition cases, one case per conditional
      branch (`name` vs `name_prefix`, default vs custom tags), and the output
      assertions in § 8; all pass offline via
      `tofu -chdir=modules/aws/iam/instance_profile init -backend=false && tofu -chdir=modules/aws/iam/instance_profile test`
      with no credentials or backend.
- [ ] No test is weakened, skipped, or mocked past the behavior under test to
      obtain a pass.
- [ ] `main.tf` declares `required_version = ">= 1.2.0"` and
      `aws version = ">= 6.0.0"`, each with a one-line comment giving the
      reason, per `AGENTS.md` § 7.
- [ ] `README.md` documents the module path, the required `role` **name**, a
      usage example attaching an existing role from `modules/aws/iam/role`, the
      explicit note that the module does **not** configure Session Manager, the
      design notes in § 4, and a committed, regenerated
      `<!-- BEGIN_TF_DOCS -->` block so `Verify - terraform-docs` passes
      (issue AC 10).
- [ ] No new Checkov/tfsec suppressions and no inline skip comments; no changes
      to `modules/aws/session_manager`, `modules/aws/iam/role`, `.checkov.yaml`,
      or any other existing file.
- [ ] `tofu fmt -check -diff -recursive` and
      `tofu -chdir=modules/aws/iam/instance_profile validate` pass.
