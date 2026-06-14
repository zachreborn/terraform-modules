# Changelog

## [8.17.0](https://github.com/zachreborn/terraform-modules/compare/v8.16.0...v8.17.0) (2026-06-14)


### Features

* add Zscaler ZPA App Connector vendor module ([#208](https://github.com/zachreborn/terraform-modules/issues/208)) ([c0215ab](https://github.com/zachreborn/terraform-modules/commit/c0215ab0ffcf414146971b7f887b4af232886d8e))
* **identity_center:** add group_memberships output and make groups description optional ([#279](https://github.com/zachreborn/terraform-modules/issues/279)) ([5479839](https://github.com/zachreborn/terraform-modules/commit/5479839dec9cf927aba3a4dbe405f7a50729f8bf))


### Bug Fixes

* **aws/amplify:** suppress perpetual basic_auth_credentials diff via lifecycle.ignore_changes ([#288](https://github.com/zachreborn/terraform-modules/issues/288)) ([73acff0](https://github.com/zachreborn/terraform-modules/commit/73acff0fb3e0d3e45aa3322baadcf10b9d94234c))
* correct terraform-docs auto-commit guidance in skill and AGENTS.md ([#293](https://github.com/zachreborn/terraform-modules/issues/293)) ([3d5e186](https://github.com/zachreborn/terraform-modules/commit/3d5e186e8e23f92334c7d5e73f070c7dcb7bdd57))

## Changelog

All notable changes to this repository are documented in this file.

From `v8.16.0` onward this file is maintained automatically by
[release-please](https://github.com/googleapis/release-please) from
[Conventional Commit](https://www.conventionalcommits.org/) history: each
qualifying merge to `main` updates the open **Release PR**, and merging that PR
cuts the next `vX.Y.Z` tag and publishes the GitHub Release. Do not edit past
release entries by hand — release-please prepends new entries on each release.

For the release/versioning rules (bump mapping, tag prefix, milestone
reconciliation, and the manual fallback), see
[`AGENTS.md` § Release & Tag Strategy](./AGENTS.md#release--tag-strategy).

Releases tagged before this automation was introduced (up to and including
`v8.16.0`) are recorded in the
[GitHub Releases](https://github.com/zachreborn/terraform-modules/releases)
list rather than in this file.
