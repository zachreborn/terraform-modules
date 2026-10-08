# Spec: feat(amplify): allow branches without a custom domain (skip aws_amplify_domain_association)
**Issue:** #516
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature
## 1. Background
`modules/aws/amplify` couples every Amplify branch to a custom domain. Two
things force that coupling on `main` (`v17.0.0`):
- `variables.tf:172` declares `domain_name = string` inside the `branches`
  object type — it is the only non-`optional` attribute, so every branch entry
  must supply one.
- `main.tf:174-206` creates `aws_amplify_domain_association.this` with
  `for_each = var.branches != null ? var.branches : {}`, so one domain
  association (and, by default, an `AMPLIFY_MANAGED` certificate) is created per
  branch with no way to opt out.
A caller therefore cannot deploy a branch that is served only from the built-in
Amplify URL (`https://<branch>.<app_id>.amplifyapp.com`), which is the normal
shape for proof-of-concept, preview, and short-lived test sites. The current
workarounds are all poor: `branches = {}` plans cleanly but creates no
`aws_amplify_branch` at all (the behavior added by #406), any branch entry drags
in a domain association, and declaring `aws_amplify_branch` outside the module
bypasses the module's branch handling entirely.
A second gap compounds this: the module exposes `default_domain` (the app-level
`<app_id>.amplifyapp.com`) but no per-branch URL, so a caller who only wants the
default Amplify URL has to rebuild it by hand, including Amplify's
`/` → `-` branch-name substitution.
Triage classified this as a feature with low breaking-change risk. Related
closed issues #406 (`branches = null` plan crash) and #286
(`basic_auth_credentials` perpetual diff) touch the same module but are distinct
requests.
## 2. Non-goals
- No change to the Amplify app-level schema (`aws_amplify_app`), its `dynamic`
  blocks, or any existing variable other than the `branches` object type.
- Repository access and token handling (`access_token` / `oauth_token`) is out
  of scope. A caller can authorize the Amplify GitHub App in the AWS console
  after the app is created.
- Notification / SNS / EventBridge wiring is untouched.
- Not fixing the latent defect in the nested `dynamic "sub_domain"` base block
  (`main.tf:191-197`), which iterates `var.branches` instead of emitting a
  single entry for the current branch. That is the pre-existing concern already
  noted in the #406 spec and is tracked separately; see § 9 for the one narrow,
  behavior-preserving touch this spec asks reviewers to rule on.
- No automatic domain inference (e.g. deriving `domain_name` from the app name),
  and no support for a single shared domain association spanning several
  branches — each branch keeps at most one association keyed by branch name.
- No change to how `sub_domains` prefixes are rendered for branches that *do*
  set `domain_name`.
## 3. Affected module path(s)
- `modules/aws/amplify/` (existing) — `variables.tf`, `main.tf`, `outputs.tf`
- `modules/aws/amplify/tests/` (existing) — new `run` blocks in
  `main.tftest.hcl` and `validation.tftest.hcl`
- `modules/aws/amplify/README.md` — new usage example plus a regenerated
  `terraform-docs` block
## 4. Proposed design
**Signatures only — no full implementations.**
Make the domain association opt-in per branch by making `domain_name` optional,
filtering the association's `for_each` to the branches that set it, and guarding
domain-only settings with validation so they cannot be silently ignored.
### `variables.tf`
No new top-level variables. One existing variable is modified:
- `variable "branches"` — `type = map(object({...}))`, `default = {}`,
  `nullable = false` (all unchanged). The single schema change is:
  - `domain_name` — from `string` (required) to `optional(string)` (implicit
    default `null`). Update the inline comment to read, in substance: "The
    domain name for the domain association. When null, no
    `aws_amplify_domain_association` is created and the branch is served only
    from the app's default `amplifyapp.com` domain."
  - Every other attribute (`basic_auth_credentials`, `certificate_type`,
    `custom_certificate_arn`, `description`, `display_name`,
    `enable_auto_build`, `enable_auto_sub_domain`, `enable_basic_auth`,
    `enable_certificate`, `enable_notification`, `enable_performance_mode`,
    `enable_pull_request_preview`, `environment_variables`, `framework`,
    `pull_request_environment_name`, `stage`, `sub_domains`, `ttl`,
    `wait_for_verification`) keeps its current type and default.
  - Update the variable `description` to state that `domain_name` is optional
    and that omitting it skips the domain association for that branch.
  - Extend the commented example block with a domain-less branch entry.
- Two new `validation { ... }` blocks on `var.branches`. They are declared
  separately (rather than combined with `&&`) so each failure reports a
  specific, actionable `error_message` and each is independently testable:
  1. **`sub_domains` requires `domain_name`** — condition: no entry has a
     non-empty `sub_domains` set while `domain_name == null`. Error message
     names the offending behavior: sub-domain prefixes only exist within a
     custom domain association.
  2. **`custom_certificate_arn` requires `domain_name`** — condition: no entry
     sets `custom_certificate_arn` while `domain_name == null`. Error message
     states that a certificate is only attached through a domain association.
  Attributes with non-null defaults (`certificate_type = "AMPLIFY_MANAGED"`,
  `enable_certificate = true`, `enable_auto_sub_domain = false`,
  `wait_for_verification = true`) are deliberately **not** validated: a caller
  cannot distinguish "set" from "defaulted" for them, so validating them would
  reject the ordinary domain-less branch shown in the issue's example. They are
  simply unused when `domain_name` is `null`; the README must say so.
### `outputs.tf`
Existing outputs (`app_id`, `app_arn`, `default_domain`, `sns_topic_arn`,
`notification_event_rule_arn`) are unchanged. One additive output:
- `output "branch_urls"` — `map(string)` keyed by branch name, each value the
  branch's default Amplify URL,
  `https://<sanitized-branch-name>.<default_domain>`, where
  `<sanitized-branch-name>` is the branch name with `/` replaced by `-`
  (matching how Amplify builds the default branch URL) and `<default_domain>`
  is `aws_amplify_app.this.default_domain`. The comprehension iterates
  `aws_amplify_branch.this` so the output is `{}` when no branches are declared
  and carries a real dependency on the branch resources. Description must note
  that this is always the default `amplifyapp.com` URL and is populated for
  every branch, including branches that also have a custom domain.
### `main.tf`
- **New local** — `local.branch_domain_associations` (name is a suggestion): the
  subset of `var.branches` whose `domain_name != null`, expressed as a `for`
  comprehension with an `if` guard. Keys stay the branch names so no existing
  resource address moves.
- `resource "aws_amplify_domain_association" "this"` — change `for_each` from
  `var.branches != null ? var.branches : {}` to the new local. All attribute
  wiring (`app_id`, `domain_name`, `enable_auto_sub_domain`,
  `wait_for_verification`), the `dynamic "certificate_settings"` block, and the
  `dynamic "sub_domain"` prefix block are otherwise unchanged. Replace the
  existing `for_each` comment with one explaining that the association is now
  opt-in per branch.
- `resource "aws_amplify_branch" "this"` — unchanged; it keeps iterating all of
  `var.branches`, so branch creation is fully decoupled from domain ownership.
- `resource "aws_amplify_app" "this"` — unchanged.
- The nested base `dynamic "sub_domain"` block (`main.tf:191-197`) should be
  repointed from `for_each = var.branches` to the same filtered local, purely so
  both expressions inside the association agree on which branches are in play.
  This is behavior-preserving (`sub_domain` is a set block and the block body
  already emits the current `each.key`, so the extra iterations collapse to one
  entry). See § 9 — reviewers should confirm or defer this.
- No change to tagging (`tags = var.tags` on both resources), lifecycle
  `ignore_changes`, the `aws_amplify_app` preconditions, or either submodule
  (`../sns`, `../cloudwatch/event`).
## 5. Breaking-change assessment
- Breaking: **no**.
- `domain_name` moves from required to optional within the `branches` object.
  Relaxing a required object attribute to `optional()` is backward compatible:
  every existing caller already supplies it.
- Existing callers that set `domain_name` on every branch produce an identical
  plan. `local.branch_domain_associations` equals `var.branches` in that case,
  the `for_each` keys are still the branch names, and no resource address moves
  — so there are no replacements, no `moved` blocks, and no state surgery.
- The two new validations only reject configurations that were previously
  unwritable (a branch with no `domain_name` but with `sub_domains` or
  `custom_certificate_arn`), so they cannot fail an existing config.
- `branch_urls` is additive.
- Conventional Commit type `feat(amplify):` → MINOR release.
## 6. Checkov / tfsec considerations
- New suppressions: **none**. Nothing in this change creates a public endpoint,
  relaxes encryption, or widens a policy; it only skips creating a resource.
- Existing suppressions affected: **none**. The repo-level `.checkov.yaml`
  suppressions are untouched, and no inline `#tfsec:ignore:` comment is added or
  removed.
- Note for reviewers: a domain-less branch is still served over HTTPS from the
  Amplify-managed `amplifyapp.com` certificate, so skipping the domain
  association does not downgrade transport security.
## 7. terraform-docs impact
Yes — `modules/aws/amplify/README.md`'s `<!-- BEGIN_TF_DOCS -->` block changes
in two places:
- The `branches` input row: its rendered object type gains
  `optional(string)` for `domain_name`, and the description text changes.
- The outputs table gains a `branch_urls` row.
The hand-written Usage section above the generated block also gains a "default
Amplify domain only" example (a `branches` entry with no `domain_name` plus an
`output` reading `module.<name>.branch_urls["main"]`), and a note that
`certificate_type`, `enable_certificate`, `enable_auto_sub_domain`, and
`wait_for_verification` are ignored for a branch with no `domain_name`.
The implementation PR must regenerate docs locally
(`pre-commit run --all-files`, or
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/amplify`)
and commit the result so the `Verify - terraform-docs` job passes — CI verifies
but never auto-commits.
## 8. Testing
- `tofu -chdir=modules/aws/amplify init -backend=false && tofu -chdir=modules/aws/amplify validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/amplify` (locally; CI runs on schedule)
- Native `tofu test` plan (required — `AGENTS.md` § Module Design Specifications
  § 6). The module already has `tests/main.tftest.hcl`,
  `tests/validation.tftest.hcl`, and `tests/wiring.tftest.hcl`. **Every existing
  `run` block must keep passing unmodified** — that is itself the
  no-regression proof for current callers. New cases reuse the established
  `mock_provider "aws"` setup (with `mock_data` for `aws_caller_identity` /
  `aws_region` and `mock_resource "aws_amplify_app"` returning
  `id = "d1234567890abc"` and
  `default_domain = "d1234567890abc.amplifyapp.com"`), and all run offline with
  `command = plan`.
  Cases the implementation must add:
  - **Valid baseline (existing, unchanged)** —
    `run "valid_baseline_plans_successfully"` and
    `run "single_branch_creates_branch_and_domain_association"` in
    `main.tftest.hcl` continue to prove that the normal, domain-bearing shape
    plans with one branch and one association keyed `"main"`.
  - **`expect_failures` — one per new `validation { ... }` rule**, both in
    `validation.tftest.hcl`, both asserting `expect_failures = [var.branches]`:
    - `run "rejects_sub_domains_without_domain_name"` — a single branch with
      `sub_domains = ["www"]` and no `domain_name`.
    - `run "rejects_custom_certificate_arn_without_domain_name"` — a single
      branch with `custom_certificate_arn` set to a plausible ACM ARN and no
      `domain_name`.
    Add a companion positive case,
    `run "branch_without_domain_name_passes_validation"`, with a domain-less
    branch that sets only non-domain attributes (`framework`, `stage`), proving
    the new rules do not over-reject the shape the issue asks for.
  - **One case per conditional / `for_each` branch** of the new filter, in
    `main.tftest.hcl`:
    - `run "branch_without_domain_creates_no_domain_association"` — one branch,
      no `domain_name`. Asserts `length(aws_amplify_branch.this) == 1`,
      `aws_amplify_branch.this["main"].branch_name == "main"`, and
      `length(aws_amplify_domain_association.this) == 0`. This is the core new
      behavior and must fail before the change and pass after it.
    - `run "mixed_branches_create_associations_only_where_domain_set"` — a
      `branches` map with `main` (has `domain_name = "example.org"`) and `poc`
      (no `domain_name`). Asserts `length(aws_amplify_branch.this) == 2`,
      `length(aws_amplify_domain_association.this) == 1`,
      `contains(keys(aws_amplify_domain_association.this), "main")`,
      `!contains(keys(aws_amplify_domain_association.this), "poc")`, and
      `aws_amplify_domain_association.this["main"].domain_name == "example.org"`
      — proving both the filtering and that association keys are still branch
      names.
    - The existing all-domains cases
      (`single_branch_creates_branch_and_domain_association`,
      `disabling_certificate_removes_certificate_settings_block`,
      `sub_domains_toggle_adds_extra_sub_domain_entry`) already cover the
      "`domain_name` set" side of the filter and the
      `enable_certificate` / `sub_domains` dynamic toggles; they must not be
      edited.
  - **Assertions on every meaningful output** — existing cases already assert
    `app_id`, `app_arn`, `default_domain`, `sns_topic_arn`, and
    `notification_event_rule_arn`. For the new output, add
    `run "branch_urls_output_is_built_from_default_domain"` with branches `main`
    and `feature/login` (neither with a `domain_name`), asserting:
    - `output.branch_urls["main"] == "https://main.d1234567890abc.amplifyapp.com"`
    - `output.branch_urls["feature/login"] == "https://feature-login.d1234567890abc.amplifyapp.com"`
      (the `/` → `-` substitution, exercised against the real mocked
      `default_domain`)
    - `length(output.branch_urls) == 2`
    Also extend the zero-branch cases so `length(output.branch_urls) == 0` when
    `branches` is `{}` / `null` / omitted, and add an assertion in the mixed
    case that a branch *with* a custom domain still gets a `branch_urls` entry.
  - **Wiring assertions** — `tests/wiring.tftest.hcl` covers the `../sns` and
    `../cloudwatch/event` submodule wiring, which this change does not touch; it
    must pass unmodified. No new submodule wiring is introduced, so no new
    wiring case is required. The parent→child value flow that *is* new (the
    `var.branches` → `local.branch_domain_associations` →
    `aws_amplify_domain_association.this` key filter) is asserted by the
    mixed-branches case above.
  Do not weaken an assertion, delete or skip a `run` block, loosen an
  `expect_failures` case, or mock away the behavior under test to force a pass.
  A failure means the module code (or a demonstrably wrong test expectation) is
  at fault — fix the root cause and re-run `tofu test` until every case passes
  for the right reason.
## 9. Open questions
- **Nested base `dynamic "sub_domain"` (`main.tf:191-197`)** — it iterates
  `for_each = var.branches` while emitting the current association's `each.key`.
  This spec proposes repointing it to `local.branch_domain_associations` so both
  `for_each` expressions in the resource agree, which is behavior-preserving
  because `sub_domain` is a set block and the duplicate entries collapse.
  Reviewers should confirm that narrow touch, or ask for it to be deferred
  wholesale to the separate issue that owns the block's real defect (it should
  emit exactly one base entry rather than iterating a map at all).
- **Branch-name sanitization scope** — `branch_urls` implements only the
  `/` → `-` substitution called out in the issue. Amplify also lowercases and
  substitutes some other characters when building the default URL. Confirm that
  the narrow substitution is acceptable for now, with broader sanitization left
  to a follow-up if a caller hits it.
- **Validation strictness** — the spec guards only `sub_domains` and
  `custom_certificate_arn`, the two attributes with no non-null default, and
  deliberately lets the defaulted domain-only attributes pass through unused.
  Confirm that silently ignoring `certificate_type`, `enable_certificate`,
  `enable_auto_sub_domain`, and `wait_for_verification` on a domain-less branch
  (documented in the README) is preferable to rejecting them.
## 10. Acceptance criteria
- [ ] A branch with no `domain_name` plans and applies with one
  `aws_amplify_branch` and zero `aws_amplify_domain_association` instances.
- [ ] With a mixed `branches` map, domain associations exist only for branches
  that set `domain_name`, keyed by branch name.
- [ ] Existing callers are unaffected: the existing `tests/*.tftest.hcl` cases
  pass unmodified, and a caller that sets `domain_name` on every branch shows no
  plan diff (no replacements, no moved addresses).
- [ ] `output.branch_urls` is asserted for a plain branch name and for a branch
  name containing `/`, and is empty when no branches are declared.
- [ ] The new `branches` validations are each covered by an
  `expect_failures = [var.branches]` case in `tests/validation.tftest.hcl`,
  alongside a positive case proving a domain-less branch is accepted.
- [ ] New tests use `mock_provider`, run offline with `command = plan`, and no
  existing assertion is weakened.
- [ ] `modules/aws/amplify/README.md` gains a "default Amplify domain only"
  usage example, documents which domain-only attributes are ignored when
  `domain_name` is null, and the `terraform-docs` block is regenerated and
  committed.
- [ ] `tofu fmt -check -diff -recursive`,
  `tofu -chdir=modules/aws/amplify init -backend=false`, `validate`, `test`, and
  `checkov -d modules/aws/amplify` pass, and all required CI checks are green.
