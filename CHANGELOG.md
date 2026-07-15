# Changelog

## [11.0.1](https://github.com/zachreborn/terraform-modules/compare/v11.0.0...v11.0.1) (2026-07-15)


### Bug Fixes

* **cloudformation/stack_set:** reject both template_body and template_url at plan time ([#425](https://github.com/zachreborn/terraform-modules/issues/425)) ([1e13d7f](https://github.com/zachreborn/terraform-modules/commit/1e13d7f6796362cb9a934aa8d4dc954f11047c27))

## [11.0.0](https://github.com/zachreborn/terraform-modules/compare/v10.2.7...v11.0.0) (2026-07-15)


### ⚠ BREAKING CHANGES

* **cloudwatch/alarm:** type action variables as list(string) with safe defaults ([#427](https://github.com/zachreborn/terraform-modules/issues/427))

### Bug Fixes

* **cloudwatch/alarm:** type action variables as list(string) with safe defaults ([#427](https://github.com/zachreborn/terraform-modules/issues/427)) ([ca12815](https://github.com/zachreborn/terraform-modules/commit/ca12815f4445cd391ad44897ca652a2799e24a03))

## [10.2.7](https://github.com/zachreborn/terraform-modules/compare/v10.2.6...v10.2.7) (2026-07-14)


### Bug Fixes

* **aws/cloudformation/stack:** give URL form precedence over body ([#410](https://github.com/zachreborn/terraform-modules/issues/410)) ([e05561d](https://github.com/zachreborn/terraform-modules/commit/e05561d7d9ec6a82989828eba3ec21cefaf1df6a))

## [10.2.6](https://github.com/zachreborn/terraform-modules/compare/v10.2.5...v10.2.6) (2026-07-14)


### Bug Fixes

* **ec2_instance:** anchor enum regex validations for shutdown behavior and auto_recovery ([#412](https://github.com/zachreborn/terraform-modules/issues/412)) ([aebf992](https://github.com/zachreborn/terraform-modules/commit/aebf992962503d7cbd975d1b976d5e9755ff97fe))

## [10.2.5](https://github.com/zachreborn/terraform-modules/compare/v10.2.4...v10.2.5) (2026-07-14)


### Bug Fixes

* **ec2_instance:** apply auto_recovery via maintenance_options block ([#413](https://github.com/zachreborn/terraform-modules/issues/413)) ([7971c03](https://github.com/zachreborn/terraform-modules/commit/7971c03212fb0ae3277656707d4444798860a0ce))

## [10.2.4](https://github.com/zachreborn/terraform-modules/compare/v10.2.3...v10.2.4) (2026-07-14)


### Bug Fixes

* **vpc:** gate NAT routes and public association on local.enable_igw ([#415](https://github.com/zachreborn/terraform-modules/issues/415)) ([6b4d1ce](https://github.com/zachreborn/terraform-modules/commit/6b4d1ce3e727de59a4a53131a975d9552b591636))

## [10.2.3](https://github.com/zachreborn/terraform-modules/compare/v10.2.2...v10.2.3) (2026-07-14)


### Bug Fixes

* **route53:** drop trailing TXT separator on exact 255-char multiples ([#408](https://github.com/zachreborn/terraform-modules/issues/408)) ([74aae22](https://github.com/zachreborn/terraform-modules/commit/74aae228e18428a603033fe1e2ca587d1b31f2c3))

## [10.2.2](https://github.com/zachreborn/terraform-modules/compare/v10.2.1...v10.2.2) (2026-07-14)


### Bug Fixes

* **lambda:** align timeout description with actual 180 default ([#414](https://github.com/zachreborn/terraform-modules/issues/414)) ([536507e](https://github.com/zachreborn/terraform-modules/commit/536507eac0d6cd06e8bf6aec94e5539f3c09a8fd))

## [10.2.1](https://github.com/zachreborn/terraform-modules/compare/v10.2.0...v10.2.1) (2026-07-14)


### Bug Fixes

* **amplify:** widen cache_config_type validation to allow null ([#411](https://github.com/zachreborn/terraform-modules/issues/411)) ([7bbd540](https://github.com/zachreborn/terraform-modules/commit/7bbd540d12c57669ba5b531d552d46112212143e))

## [10.2.0](https://github.com/zachreborn/terraform-modules/compare/v10.1.0...v10.2.0) (2026-07-12)


### Features

* **ecs:** add AWS ECS module family ([#295](https://github.com/zachreborn/terraform-modules/issues/295)) ([3a90693](https://github.com/zachreborn/terraform-modules/commit/3a90693429b03dd87129907cd35df9ec05457409))

## [10.1.0](https://github.com/zachreborn/terraform-modules/compare/v10.0.0...v10.1.0) (2026-07-09)


### Features

* **organizations:** add four new SCPs to the organization module ([#371](https://github.com/zachreborn/terraform-modules/issues/371)) ([2a53032](https://github.com/zachreborn/terraform-modules/commit/2a530327293ae97de724bd76e96fd8d39fbd77c8))

## [10.0.0](https://github.com/zachreborn/terraform-modules/compare/v9.0.0...v10.0.0) (2026-07-08)


### ⚠ BREAKING CHANGES

* **fsx:** modernize FSx for Windows File Server module ([#366](https://github.com/zachreborn/terraform-modules/issues/366))

### Features

* **fsx:** modernize FSx for Windows File Server module ([#366](https://github.com/zachreborn/terraform-modules/issues/366)) ([fe8566a](https://github.com/zachreborn/terraform-modules/commit/fe8566aae95e816ac86798d10f3c9d3976dd58a8))

## [9.0.0](https://github.com/zachreborn/terraform-modules/compare/v8.25.0...v9.0.0) (2026-07-06)


### ⚠ BREAKING CHANGES

* **organizations:** map-based ou/account modules + composed module ([#362](https://github.com/zachreborn/terraform-modules/issues/362))

### Features

* **organizations:** map-based ou/account modules + composed module ([#362](https://github.com/zachreborn/terraform-modules/issues/362)) ([84d0e55](https://github.com/zachreborn/terraform-modules/commit/84d0e55b7669143813d652774e33704f679b9809))

## [8.25.0](https://github.com/zachreborn/terraform-modules/compare/v8.24.0...v8.25.0) (2026-07-06)


### Features

* **organizations:** add opt-in Region-restriction SCP to organization module ([#360](https://github.com/zachreborn/terraform-modules/issues/360)) ([55f2f25](https://github.com/zachreborn/terraform-modules/commit/55f2f252500855a7308a387b8e7d2437e425e784))

## [8.24.0](https://github.com/zachreborn/terraform-modules/compare/v8.23.0...v8.24.0) (2026-07-04)


### Features

* **security-hub:** support AWS Security Hub 2026 changes (CSPM + unified v2) ([#352](https://github.com/zachreborn/terraform-modules/issues/352)) ([b1a4f95](https://github.com/zachreborn/terraform-modules/commit/b1a4f952e82a363880019c2691499aa1b6c76277))

## [8.23.0](https://github.com/zachreborn/terraform-modules/compare/v8.22.0...v8.23.0) (2026-06-30)


### Features

* **ssm_domain_join:** add module for automated AD domain join via SSM ([#325](https://github.com/zachreborn/terraform-modules/issues/325)) ([adbd56c](https://github.com/zachreborn/terraform-modules/commit/adbd56c1b9483f06c826a03d246305ed75d829b8))

## [8.22.0](https://github.com/zachreborn/terraform-modules/compare/v8.21.0...v8.22.0) (2026-06-30)


### Features

* **datadog:** add integrations modules ([#344](https://github.com/zachreborn/terraform-modules/issues/344)) ([d5c3e32](https://github.com/zachreborn/terraform-modules/commit/d5c3e32d968a840a73740326a2d3600759d07ff8))
* **datadog:** add monitors modules ([#342](https://github.com/zachreborn/terraform-modules/issues/342)) ([54e6caf](https://github.com/zachreborn/terraform-modules/commit/54e6cafca2607779e85e434de1b953868211edf3))
* **datadog:** add synthetics modules ([#343](https://github.com/zachreborn/terraform-modules/issues/343)) ([d5d0d00](https://github.com/zachreborn/terraform-modules/commit/d5d0d00517473b078a7305ced32d8e350a198c1d))

## [8.21.0](https://github.com/zachreborn/terraform-modules/compare/v8.20.3...v8.21.0) (2026-06-26)


### Features

* **datadog:** add real user monitoring (RUM) modules ([#340](https://github.com/zachreborn/terraform-modules/issues/340)) ([689ea5b](https://github.com/zachreborn/terraform-modules/commit/689ea5b285f0244897318c950805a66267ce4670))

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
