# Spec: ci: automate SemVer tag/release creation from Conventional Commits and define repo tag strategy
**Issue:** #290
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** CI/automation (no Terraform module changes)

## 1. Background
Version tags (`v*.*.*`) are created **by hand** today. The existing
`.github/workflows/release.yml` only reacts *after* a tag is pushed — it runs
`gh release create "$TAG_NAME" --generate-notes --verify-tag`. It does not
decide the next version, nor does it derive the bump from commit history. The
repo already follows Conventional Commits on `main` (squash-merged PR titles
per the `/commit-standards` convention), the current release is `v8.16.0`, and
callers pin module sources by tag (e.g. `...//modules/...?ref=v8.16.0`).

Because the human picks the bump manually, an incorrect or skipped MAJOR bump on
a breaking change can silently break downstream consumers. The goal is to
**compute** the next SemVer from Conventional Commit history and gate the actual
tag/release behind a codeowner merge, and to **document a repository tag
strategy** so the rules are explicit.

The recommended tool is **release-please** (Google's GitHub-native release
automation): it reads Conventional Commit history, computes the next SemVer, and
opens/maintains a **Release PR** that owns `CHANGELOG.md`. Merging that PR cuts
the `vX.Y.Z` tag and publishes the GitHub Release. The human merge step matches
this repo's existing review-gated philosophy (codeowner-merged spec/impl PRs,
approval-required CI) and avoids surprise zero-touch releases of a library whose
tags are a public contract. See issue #290 for the full discussion.

## 2. Non-goals
- **Per-module tags** (e.g. `module-name-vX.Y.Z`) — explicitly deferred; they
  would break the existing `?ref=vX.Y.Z` consumption pattern. Note only as a
  possible future enhancement.
- **Fully zero-touch releases** (e.g. semantic-release on every merge to
  `main`) — rejected in favor of review-gated automation.
- Changing the repo-wide SemVer line or the `v` tag prefix.
- Changing how callers pin modules (`?ref=`).
- Modifying any Terraform/OpenTofu module under `modules/`.
- Pre-`1.0` "anything goes" leniency — the repo is well past `v1.0.0`, so
  breaking changes must bump MAJOR.
- Replacing milestones — they remain the human roadmap/planning layer.

## 3. Affected module path(s)
No Terraform/OpenTofu modules are affected. Files:
- New: `.github/workflows/release-please.yml`
- New: `release-please-config.json` (repo root)
- New: `.release-please-manifest.json` (repo root, seeded to `8.16.0`)
- New: `CHANGELOG.md` (repo root, owned by release-please going forward)
- Modified (publisher decision — see §4): `.github/workflows/release.yml`
- Modified docs: `AGENTS.md` (new "Release & Tag Strategy" section); `README.md`
  and/or a new `CONTRIBUTING.md` (no `CONTRIBUTING` file exists today).

## 4. Proposed design
**Signatures only — no full implementations.**

This change is GitHub Actions / release tooling, not a Terraform module, so the
standard `variables.tf` / `outputs.tf` / `main.tf` sections do not apply (same
precedent as `issue-260` and `issue-206`).

### Tag strategy (to be documented in `AGENTS.md` / `README` / `CONTRIBUTING`)
- **Single, repo-wide SemVer line**: `vMAJOR.MINOR.PATCH`, `v`-prefixed. This
  matches the existing tags, `v8.16.0`, the `release.yml` trigger (`v*.*.*`), and
  how callers pin modules.
- **Bump rules from Conventional Commits** (`/commit-standards`):
  - `feat:` → **MINOR**
  - `fix:` → **PATCH**
  - `feat!:` / `fix!:` / `BREAKING CHANGE:` footer → **MAJOR**
  - `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore` → no
    release on their own.
- **No pre-`1.0` leniency.**
- **Milestones** stay as the forward-looking roadmap (`v8.17.0`, `v9.0.0`).
  Because the version is *computed*, a milestone name may drift from the cut
  version (a `v8.17.0` milestone becomes `v9.0.0` if a breaking change lands
  first). Add a lightweight **reconciliation step**: rename/close the milestone
  to match the version release-please actually cuts.

### `.github/workflows/release-please.yml`
- **Trigger:** `on: push: branches: [main]`.
- **Permissions (job or workflow level):** `contents: write`,
  `pull-requests: write` (and `issues: write`, which release-please uses for
  labeling/commenting per upstream docs).
- **Single job, single step:** `googleapis/release-please-action`, **pinned by
  commit SHA** with a version comment (zizmor supply-chain policy, consistent
  with how `release.yml` pins `actions/checkout` and how `issue-206` pins
  `warpdotdev/oz-agent-action`). Inputs (names only):
  - `token` — see token decision below.
  - `config-file: release-please-config.json`
  - `manifest-file: .release-please-manifest.json`

### `release-please-config.json` (manifest-driven config — keys only)
- `$schema` — release-please config schema URL.
- `release-type: "simple"` — see "Notes" for why not `terraform-module`.
- `include-component-in-tag: false` — keep a single repo-wide `vX.Y.Z` tag with
  no component prefix.
- `packages` — a single root entry `"."` carrying the per-package options above.
- `changelog-sections` (optional) — map Conventional Commit types to changelog
  headings / hide non-releasing types.
- Tag prefix remains `v` (default). Pre-`1.0` options
  (`bump-minor-pre-major`, etc.) are **not** set — the repo is past `1.0`.

### `.release-please-manifest.json` (shape)
- `{ ".": "8.16.0" }` — seeds the current version so history is **not**
  re-scanned from zero; the next bump is computed from commits since the
  existing `v8.16.0` tag.

### `CHANGELOG.md`
- New root file, owned by release-please. Minimal seed (e.g. a heading or the
  current version stub); release-please prepends entries on each release.

### `.github/workflows/release.yml` (publisher decision — exactly one publisher)
- **Recommended: release-please is the single publisher.** On Release PR merge,
  release-please cuts the `vX.Y.Z` tag and publishes the GitHub Release with
  notes derived from `CHANGELOG.md` — its native behavior.
- **Why this avoids a double-publish:** GitHub deliberately does **not** trigger
  downstream workflows for refs created with the default `GITHUB_TOKEN`
  (recursive-workflow prevention). A release-please tag created via
  `GITHUB_TOKEN` therefore would **not** fire the tag-listening `release.yml`.
  Relying on that silently is fragile (it would start double-publishing the day
  someone switches release-please to a PAT/App token). To make the single
  publisher explicit, **convert `release.yml` to `workflow_dispatch`-only** (a
  manual fallback for hand-cut/emergency tags) **or remove it**. Either way:
  exactly one publisher.

### Permissions / repo configuration (manual, one-time)
- Enable **Settings → Actions → General → "Allow GitHub Actions to create and
  approve pull requests"** so release-please can open the Release PR.
- The Release PR is created via `GITHUB_TOKEN`, so its required checks (`Linter`,
  `Test OpenTofu`, `Verify - terraform-docs`, `Invisible Unicode Check`) land in
  the **approval-required** state — the same per-PR "Approve workflows to run"
  gate already documented in `AGENTS.md` for Oz bot PRs. A maintainer clicks it
  before merge. Adopting a PAT or GitHub App token removes that click (future
  enhancement; see Open questions).

### Notes / design decisions
- **`release-type: simple` (not `terraform-module`):** the `terraform-module`
  strategy expects a version string embedded in a single module's `README.md`
  and targets single-module repos. This repo is a multi-module library with one
  repo-wide version held in the manifest, so `simple` is the right fit — it
  maintains `CHANGELOG.md` + the manifest version and cuts the tag/release
  **without** editing any module files. No `version.txt` is required because the
  manifest is the source of truth for the version.
- The action is pinned by commit SHA per the zizmor supply-chain policy.

## 5. Breaking-change assessment
- Breaking: **no** (to Terraform modules / consumers).
- The repo-wide SemVer line and `v` prefix are unchanged, so existing caller
  `?ref=vX.Y.Z` pins continue to work. The only behavioral change is **how**
  tags get created (review-gated automation instead of manual).
- If `release.yml` is converted to `workflow_dispatch`-only or removed, the
  **manual emergency-tagging path changes**; the new path must be documented in
  the "Release & Tag Strategy" section so maintainers know how to cut a release
  by hand if needed.

## 6. Checkov / tfsec considerations
- New suppressions: **none** — this change does not touch Terraform code.
- zizmor: the new third-party action must be **pinned by commit SHA** to satisfy
  the existing supply-chain policy — no suppression is required.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
**None.** No module-level Terraform changes, so no `<!-- BEGIN_TF_DOCS -->`
blocks change for any module.

## 8. Testing
- `tofu fmt -check -diff -recursive` (and Terraform equivalent) must remain
  clean — no `.tf` files are modified.
- `super-linter` (existing `test.yml`) must pass for the new YAML / JSON /
  Markdown, plus the invisible-Unicode check.
- Validate that `release-please-config.json` and `.release-please-manifest.json`
  are well-formed JSON.
- **Dry run on a test branch / PR before rollout:**
  - A `feat(...)` commit produces a Release PR proposing the next **MINOR**.
  - A `feat!:` / `BREAKING CHANGE:` commit produces a Release PR proposing the
    next **MAJOR** (e.g. `v9.0.0`) — validates the breaking-change acceptance
    item.
  - Merging the Release PR creates exactly **one** GitHub Release for the tag
    (no duplicate from `release.yml`).
  - Confirm the seeded manifest makes the next release build off `v8.16.0`
    rather than re-scanning history from zero.

## 9. Open questions
- **Token choice:** default `GITHUB_TOKEN` (recommended for the single-publisher
  design) vs a PAT (`RELEASE_PLEASE_TOKEN`) vs a **GitHub App token**
  (`actions/create-github-app-token`). A non-default token is only needed if
  maintainers want CI to run automatically on the Release PR (instead of the
  one-click "Approve workflows to run") or if `release.yml` is kept as the
  publisher. **Recommendation:** start with `GITHUB_TOKEN`; track a GitHub App
  token as a future enhancement (repo-scoped, ephemeral, survives maintainer
  turnover).
- **Fate of `release.yml`:** convert to `workflow_dispatch`-only fallback
  (recommended) vs delete entirely.
- **`changelog-sections`:** keep release-please defaults vs customize which
  non-releasing types (e.g. `ci`, `chore`) appear in `CHANGELOG.md`.
- **Docs home:** add a new `CONTRIBUTING.md` vs document the strategy in
  `README.md` (in addition to the `AGENTS.md` section).

## 10. Acceptance criteria
Mirrors the issue's "Confirmation" section:
- [ ] Repo-wide SemVer tag strategy is documented (single `vX.Y.Z` line; bump
      rules mapped to Conventional Commit types; per-module tags explicitly
      deferred).
- [ ] A review-gated automated tagging workflow (release-please) is added,
      pinned by commit SHA, seeded at the current version (`8.16.0`), and opens
      a Release PR on qualifying merges.
- [ ] Merging the Release PR creates the correct `vX.Y.Z` tag and exactly **one**
      GitHub Release (no duplicate publishing).
- [ ] `CHANGELOG.md` is generated/maintained automatically and reflects
      Conventional Commit history.
- [ ] Decision recorded: automated tags + milestones are used **together** with
      the roles defined above, including the milestone → actual-version
      reconciliation step.
- [ ] A breaking-change commit correctly proposes a MAJOR bump in the Release PR
      (validated on a test branch/PR before rollout).
- [ ] The release-please action is pinned by commit SHA (zizmor supply-chain
      policy); no new Checkov/tfsec suppressions are introduced.
- [ ] The one-time "Allow GitHub Actions to create and approve pull requests"
      repo setting (and the token decision) is documented in the PR/description.
