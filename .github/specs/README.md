# Specs

This directory holds **technical specifications** that sit between a GitHub
issue and its implementation PR.

Each spec is reviewed and merged by codeowners **before** the corresponding
implementation work is done. The full pipeline is documented in the
"Automated issue/spec/impl pipeline" section of [`AGENTS.md`](../../AGENTS.md).

## Naming

```
issue-<issue-number>-<short-kebab-slug>.md
```

Examples:
- `issue-206-oz-issue-to-impl-workflow.md`
- `issue-310-aws-eks-node-group-iam-bug.md`

The `issue-<N>-` prefix is required — the `Spec Approved` and
`Implementation (Oz)` workflows use it to locate the originating issue and
the matching spec file.

## Layout

Use [`_template.md`](./_template.md) as the starting point. Every spec
must include the sections enumerated there:

- Title + status header (with `**Issue:** #<N>`)
- Background
- Non-goals
- Affected module path(s)
- Proposed `variables.tf` / `outputs.tf` / `main.tf` shape (signatures only)
- Breaking-change assessment
- Checkov / tfsec suppression considerations
- terraform-docs impact
- Acceptance criteria

## Lifecycle

1. Issue gets `ready-for-spec` (after triage).
2. `Spec Generation (Oz)` opens a PR adding a file here.
3. Codeowners review and merge that PR.
4. `Spec Approved` flips the issue to `spec-approved`.
5. `Implementation (Oz)` reads the spec from `main` and opens an
   implementation PR with `Fixes #<N>`.

`README.md` and `_template.md` are excluded from spec-PR detection.
