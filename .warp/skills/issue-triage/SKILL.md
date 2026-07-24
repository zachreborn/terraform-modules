---
name: issue-triage
description: >-
  Triage a GitHub issue in the zachreborn/terraform-modules Terraform/OpenTofu
  module library: check it for duplicate or closely related issues already in
  the pipeline, classify it as a bug or feature, validate it against the
  repository's minimum reporting standards, and move it through the
  issue-to-implementation pipeline by posting a single comment and applying the
  correct label (possible-duplicate, needs-info, or ready-for-spec) via the gh
  CLI. Use this skill whenever you are asked to triage, validate, classify, or
  label an incoming issue for this repo, or when an issue is opened or edited
  and needs its pipeline state set. This skill is the canonical source for the
  triage agent; the Issue Triage GitHub Actions workflow invokes it with
  per-run context.
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

## Duplicate and similar-issue check
Before classifying the issue, check whether the same request is already being
worked on elsewhere in the pipeline. This is the primary defense against
spending spec-generation or implementation effort twice on the same problem —
do this first, before classification.
1. Extract 2-4 distinguishing signals from the issue: the affected/target
   module path(s) (e.g. `modules/aws/ec2_instance`) plus a couple of
   distinctive nouns/phrases from the title. Skip generic words like "bug",
   "feature", "module", or "support".
2. Search issues in any state for overlap, excluding the current issue
   number:
   ```sh
   gh issue list --repo <repository> --state all \
     --search "<signal-1> <signal-2>" \
     --json number,title,state,labels,url --limit 20
   ```
   Re-run with just the module path if the first search is too broad or
   returns nothing useful.
3. Search pull requests the same way — a spec or implementation PR can exist
   for a request even before (or without) its issue carrying a pipeline
   label:
   ```sh
   gh pr list --repo <repository> --state all \
     --search "<signal-1> <signal-2>" \
     --json number,title,state,url,headRefName --limit 20
   ```
4. Grep the checked-out repo for a merged spec covering the same module —
   this catches cases where design work already happened even if the
   originating issue is closed:
   ```sh
   grep -ril "<module_path>" .github/specs/ 2>/dev/null
   ```
5. For every candidate surfaced above, read enough of it (title, body
   snippet, or spec content) to judge whether it describes the *same
   underlying request* — not merely the same module. A different bug or
   feature in a shared module is not a duplicate.
Classify the strongest candidate found, if any:
- **Active or completed effort** — a candidate issue/PR carries (or carried)
  any of `ready-for-spec`, `spec-in-progress`, `spec-ready-for-review`,
  `spec-approved`, `implementation-in-progress`, `implemented`, or a merged
  spec/implementation exists for the same request.
- **Open duplicate** — an open issue with no pipeline label yet already
  describes the same request.
- **Related, not duplicate** — same module/area but a distinct problem or
  request. Note it for context later; it does not change how this run
  proceeds.
- **None found** — proceed as normal.

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
5. Acceptance criteria for "done" — stated as verifiable, testable conditions (this repo requires every module to ship native `tofu test` coverage, so acceptance criteria should be written in terms an implementer can turn directly into test cases).

Check the standards exhaustively: walk the numbered list for the chosen
classification one item at a time and record every item that is absent or
inadequate. Do not stop at the first gap. Listing all missing items at once lets
the author fix everything in a single edit instead of cycling through repeated
re-triage rounds.

## Actions you must take

Use the `gh` CLI (it is already authenticated in your environment). Substitute
the issue number and repository from the run context. The duplicate check
takes priority: if it found an active/completed effort or an open duplicate,
take only the first action below and stop — do not also evaluate
classification or minimum standards this run.

**If the duplicate check found an active/completed effort or an open
duplicate:**

- Post a single comment that:
  - Links each duplicate candidate found (issue/PR/spec) by number and title,
    with its current pipeline state (e.g. open, `spec-approved`, merged,
    `implemented`).
  - States in one sentence why it matches (same module + same underlying
    request).
  - Ends with exactly:

    > If this is not a duplicate, please **edit the issue body** to explain the difference — editing the body re-triggers triage automatically. If it is a duplicate, please close this issue and reference the original.

- Then apply the label:

  ```sh
  gh issue edit <issue_number> --repo <repository> --add-label possible-duplicate
  ```

**If ANY required item is missing** (and no duplicate was flagged above):

- Post a single comment listing each missing item by name and briefly
  explaining what is needed. If the duplicate check found related-but-not-
  duplicate issues, add a short "Related issues" line linking them for
  context — this does not block anything. End the comment with exactly:

  > Please **edit the issue body** (not a comment reply) to add the items above — editing the body re-triggers triage automatically.

- Then apply the `needs-info` label and clear any stale duplicate flag from a
  prior run:

  ```sh
  gh issue edit <issue_number> --repo <repository> --add-label needs-info
  gh issue edit <issue_number> --repo <repository> --remove-label possible-duplicate || true
  ```

**If ALL required items are present** (and no duplicate was flagged above):

- Post a single short comment containing:
  - Classification (bug/feature)
  - Affected module path(s)
  - Breaking-change risk (none/low/medium/high) with one sentence of rationale
  - If the duplicate check found related-but-not-duplicate issues, a short
    "Related issues" line linking them for context
- Then advance the issue and clear any stale duplicate flag from a prior run:

  ```sh
  gh issue edit <issue_number> --repo <repository> --remove-label needs-info || true
  gh issue edit <issue_number> --repo <repository> --remove-label possible-duplicate || true
  gh issue edit <issue_number> --repo <repository> --add-label ready-for-spec
  ```

## Guardrails

Your only side effects are issue comments and label changes via `gh`. Do not
edit any files. Do not push commits. Do not open PRs. Do not invoke `terraform`
or `tofu`. Do not close issues yourself — flagging `possible-duplicate` is a
suggestion for a human to confirm. Post exactly one comment per run.
