---
name: spec-implementation
description: >-
  Implement an approved spec in the zachreborn/terraform-modules
  Terraform/OpenTofu module library, treating the committed spec file as the
  source of truth, then open an implementation PR that fills the repo PR
  template and links the originating issue. Use this skill whenever you are
  asked to implement, build, or code an approved spec for this repo, or when an
  issue reaches the spec-approved stage of the pipeline. This skill is the
  canonical source for the implementation agent; the Implementation GitHub
  Actions workflow invokes it with per-run context.
---

# Spec implementation

You implement an approved spec in `zachreborn/terraform-modules`, a
Terraform/OpenTofu module library (OpenTofu is the default; Terraform is also
supported). The spec was reviewed and merged precisely so that implementation
stays within agreed bounds — treat it as the source of truth and do not expand
scope beyond it.

## Run context

The invoking prompt provides:

- **Issue number** — the originating issue.
- **Repository** — the target repo (e.g. `zachreborn/terraform-modules`).
- **Spec file path** — the approved spec already on `main`
  (e.g. `.github/specs/issue-<issue_number>-<slug>.md`).

Read the spec file in full before making any changes.

## Required reading

- `AGENTS.md` — repo conventions: four-file module layout,
  `opentofu >= 1.6.0` / `terraform >= 1.0.0`, `aws >= 6.0.0`, section header
  style, `tags = merge(tomap({ Name = var.name }), var.tags)` pattern,
  `count = var.enable_x ? 1 : 0` conditional pattern, lifecycle ignores,
  tfsec suppression style, and the Native Test Coverage requirement (§ 6 of
  Module Design Specifications).
- `modules/module_template/` — the starting point for new modules, including
  its `tests/` scaffolding.
- `modules/aws/organizations/tests/` — a worked example of the `mock_provider`
  / `run` / `expect_failures` test conventions.
- `.github/pull_request_template.md` — the required PR body shape.

## Implementation rules

- Stay within the scope defined by the spec. Do not modify unrelated modules.
- Run `tofu fmt -recursive` before committing.
- If you change module inputs/outputs or the README `terraform-docs` markers,
  regenerate the docs locally (e.g. `pre-commit run --all-files`) and commit the
  result. CI (`build.yml`) only verifies the committed docs and fails the
  `Verify - terraform-docs` job if they are stale — it does not auto-commit
  fixes back to the PR.
- Run `tofu -chdir=<module_path> init -backend=false` and
  `tofu -chdir=<module_path> validate` for any module you create or modify, and
  ensure both succeed.
- If you add a Checkov suppression, document the rationale in a comment per the
  convention in `AGENTS.md`.

## Testing requirements

Every module you create or significantly modify must ship (or extend) a
`tests/` directory of native OpenTofu tests implementing the spec's § 8
Testing plan in full. At minimum, cover:

- A valid-baseline `run` block proving a normal plan succeeds.
- One `expect_failures` case per variable `validation { ... }` rule.
- One case per conditional/`count`/`for_each` branch (each side of the toggle).
- Assertions on every meaningful output.
- Wiring assertions between this module and any submodules it calls, for
  wrapper/composition modules.

Use `mock_provider` / `mock_resource` blocks so tests run offline, with no real
cloud credentials or backend. Run `tofu -chdir=<module_path> init -backend=false`
followed by `tofu -chdir=<module_path> test` and confirm every case passes
before opening the PR.

**Never weaken a test to make it pass.** Do not narrow an `assert` condition,
delete or skip a `run` block, loosen an `expect_failures` case, or mock away
the exact behavior under test merely to turn a failing test green. A failing
test is a signal that something is wrong with the module code you just wrote —
find and fix the root cause there. Only change the test itself if its logic is
demonstrably incorrect, and even then, make it more correct, not weaker.
Re-run `tofu test` until every case passes for the right reason.

## Commit and PR

- Branch name: `feat/issue-<issue_number>-<slug>` for features, or
  `fix/issue-<issue_number>-<slug>` for bugs.
- Commit messages follow conventional-commit style and include a
  `Co-Authored-By` line for Oz.
- Open the PR as **ready-for-review** (NOT a draft) so that CODEOWNERS are
  auto-assigned via the `pull_request: ready_for_review` event. If your tooling
  defaults to draft, flip it to ready before exiting (the workflow also runs a
  `gh pr ready` safety net).
- Title: per the spec. The PR body MUST fill in the existing
  `.github/pull_request_template.md` sections: Description, Issue or Ticket
  (with `Fixes #<issue_number>`), Type of change, Breaking Changes, and TODOs.
- Post a comment on the originating issue with the PR URL.

Before marking the PR ready, walk the implementation rules above, the Testing
requirements, and every required PR-template section one item at a time and
confirm each is satisfied. Do not stop at the first gap or leave a template
section blank, and do not let a weakened test count as satisfying the Testing
requirements. An incomplete change fails CI or review and forces another
round, so complete every item now.

## CI expectations

Implementation PRs go through the same CI as any other PR (`build.yml`,
`test.yml`, `scan.yml`). Do not attempt to bypass any check.
