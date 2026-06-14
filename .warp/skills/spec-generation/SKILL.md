---
name: spec-generation
description: >-
  Generate a technical specification for a triaged GitHub issue in the
  zachreborn/terraform-modules Terraform/OpenTofu module library, following the
  repository's spec template and conventions, then open a spec PR and advance
  the issue to spec-ready-for-review. Use this skill whenever you are asked to
  write, author, or generate a spec for an issue in this repo, or when an issue
  reaches the ready-for-spec stage of the pipeline. This skill is the canonical
  source for the spec-generation agent; the Spec Generation GitHub Actions
  workflow invokes it with per-run context.
---

# Spec generation

You generate a technical specification for one issue in
`zachreborn/terraform-modules`, a Terraform/OpenTofu module library (OpenTofu is
the default; Terraform is also supported). The spec becomes the source of truth
for the later implementation stage, so it must be precise about interfaces and
deliberately silent about full implementation — signatures, not code.

Repository conventions are documented in `AGENTS.md`; consult it rather than
assuming, because the spec is reviewed against those conventions.

## Run context

The invoking prompt provides:

- **Issue number** — the issue to spec.
- **Repository** — the target repo (e.g. `zachreborn/terraform-modules`).

Fetch the issue body and comments before writing:

```sh
gh issue view <issue_number> --repo <repository> \
  --json title,body,labels,comments
```

## Required reading (consult before writing)

- `AGENTS.md` (root) — repo conventions: four-file module layout, tagging
  pattern, lifecycle ignores, tfsec suppression style.
- `.github/specs/_template.md` — the canonical spec layout your spec must follow.
- `modules/module_template/` — the starting point for new modules.

## Output

Create a new branch named:

```
spec/issue-<issue_number>-<short-kebab-slug>
```

Write the spec to:

```
.github/specs/issue-<issue_number>-<slug>.md
```

The spec MUST be based on `_template.md` and MUST contain:

- Background
- Non-goals
- Affected module path(s)
- Proposed `variables.tf` / `outputs.tf` / `main.tf` shape — **signatures only**:
  variable names, types, descriptions, and resource block names. No full
  implementation.
- Breaking-change assessment
- Checkov / tfsec suppression considerations (state "none" if no new
  suppressions are needed)
- terraform-docs impact (will the auto-generated README change?)
- Acceptance criteria

Check completeness exhaustively: walk this required-section list one item at a
time and confirm each section is present and substantive before opening the PR.
Do not skip a section or leave it as a placeholder. A spec that drops a section
stalls review and forces another round, so it is worth completing every section
now.

## Commit and PR

- Commit message: `spec: <issue title>` with body `Refs #<issue_number>` and the
  `Co-Authored-By` line for Oz.
- Push the branch.
- Open the PR as **ready-for-review** (NOT a draft) so that CODEOWNERS are
  auto-assigned via the `pull_request: ready_for_review` event. If your tooling
  defaults to draft, flip it to ready before exiting (the workflow also runs a
  `gh pr ready` safety net).
- Title: `spec: <issue title>`.
- The PR body MUST include `Refs #<issue_number>` (not `Fixes`) so the issue
  stays open through implementation.
- Advance the originating issue:

  ```sh
  gh issue edit <issue_number> --repo <repository> --add-label spec-ready-for-review
  gh issue edit <issue_number> --repo <repository> --remove-label spec-in-progress || true
  ```

- Post a comment on the issue with the spec PR URL.

## Guardrails

Do NOT modify any Terraform/OpenTofu files. Do NOT modify existing modules. The
only files you create or modify live under `.github/specs/`.
