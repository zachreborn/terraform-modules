# Spec: Refactor release workflow to replace action-gh-release with gh release
**Issue:** #260
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** CI/automation

## 1. Background
The `.github/workflows/release.yml` workflow currently uses the third-party
action `softprops/action-gh-release@v3.0.0` (pinned by SHA) to create GitHub
releases when a `v*.*.*` tag is pushed. Zizmor flags this as a
`superfluous-actions` finding because GitHub-hosted runners already ship the
`gh` CLI, which natively supports `gh release create` with auto-generated
release notes.

Replacing the third-party action with a `gh release create` script step will:

- Reduce the third-party GitHub Action dependency surface area.
- Eliminate the zizmor `superfluous-actions` finding without adding a
  suppression.
- Keep release creation behavior explicit and auditable in the workflow.

This was identified while consolidating GitHub Actions dependency updates in
PR #259.

Current workflow (`release.yml`):

```yaml
steps:
  - name: Checkout
    uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
    with:
      persist-credentials: false
  - name: Create release
    uses: softprops/action-gh-release@b4309332981a82ec1c5618f44dd2e27cc8bfbfda # v3.0.0
    with:
      generate_release_notes: true
```

## 2. Non-goals
- Changing the release trigger (stays `push: tags: ["v*.*.*"]`).
- Adding asset uploads, pre-release flags, or custom release body templates.
- Modifying any other workflow file.
- Changing any Terraform/OpenTofu module code.

## 3. Affected module path(s)
- No Terraform/OpenTofu modules are affected.
- Affected file: `.github/workflows/release.yml`

## 4. Proposed design
**Signatures only — no full implementations.**

This change modifies a GitHub Actions workflow, not a Terraform module. The
standard `variables.tf` / `outputs.tf` / `main.tf` sections do not apply.

### Workflow changes (`.github/workflows/release.yml`)

Replace the `softprops/action-gh-release` step with a `run:` step that
invokes `gh release create`. The proposed step structure:

- **Step name:** `Create release`
- **Shell:** `bash` (explicit, though it is the default on `ubuntu-latest`)
- **Command:** `gh release create` with:
  - The tag ref from `${{ github.ref_name }}` as the release tag.
  - `--generate-notes` to replicate the existing `generate_release_notes: true`
    behavior.
  - `--verify-tag` to ensure the tag exists on the remote before creating the
    release (safety guard).
- **Environment:** `GH_TOKEN` set to `${{ secrets.GITHUB_TOKEN }}` (required
  by `gh` for authentication).

### Permissions

The existing `contents: write` permission remains unchanged — it is the
minimum required for `gh release create` to create releases and upload assets.

### Checkout step

The `actions/checkout` step remains. `gh release create` does not strictly
require a checkout, but keeping it ensures the workflow has access to the
repository context and is consistent with other workflows in the repo. The
`persist-credentials: false` setting stays to avoid leaving tokens on disk.

## 5. Breaking-change assessment
- Breaking: **no**
- The tag trigger, release creation behavior, and auto-generated release notes
  are all preserved. Consumers of the releases (downstream callers pulling
  module source by tag) are unaffected.

## 6. Checkov / tfsec considerations
- New suppressions: **none** — this change does not touch Terraform code.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
No. No Terraform modules are modified, so no `<!-- BEGIN_TF_DOCS -->` blocks
will change.

## 8. Testing
- **Manual verification:** push a test tag (e.g. `v0.0.0-rc.test`) to a fork
  or use `workflow_dispatch` (if added temporarily) to confirm:
  - A GitHub release is created for the tag.
  - Release notes are auto-generated.
  - No errors in the workflow run logs.
- **Zizmor scan:** run `zizmor .github/workflows/release.yml` locally (or
  against the full `.github/workflows/` directory) and confirm the
  `superfluous-actions` finding no longer appears for `release.yml`.
- **Permission audit:** confirm the workflow uses only `contents: write` and
  no additional permissions are required.

## 9. Open questions
- Should the `actions/checkout` step be removed entirely? `gh release create`
  does not need a working copy — but removing checkout would diverge from the
  pattern used by other workflows and could break future steps if the workflow
  is extended. **Recommendation:** keep checkout for now.
- Should `--verify-tag` be included in the `gh release create` call? It adds
  a safety check that the tag exists on the remote. **Recommendation:** yes,
  include it.

## 10. Acceptance criteria
- [ ] `.github/workflows/release.yml` no longer uses `softprops/action-gh-release`.
- [ ] The workflow uses a `run:` step with `gh release create` instead.
- [ ] Release creation still triggers on pushed `v*.*.*` tags.
- [ ] Auto-generated release notes are enabled (`--generate-notes`).
- [ ] `GH_TOKEN` is set via `${{ secrets.GITHUB_TOKEN }}` for `gh` authentication.
- [ ] Permissions remain `contents: write` (least-privilege for release creation).
- [ ] Zizmor no longer reports `superfluous-actions` for `release.yml`.
- [ ] Existing release workflow behavior is documented in the PR description.
