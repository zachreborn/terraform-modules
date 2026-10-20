# Spec: bug(aws/organizations): account tags with disallowed characters fail at apply, not plan
**Issue:** #496
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/organizations/account` accepts arbitrary tag maps with no
client-side character checking:

- `var.accounts` is `map(object({ ... tags = optional(map(string), {}) }))`
  (`modules/aws/organizations/account/variables.tf (38-47)`).
- `var.tags` is `map(any)` (`modules/aws/organizations/account/variables.tf (70-74)`).
- Both are merged straight onto the resource:
  `tags = merge(var.tags, each.value.tags)`
  (`modules/aws/organizations/account/main.tf:24`).

AWS Organizations' `CreateAccount` API only accepts tag keys and values made up
of letters, numbers, spaces representable in UTF-8, and the characters
`+ - = . _ : / @`. Anything else (parentheses, commas, ampersands, …) passes
`tofu validate` and `tofu plan` unchanged and then fails mid-apply with an
opaque error that names neither the offending account nor the offending tag:

```
Error: creating AWS Organizations Account (prod.website): operation error Organizations:
CreateAccount, https response error StatusCode: 400, InvalidInputException:
You provided a value that does not match the required pattern.
```

Because account creation is a slow, partially-applied operation, discovering
this at apply time is expensive: the run has already created sibling accounts,
and the only way to isolate the cause is to read the raw apply log and
cross-reference AWS's tag character rules by hand.

The composed `modules/aws/organizations` module re-declares the identical
`accounts` object shape (`modules/aws/organizations/variables.tf (97-107)`) and
passes it straight through to the `account` submodule
(`modules/aws/organizations/main.tf (109-115)`), so it has the same gap. Its
`var.tags` (`modules/aws/organizations/variables.tf (138-144)`) fans out to both
the `account` and `ou` submodules, and AWS applies the same character rules to
OU tags, so validating it there covers both call sites.

Note on relying on the submodule alone: a child module's variable validation
does fire through a wrapper, but it is not a checkable object the wrapper's own
`tofu test` cases can reference with `expect_failures`, and the reported error
points at the submodule's variable rather than the caller's input. This is the
same reasoning already recorded in
`modules/aws/organizations/tests/wiring.tftest.hcl (54-57)` for the `ou`
submodule. The wrapper therefore duplicates the validation rather than
inheriting it.

See: https://github.com/zachreborn/terraform-modules/issues/496

## 2. Non-goals
- **No tag length validation.** AWS caps tag keys at 128 characters and values
  at 256. That is a separate class of failure from the character-set bug in this
  issue and is deliberately excluded to keep the rejected surface exactly what
  the issue describes.
- **No `aws:` reserved-prefix validation.** AWS rejects caller-supplied keys
  beginning with `aws:`, but with a distinct error; not in scope here.
- **No validation of non-tag fields.** `name`, `email`, `role_name`,
  `iam_user_access_to_billing`, and `parent_id`/`parent_key` keep their current
  validation (or lack of it) untouched.
- **No changes to `modules/aws/organizations/ou`**, `organization`,
  `delegated_admin`, `delegated_resource_policy`, or `policy`. The `ou` module's
  own `organizational_units[key].tags` input is not validated by this spec; if
  desired it should be filed separately. (The composed module's shared
  `var.tags`, which reaches `ou`, *is* validated — see § 4.)
- **No repo-wide tag validation convention.** This spec does not introduce a
  shared tag-validation helper or apply the rule to other modules' `tags`
  variables.
- **No change to tagging behaviour.** The `merge(var.tags, each.value.tags)`
  precedence, defaults, and outputs stay exactly as they are.
- **No type change to `var.tags`.** It stays `map(any)` in the `account` module
  (see § 9).

## 3. Affected module path(s)
- `modules/aws/organizations/account/` (existing)
- `modules/aws/organizations/` (existing — composed module)

## 4. Proposed design
**Signatures only — no full implementations.**

### Shared regex
Both modules use the same anchored, Unicode-aware pattern, matching AWS's
documented tag character set (letters, numbers, Unicode separators/spaces, and
`+ - = . _ : / @`):

- Tag **values**: `^[\p{L}\p{N}\p{Z}+\-=._:/@]*$` — `*` because AWS permits an
  empty tag value.
- Tag **keys**: `^[\p{L}\p{N}\p{Z}+\-=._:/@]+$` — `+` because AWS requires a
  non-empty key.

Written in HCL the backslashes are escaped (e.g.
`"^[\\p{L}\\p{N}\\p{Z}+\\-=._:/@]*$"`). `regex()` is RE2-backed, so the `\p{…}`
Unicode classes are supported; anchoring is required so that substring matches
do not pass (same defect class as #396).

Design notes the implementation must honour:

- **Separate `validation` blocks for keys and values**, so the error message can
  say which one failed.
- **Each block references only the variable it validates.** Cross-variable
  references in `validation.condition` require Terraform >= 1.9; validating
  `var.tags` and `var.accounts[*].tags` independently (rather than validating
  their merged result) keeps the floor at 1.3 (§ 7 of `AGENTS.md`).
- **Error messages name the offending entries** by interpolating a `for`
  expression over the variable being validated — e.g. listing
  `<account_key>.<tag_key>` pairs that failed. This is the core ask of the issue
  and requires expression-valued `error_message` (Terraform >= 1.2.0).
- **Unknown values are deferred, not failed.** If a tag value is only known
  after apply, the condition evaluates to unknown and OpenTofu/Terraform defers
  the check rather than erroring; the module must not try to work around this
  (e.g. with `try()` coercion that would silently skip known-bad values).
- **`var.tags` is `map(any)`** in the `account` module, so its conditions wrap
  the element in `can(regex(pattern, tostring(v)))` so a non-string-convertible
  value fails the validation instead of raising a type error.

### `modules/aws/organizations/account`

#### `variables.tf`
No new variables, no type changes, no default changes. Two `validation` blocks
are added to each of two existing variables, and their `description` strings
gain a sentence documenting the allowed character set.

- **`accounts`** — `map(object({...}))`, required. Unchanged type and existing
  two validations (non-null entry; exactly one of `parent_id`/`parent_key`)
  stay. Adds:
  - `validation` — every `tags` **key** in every entry matches the key pattern;
    `error_message` lists the offending `<account_key>.<tag_key>` pairs and
    states the allowed character set.
  - `validation` — every `tags` **value** in every entry matches the value
    pattern; `error_message` lists the offending `<account_key>.<tag_key>` pairs
    (keys, not values, to avoid echoing long strings) and states the allowed
    character set.
- **`tags`** — `map(any)`, default `{}`. Adds:
  - `validation` — every key matches the key pattern; `error_message` lists the
    offending keys.
  - `validation` — every value matches the value pattern; `error_message` lists
    the offending keys.

#### `outputs.tf`
No changes. `ids`, `arns`, and `tags_all` keep their current shape and
descriptions.

#### `main.tf`
No resource changes. `aws_organizations_account.this` keeps its `for_each`,
its `merge(var.tags, each.value.tags)` tagging, its
`lifecycle { ignore_changes = [role_name] }`, and its existing `parent_key`
precondition. The only edit is to the `terraform {}` block:

- `required_version` `">= 1.0.0"` → `">= 1.3.0"`, with a one-line comment giving
  the reason (see § 7 of `AGENTS.md`): expression-valued `error_message`
  requires >= 1.2.0, and the module's already-present `optional(<type>, <default>)`
  object attributes require >= 1.3.0. The `aws` provider constraint
  (`>= 6.0.0`) is unchanged — no provider feature is involved.

### `modules/aws/organizations` (composed)

#### `variables.tf`
- **`accounts`** — same duplicated key/value `validation` blocks as the
  submodule, so the failure is reported against the caller-facing variable and
  is referenceable from this module's own tests. Description gains the same
  allowed-character-set sentence.
- **`tags`** — `map(string)`, default `{ terraform = "true" }`. Same two
  `validation` blocks (keys and values). This input fans out to both the
  `account` and `ou` submodules, and AWS applies the same character rules to OU
  tags, so one pair of blocks covers both.

#### `outputs.tf`
No changes.

#### `main.tf`
No module-wiring changes: `module "accounts"`, `module "organizational_units"`,
`module "organization"`, `module "delegated_admins"`, and the
`organizational_units_normalized` / `organizational_units_resolved` locals are
untouched. Only `required_version` is bumped to `">= 1.3.0"` with the same
explanatory comment and for the same two reasons.

#### `README.md` (both modules)
Each README gains a short note — in the existing prose sections, above the
`<!-- BEGIN_TF_DOCS -->` block — stating the allowed tag character set
(letters, numbers, spaces, and `+ - = . _ : / @`), that keys must be non-empty
and values may be empty, and that violations now fail at plan time rather than
at apply. This satisfies the issue's fourth acceptance criterion.

## 5. Breaking-change assessment
- Breaking: **no**.
- The validations only reject values that AWS itself already rejects: any
  configuration containing a disallowed character could never have applied
  successfully, so no working caller configuration changes behaviour. The effect
  is moving an existing failure earlier, from apply to plan/validate, with a
  message that names the offending account key and tag key. Classified as
  `fix:` (PATCH) under the repo's release-please conventions.
- One caller-visible consequence worth calling out in review: a caller who today
  has a broken tag value and never runs `apply` (e.g. a plan-only CI job) will
  now see that job fail. That is the intended correction.
- The `required_version` bump from `>= 1.0.0` to `>= 1.3.0` is a documentation
  correction, not a new restriction: both modules already use
  `optional(<type>, <default>)` object attributes, which never worked on
  Terraform 1.0–1.2, and every OpenTofu release (1.6+) already satisfies
  `>= 1.3.0`. Only a caller on Terraform 1.0/1.1 — where these modules are
  already non-functional — is affected.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. Adding variable validation introduces no new
  resource configuration and no security-relevant surface.
- Existing suppressions affected: **none**. Neither module carries an inline
  `#tfsec:ignore:` or `#checkov:skip=` comment, and no entry in the repo-root
  `.checkov.yaml` relates to AWS Organizations tagging.

## 7. terraform-docs impact
**Yes**, for both modules. The generated inputs table renders each variable's
`description`, and this spec changes the descriptions of:

- `modules/aws/organizations/account/README.md` — `accounts`, `tags`
- `modules/aws/organizations/README.md` — `accounts`, `tags`

The `Requirements` section of both READMEs also renders `required_version`, so
the `>= 1.0.0` → `>= 1.3.0` bump changes that row too. `validation {}` block
contents themselves are not rendered.

The implementation must regenerate both READMEs (`pre-commit run --all-files`,
or per module
`terraform-docs markdown table --output-file README.md --output-mode inject <module_path>`)
and commit the result; the `Verify - terraform-docs` CI job fails on any diff
and does not auto-commit.

## 8. Testing
Standard local checks:

- `tofu -chdir=modules/aws/organizations/account init -backend=false && tofu -chdir=modules/aws/organizations/account validate`
- `tofu -chdir=modules/aws/organizations init -backend=false && tofu -chdir=modules/aws/organizations validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/organizations` (locally; CI runs on schedule)

Native `tofu test` plan (required — `AGENTS.md` § Module Design Specifications
§ 6). All cases follow the existing `mock_provider "aws" {}` / `run` /
`expect_failures` conventions in
`modules/aws/organizations/account/tests/validation.tftest.hcl` and
`modules/aws/organizations/tests/wiring.tftest.hcl`, and must run fully offline.

### `modules/aws/organizations/account/tests/validation.tftest.hcl` (extend)
Every entry below needs the minimum valid inputs to reach validation
(`email` plus exactly one of `parent_id`/`parent_key`).

Valid-baseline and allowed-input cases (`command = plan`):

- **`valid_baseline_does_not_fail`** — existing case, unchanged; must still
  pass, proving the new blocks do not reject a tagless baseline (the
  `tags = optional(map(string), {})` empty-default branch).
- **`accepts_full_allowed_tag_character_set`** — one entry whose `tags`, and a
  module-level `var.tags`, together exercise every allowed class: upper/lower
  letters, digits, a space, Unicode letters (e.g. `"Café"`), and each of
  `+ - = . _ : / @` in both a key and a value. Assert the merged result lands on
  the resource, e.g.
  `aws_organizations_account.this["company_ventures"].tags["purpose"]` equals the
  supplied value. This is the case that proves the regex is not over-strict.
- **`accepts_empty_tag_value`** — an entry tag with value `""`; assert the plan
  succeeds and the empty value is preserved on the resource. Covers the `*` vs
  `+` distinction between the value and key patterns.
- **`tags_merge_module_and_entry_tags`** — existing case, unchanged; must still
  pass (per-entry tag overriding a module-level tag of the same key).

Failure cases, one per new `validation` block, each with `command = plan`:

- **`rejects_entry_tag_value_with_disallowed_character`** — the exact repro from
  the issue: `tags = { purpose = "Public-facing personal static websites (S3 + CloudFront)." }`;
  `expect_failures = [var.accounts]`.
- **`rejects_entry_tag_value_with_comma`** — a second disallowed character
  (`,`), confirming the rejection is not parenthesis-specific;
  `expect_failures = [var.accounts]`.
- **`rejects_entry_tag_key_with_disallowed_character`** — e.g. key
  `"purpose(1)"`; `expect_failures = [var.accounts]`.
- **`rejects_entry_tag_key_that_is_empty`** — key `""`;
  `expect_failures = [var.accounts]`.
- **`rejects_module_tag_value_with_disallowed_character`** — same bad value on
  `var.tags`; `expect_failures = [var.tags]`.
- **`rejects_module_tag_key_with_disallowed_character`** — same bad key on
  `var.tags`; `expect_failures = [var.tags]`.

The pre-existing `expect_failures = [var.accounts]` cases
(`rejects_entry_with_both_parent_id_and_parent_key`,
`rejects_entry_with_neither_parent_id_nor_parent_key`, `rejects_null_entry`) and
the resource-precondition case in `accounts.tftest.hcl`
(`invalid_parent_key_fails_precondition_not_invalid_index`) must keep passing
unchanged; each new failure case must supply otherwise-valid input so it fails
only because of the tag character rule. Output assertions in
`outputs_expose_keyed_maps` (`ids`, `arns`, `tags_all`) are unchanged and must
still pass.

### `modules/aws/organizations/tests/` (composed module)
Add the wrapper-level cases (a new `tag_validation.tftest.hcl`, or appended to
`wiring.tftest.hcl`, reusing that file's `mock_resource` defaults):

- **`rejects_account_entry_tag_value_with_disallowed_character`** —
  `expect_failures = [var.accounts]` **on this module's own variable**. This is
  precisely what proves the wrapper duplicates the rule rather than relying on
  the submodule, whose validation is not a checkable object here.
- **`rejects_account_entry_tag_key_with_disallowed_character`** —
  `expect_failures = [var.accounts]`.
- **`rejects_wrapper_tag_value_with_disallowed_character`** —
  `expect_failures = [var.tags]`.
- **`rejects_wrapper_tag_key_with_disallowed_character`** —
  `expect_failures = [var.tags]`.
- **`valid_tags_plan_successfully_through_the_wrapper`** — wiring case: valid
  `var.tags` plus valid per-entry `accounts[key].tags` with an OU attached by
  `parent_key`; assert `output.account_ids[<key>] != null` and
  `output.organizational_unit_ids[<key>] != null`, proving the shared `var.tags`
  still reaches both the `account` and `ou` submodules with the validations in
  place.

Implementer guidance: assert exact tag *values* only in the `account`
submodule's tests, where `aws_organizations_account.this[...].tags` is directly
addressable. Do **not** assert exact values against the wrapper's
`output.account_tags_all` — `tags_all` is a computed attribute and is
mock-generated under `mock_provider`, so such an assertion would test the mock,
not the wiring.

Every `expect_failures` case must fail *because* the new tag validation rejects
the input. If a case does not fail, fix the regex or the condition in
`variables.tf` — do not loosen the assertion, delete the case, or mock the
validation away. Both suites must pass offline via
`tofu -chdir=<module_path> init -backend=false && tofu -chdir=<module_path> test`.

## 9. Open questions
- Should `modules/aws/organizations/account`'s `var.tags` be tightened from
  `map(any)` to `map(string)`, matching the composed module and every other tag
  input in the library? It would make the validation naturally typed (no
  `tostring()` wrapper) and auto-converts primitive values, but it would newly
  reject a map whose values are lists/objects — which the AWS provider rejects
  anyway. This spec keeps `map(any)` to hold the change to zero type risk;
  reviewers may prefer to fold the tightening in here rather than defer it.
- Should the error messages enumerate *all* offending `<account_key>.<tag_key>`
  pairs, or cap the list (e.g. first five) to keep the message readable for a
  large YAML-sourced organization? This spec assumes enumerate-all.
- Should the identical validation be extended to
  `modules/aws/organizations/ou`'s `organizational_units[key].tags` in a
  follow-up issue? Listed as a non-goal here; the composed module's shared
  `var.tags` is already covered.

## 10. Acceptance criteria
- [ ] `modules/aws/organizations/account`'s `accounts` variable rejects, at
      `tofu plan`/`validate` time, any `tags` key or value containing a
      character outside AWS's allowed set (letters, numbers, spaces, and
      `+ - = . _ : / @`), with an error message that names the offending account
      key.
- [ ] The same module's `tags` variable carries the equivalent key and value
      validations.
- [ ] The composed `modules/aws/organizations` module's `accounts` variable
      carries the same validations, so the failure is reported against the
      caller-facing input, and its `tags` variable is validated as well.
- [ ] The exact reproduction from the issue —
      `tags = { purpose = "Public-facing personal static websites (S3 + CloudFront)." }`
      — fails at plan time in both modules.
- [ ] Valid tag values, including the full allowed punctuation set, Unicode
      letters, spaces, and an empty value, continue to plan successfully, and
      `merge(var.tags, each.value.tags)` precedence is unchanged.
- [ ] `modules/aws/organizations/account/tests/` gains the regression and
      allowed-input cases in § 8, and the composed module's `tests/` gains the
      wrapper-level cases; `tofu test` passes offline for both modules and all
      pre-existing cases still pass.
- [ ] Both READMEs document the allowed tag-value/key character set outside the
      generated block, and both regenerated `<!-- BEGIN_TF_DOCS -->` blocks are
      committed so `Verify - terraform-docs` passes.
- [ ] `required_version` in both modules is `">= 1.3.0"` with a comment stating
      the reason; the `aws` provider constraint is unchanged.
- [ ] No new Checkov/tfsec suppressions; no changes to resources, outputs,
      tagging behaviour, or any other module.
- [ ] `tofu fmt -check -diff -recursive` and `tofu validate` pass for both
      modules.
