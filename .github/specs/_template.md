# Spec: <title>
**Issue:** #<N>
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** <Feature | Bug fix | CI/automation | Other>

## 1. Background
What is the current state and why do we need to change it? Link to the
originating issue and any prior discussion.

## 2. Non-goals
Explicit list of things this spec deliberately does NOT cover.

## 3. Affected module path(s)
- `modules/<provider>/<name>/` (existing) or
- `modules/<provider>/<name>/` (new)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
List the variables (name, type, description, default if any).

### `outputs.tf`
List the outputs and what they expose.

### `main.tf`
List the resource block types and their high-level relationships. Note any
`count`/`for_each` patterns, lifecycle ignores, and tagging.

## 5. Breaking-change assessment
- Breaking: yes / no
- If yes, describe what callers must do to migrate.

## 6. Checkov / tfsec considerations
- New suppressions: none, or list each with rationale.
- Existing suppressions affected: none, or list.

## 7. terraform-docs impact
Will the auto-generated `<!-- BEGIN_TF_DOCS -->` block change for any
module? If yes, which.

## 8. Testing
- `tofu -chdir=<path> init -backend=false && tofu -chdir=<path> validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d <path>` (locally; CI runs on schedule)
- Native `tofu test` plan (required — see `AGENTS.md` § Module Design
  Specifications § 6, Native Test Coverage). List the `tests/*.tftest.hcl`
  cases the implementation must add:
  - Valid-baseline `run` block (proves a normal plan succeeds).
  - One `expect_failures` case per variable `validation { ... }` rule.
  - One case per conditional/`count`/`for_each` branch.
  - Assertions on every meaningful output.
  - Wiring assertions between this module and any submodules it calls, if applicable.
  Do not propose weakened assertions, mocked-away behavior, or skipped cases as
  a way to make tests pass — every case must exercise real module behavior.

## 9. Open questions
Bullet list. Each one should be resolvable before merge.

## 10. Acceptance criteria
Mirror the issue's "Confirmation" / acceptance section. The implementation
PR must satisfy every item here.
