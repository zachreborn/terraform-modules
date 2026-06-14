# Description
<!-- Description of the changes introduced by this Pull Request (PR). Link to an issue or ticket where possible for more context.-->
A brief description of the changes introduced by this Pull Request.

> **PR title must follow [Conventional Commits](https://www.conventionalcommits.org/):** `<type>(optional scope): <description>` (for example `feat(vpc): add flow log support`). This repository squash-merges, so the PR title becomes the commit subject that drives release notes and the SemVer bump. Append `!` after the type/scope for a breaking change (for example `feat(api)!: ...`).

## Issue or Ticket
<!-- Link to the issue or ticket this PR addresses. Use "Fixes #N" to auto-close it on merge, or "Refs #N" to keep it open. -->
Fixes #000

## Type of change
<!-- Select the Conventional Commit type that matches your PR title. Only `feat`, `fix`, and breaking changes affect the released version. -->
- [ ] `feat` — a new user-facing feature (SemVer MINOR)
- [ ] `fix` — a bug fix (SemVer PATCH)
- [ ] `docs` — documentation only
- [ ] `style` — formatting/whitespace; no logic change
- [ ] `refactor` — code change that neither fixes a bug nor adds a feature
- [ ] `perf` — performance improvement
- [ ] `test` — adding or correcting tests
- [ ] `build` — build system or dependency changes
- [ ] `ci` — CI configuration (GitHub Actions, etc.)
- [ ] `chore` — maintenance task that does not fit elsewhere
- [ ] `revert` — reverts a previous commit

## Breaking Changes
<!-- A breaking change triggers a SemVer MAJOR bump. Signal it with `!` in the PR title or a `BREAKING CHANGE:` footer. -->
- [ ] Yes — this is a breaking change
- [ ] No

### Breaking Changes Description
<!-- If yes, describe what breaks and the migration path. This becomes the BREAKING CHANGE footer. -->


## TODOs
<!-- Complete these tasks prior to requesting a review.-->
- [ ] PR title follows Conventional Commits (`<type>(scope): description`).
- [ ] Validate your code matches the style of the project (`tofu fmt -recursive`).
- [ ] Update the docs (regenerate the `terraform-docs` block where applicable).
- [ ] Validate all tests run successfully, including pre-commit checks.
- [ ] Include release notes and description. This should include both a summary of the changes and any necessary context.
