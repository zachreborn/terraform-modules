---
name: issue-triage
description: >-
  Triage a GitHub issue in the zachreborn/terraform-modules Terraform/OpenTofu
  module library: classify it as a bug or feature, validate it against the
  repository's minimum reporting standards, and move it through the
  issue-to-implementation pipeline by posting a single comment and applying the
  correct label (needs-info or ready-for-spec) via the gh CLI. Use this skill
  whenever you are asked to triage, validate, classify, or label an incoming
  issue for this repo, or when an issue is opened or edited and needs its
  pipeline state set. This skill is the canonical source for the triage agent;
  the Issue Triage GitHub Actions workflow invokes it with per-run context.
---

# Issue triage

You triage a single GitHub issue for `zachreborn/terraform-modules`, a
Terraform/OpenTofu module library (OpenTofu is the default; Terraform is also
supported). Your job is to decide whether the issue is actionable, and to move
it one step through the issue → spec → implementation pipeline by labeling it
and leaving exactly one comment.

Getting this right matters because the next pipeline stage (spec generation) is
triggered off the `ready-for-spec` label. Promoting an under-specified issue
wastes a spec run; over-asking for info on a complete issue stalls the author.

## Run context

The specific issue is provided in the invoking prompt. Expect these fields:

- **Issue number** — the issue to act on.
- **Repository** — the target repo (e.g. `zachreborn/terraform-modules`).
- **URL**, **Title**, **Labels**, **Body** — the issue contents to evaluate.

If the body is not included in the prompt, fetch it first:

```sh
gh issue view <issue_number> --repo <repository> \
  --json title,body,labels,comments
```

## Classification

Classify the issue as `bug` or `feature` based on the existing labels and body
content. If it is clearly both or neither, do not guess — ask in your comment
and apply `needs-info`.

## Minimum standards

A **bug** must include all of:

1. Affected module path (e.g. `modules/aws/ec2_instance`).
2. OpenTofu or Terraform version and relevant provider versions.
3. Reproduction steps.
4. Expected vs. actual behavior.
5. One of: error message, stack trace, or plan/apply output.
6. Acceptance criteria for "fixed."

A **feature** must include all of:

1. Target module path (existing or proposed under `modules/<provider>/<name>/`).
2. Motivation / problem being solved.
3. High-level proposed inputs and outputs.
4. Breaking-change assessment (yes/no + scope).
5. Acceptance criteria for "done."

Check the standards exhaustively: walk the numbered list for the chosen
classification one item at a time and record every item that is absent or
inadequate. Do not stop at the first gap. Listing all missing items at once lets
the author fix everything in a single edit instead of cycling through repeated
re-triage rounds.

## Actions you must take

Use the `gh` CLI (it is already authenticated in your environment). Substitute
the issue number and repository from the run context.

**If ANY required item is missing:**

- Post a single comment listing each missing item by name and briefly
  explaining what is needed. End the comment with exactly:

  > Please **edit the issue body** (not a comment reply) to add the items above — editing the body re-triggers triage automatically.

- Then apply the `needs-info` label:

  ```sh
  gh issue edit <issue_number> --repo <repository> --add-label needs-info
  ```

**If ALL required items are present:**

- Post a single short comment containing:
  - Classification (bug/feature)
  - Affected module path(s)
  - Breaking-change risk (none/low/medium/high) with one sentence of rationale
- Then advance the issue:

  ```sh
  gh issue edit <issue_number> --repo <repository> --remove-label needs-info || true
  gh issue edit <issue_number> --repo <repository> --add-label ready-for-spec
  ```

## Guardrails

Your only side effects are issue comments and label changes via `gh`. Do not
edit any files. Do not push commits. Do not open PRs. Do not invoke `terraform`
or `tofu`. Post exactly one comment per run.
