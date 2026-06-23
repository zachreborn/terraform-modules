# Changelog

## [8.20.3](https://github.com/zachreborn/terraform-modules/compare/v8.20.2...v8.20.3) (2026-06-23)


### Bug Fixes

* **organizations/organization:** prefix file() paths with ${path.module}/ ([#334](https://github.com/zachreborn/terraform-modules/issues/334)) ([492f177](https://github.com/zachreborn/terraform-modules/commit/492f177c22bb8d0fccfcfff57dec44fb3fbacf5f))

## [8.20.2](https://github.com/zachreborn/terraform-modules/compare/v8.20.1...v8.20.2) (2026-06-23)


### Bug Fixes

* **aws_backup:** render org backup policy inline to fix file() path error ([#329](https://github.com/zachreborn/terraform-modules/issues/329)) ([0b07035](https://github.com/zachreborn/terraform-modules/commit/0b0703598e5f4704f13c8b7f7a600fda938374cd))

## [8.20.1](https://github.com/zachreborn/terraform-modules/compare/v8.20.0...v8.20.1) (2026-06-16)


### Bug Fixes

* **aws_backup:** use set(string) for organization_backup_plan for_each ([#323](https://github.com/zachreborn/terraform-modules/issues/323)) ([a09502b](https://github.com/zachreborn/terraform-modules/commit/a09502bafa95684d3f45ce9c646311ff0f9f1dc7))

## [8.20.0](https://github.com/zachreborn/terraform-modules/compare/v8.19.1...v8.20.0) (2026-06-15)


### Features

* **cloudformation/stack_set:** add stack_set_instance_region variable to stack set instance ([#316](https://github.com/zachreborn/terraform-modules/issues/316)) ([da78e71](https://github.com/zachreborn/terraform-modules/commit/da78e714646661e768754ce74df9434300b8abfe))

## [8.19.1](https://github.com/zachreborn/terraform-modules/compare/v8.19.0...v8.19.1) (2026-06-14)


### Bug Fixes

* **amplify:** replace deprecated data.aws_region.current.id with .region ([#309](https://github.com/zachreborn/terraform-modules/issues/309)) ([190f2da](https://github.com/zachreborn/terraform-modules/commit/190f2daf6ef1f532c141c783ef11266ec6d040fa))

## [8.19.0](https://github.com/zachreborn/terraform-modules/compare/v8.18.0...v8.19.0) (2026-06-14)


### Features

* **s3:** modernize bucket server-side encryption options ([#305](https://github.com/zachreborn/terraform-modules/issues/305)) ([a1bba3d](https://github.com/zachreborn/terraform-modules/commit/a1bba3d423431c1411ad7388b6957ccd1078cf00))

## [8.18.0](https://github.com/zachreborn/terraform-modules/compare/v8.17.0...v8.18.0) (2026-06-14)


### Features

* **iam:** add policy name lookup to user_policy_attachment ([#301](https://github.com/zachreborn/terraform-modules/issues/301)) ([422e714](https://github.com/zachreborn/terraform-modules/commit/422e714661c013591d64cbfad9b50ed88dc40c48))

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
