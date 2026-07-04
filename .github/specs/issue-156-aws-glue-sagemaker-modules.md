# Spec: Add AWS Glue and SageMaker Modules
**Issue:** #156
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The library has no modules for AWS Glue or Amazon SageMaker AI. Issue #156
requests three net-new modules so callers can manage ML / data-engineering
infrastructure as code:

- `aws_glue_catalog_database` — Glue Data Catalog databases for data lakes and
  ML feature stores.
- `aws_sagemaker_domain` — SageMaker Studio domains with VPC integration.
- `aws_sagemaker_user_profile` — user profiles inside a SageMaker domain.

All three are standalone provider resources that map cleanly onto the repo's
four-file module layout (`modules/module_template/`). They follow the same
conventions already used by an analytics-adjacent precedent,
`modules/aws/athena/workgroup/` (single-instance resource, `resource "..." "this"`,
`(Required)`/`(Optional)` variable descriptions, `validation` blocks, `terraform {}`
block pinned to `aws >= 6.0.0`).

The issue body requests `AWS Provider >= 4.0.0`, but this library standardizes on
`aws >= 6.0.0` (see `AGENTS.md` → Code Conventions). This spec adopts
`aws >= 6.0.0` / `required_version = ">= 1.0.0"` to match every other module. The
`aws >= 6.0.0` schema is the authority for complete attribute coverage below.

## 2. Non-goals
- No changes to any existing module, shared local, or `global/` caller.
- No inline creation of cross-cutting resources (IAM roles/policies, KMS keys,
  security groups, VPC/subnets, EFS, S3 buckets). Per `AGENTS.md` §2 these are the
  caller's responsibility and are passed in by ARN/ID. Callers needing them use
  the existing `modules/aws/iam/role`, `modules/aws/kms`, `modules/aws/security_group`,
  etc. This includes the IAM execution role required by SageMaker.
- No SageMaker resources beyond domain and user profile (spaces, apps, images,
  app-image-configs, model/endpoint resources, MLflow, feature groups, etc.).
- No other Glue resources (crawler, job, catalog table, connection, trigger,
  registry, etc.).
- No per-resource `region` argument. Although `aws >= 6.0.0` exposes a
  resource-level `region` meta-argument, existing modules (e.g. `athena/workgroup`)
  deliberately omit it and rely on provider configuration; these modules follow
  that convention. This omission is intentional and documented, not silent.
- Single Terraform-block-per-call interface (one database, one domain, one user
  profile per module invocation), matching the `athena/workgroup` precedent.
  Bulk/`for_each` scaling is discussed in §9 (Open questions).

## 3. Affected module path(s)
- `modules/aws/glue/catalog_database/` (new)
- `modules/aws/sagemaker/domain/` (new)
- `modules/aws/sagemaker/user_profile/` (new)

Each new module contains exactly four files: `main.tf`, `variables.tf`,
`outputs.tf`, `README.md` (copied from `modules/module_template/`).

## 4. Proposed design
**Signatures only — no full implementations.** Variable/output names, types,
descriptions, and resource block names are listed. Deeply nested SageMaker
`*_app_settings` blocks are shown one level deep and typed `optional(any)` at the
spec altitude; the implementation MUST expose the full nested attribute tree from
the `aws >= 6.0.0` schema (see provider docs linked in §9). No leaf argument
supported by the provider resource may be silently dropped (`AGENTS.md` §1).

Shared conventions for all three modules:
- `main.tf` opens with the standard `terraform {}` block: `required_version = ">= 1.0.0"`,
  `aws` provider `source = "hashicorp/aws"`, `version = ">= 6.0.0"`.
- Single resource named `this`.
- Tagging follows `AGENTS.md`: `tags = merge(tomap({ Name = <name-var> }), var.tags)`.
- Section headers use the `###########################` comment banner style.

### 4a. `modules/aws/glue/catalog_database`
Resource: `aws_glue_catalog_database.this`.

#### `variables.tf`
- `name` (string, Required) — database name; validate lowercase letters, numbers,
  and underscores only.
- `catalog_id` (string, default `null`) — Glue catalog ID; provider defaults to
  the current AWS account ID when null.
- `description` (string, default `null`) — database description.
- `location_uri` (string, default `null`) — physical location of the database.
- `parameters` (map(string), default `{}`) — key/value database properties.
- `create_table_default_permission` (object, default `null`) — one level:
  `permissions` (list(string)) and `principal` (object with
  `data_lake_principal_identifier` (string)).
- `federated_database` (object, default `null`) — `connection_name` (string),
  `identifier` (string).
- `target_database` (object, default `null`) — resource-link target:
  `catalog_id` (string, required), `database_name` (string, required),
  `region` (string, optional).
- `tags` (map(string), default `{}`).

#### `outputs.tf`
- `id` — catalog ID and name of the database.
- `name` — database name.
- `arn` — ARN of the Glue catalog database.
- `catalog_id` — catalog ID the database lives in.

#### `main.tf`
Single `aws_glue_catalog_database.this` with `dynamic` blocks for the optional
`create_table_default_permission` (nested `principal`), `federated_database`, and
`target_database` configuration blocks, gated on their variable being non-null.

### 4b. `modules/aws/sagemaker/domain`
Resource: `aws_sagemaker_domain.this`.

#### `variables.tf`
Top-level scalars / lists:
- `domain_name` (string, Required).
- `auth_mode` (string, Required) — validate one of `IAM`, `SSO`.
- `vpc_id` (string, Required).
- `subnet_ids` (list(string), Required).
- `kms_key_id` (string, default `null`) — CMK for the domain EFS volume.
- `app_network_access_type` (string, default `"VpcOnly"`) — validate
  `PublicInternetOnly` or `VpcOnly`. Secure-by-default deviates from the provider
  default of `PublicInternetOnly` (`AGENTS.md` §3; see §6/§9).
- `app_security_group_management` (string, default `null`) — validate `Service`
  or `Customer` when set.
- `tag_propagation` (string, default `"DISABLED"`) — validate `ENABLED`/`DISABLED`.
- `tags` (map(string), default `{}`).

Nested configuration blocks (object-typed variables; `execution_role` required
inside user settings):
- `default_user_settings` (object, Required) — must include `execution_role`
  (string, required) plus optional `security_groups` (list(string)),
  `auto_mount_home_efs` (string), `default_landing_uri` (string),
  `studio_web_portal` (string), `sharing_settings` (object:
  `notebook_output_option`, `s3_kms_key_id`, `s3_output_path`),
  `space_storage_settings`, `custom_posix_user_config`, `custom_file_system_config`,
  and the app-settings blocks `canvas_app_settings`, `code_editor_app_settings`,
  `jupyter_lab_app_settings`, `jupyter_server_app_settings`,
  `kernel_gateway_app_settings`, `r_session_app_settings`,
  `r_studio_server_pro_app_settings`, `tensor_board_app_settings`,
  `studio_web_portal_settings` (each `optional(any)` at spec altitude; fully typed
  in implementation).
- `default_space_settings` (object, default `null`) — `execution_role` plus the
  space-scoped subset of the app-settings blocks above.
- `domain_settings` (object, default `null`) — `security_group_ids`
  (list(string)), `execution_role_identity_config` (string),
  `docker_settings`, `r_studio_server_pro_domain_settings`,
  `amazon_q_settings` (each `optional(...)`).
- `retention_policy` (object, default `null`) — `home_efs_file_system` (string,
  validate `Retain`/`Delete`).

#### `outputs.tf`
- `id` — domain ID.
- `arn` — domain ARN.
- `url` — domain login URL.
- `home_efs_file_system_id` — EFS file system ID backing the domain.
- `security_group_id_for_domain_boundary` — domain-boundary security group ID.
- `single_sign_on_managed_application_instance_id` — SSO managed app instance ID.
- `single_sign_on_application_arn` — IAM Identity Center application ARN.

Note: the issue asked for `domain_id` / `domain_arn`; this spec names them `id` /
`arn` to match the repo output convention (see `athena/workgroup`).

#### `main.tf`
Single `aws_sagemaker_domain.this`. `default_user_settings` is a required nested
block; `default_space_settings`, `domain_settings`, and `retention_policy` are
emitted via `dynamic` blocks gated on non-null variables, each with `dynamic`
sub-blocks for their nested settings.

### 4c. `modules/aws/sagemaker/user_profile`
Resource: `aws_sagemaker_user_profile.this`.

#### `variables.tf`
- `domain_id` (string, Required).
- `user_profile_name` (string, Required).
- `single_sign_on_user_identifier` (string, default `null`) — only valid when the
  domain `auth_mode` is `SSO`; validate value `UserName` when set.
- `single_sign_on_user_value` (string, default `null`) — required by the provider
  when the domain is SSO; must be null for IAM domains.
- `user_settings` (object, default `null`) — same shape as the domain's
  `default_user_settings` (`execution_role` plus `security_groups`,
  `sharing_settings`, and the per-app settings blocks; deep blocks `optional(any)`
  at spec altitude, fully typed in implementation).
- `tags` (map(string), default `{}`).

#### `outputs.tf`
- `id` — user profile ID/ARN.
- `arn` — user profile ARN.
- `user_profile_name` — user profile name.
- `home_efs_file_system_uid` — user's EFS UID within the domain.

#### `main.tf`
Single `aws_sagemaker_user_profile.this` with a `dynamic "user_settings"` block
(and nested `dynamic` sub-blocks) gated on `var.user_settings != null`, plus
optional `single_sign_on_user_identifier` / `single_sign_on_user_value`.

## 5. Breaking-change assessment
- **Breaking: no.** All three are net-new modules under new paths
  (`modules/aws/glue/`, `modules/aws/sagemaker/`). They add no changes to existing
  modules, shared locals, or `global/` callers, and there is nothing for existing
  callers to migrate. Under the repo's Conventional-Commit release rules this is a
  `feat:` → MINOR bump.

## 6. Checkov / tfsec considerations
- **New suppressions: none anticipated.** The modules create no S3 buckets, KMS
  keys, IAM policies, or security groups inline, so the security checks that most
  often require suppression do not apply here. Encryption and network posture are
  driven by caller-supplied variables (`kms_key_id`, `app_network_access_type`,
  `subnet_ids`, security-group IDs).
- If a Checkov policy flags a SageMaker/Glue argument that is intentionally
  caller-controlled (e.g. a domain-level KMS/network check that cannot evaluate a
  dynamic value), add a documented inline `#trivy:ignore` / `#checkov:skip`
  comment in the same style as `athena/workgroup/main.tf`, and record the rationale
  in `.checkov.yaml` if it must be global. Prefer secure defaults over suppression.
- **Existing suppressions affected: none.**

## 7. terraform-docs impact
- Three brand-new `README.md` files, each with a populated
  `<!-- BEGIN_TF_DOCS --> … <!-- END_TF_DOCS -->` block generated by
  `terraform-docs` (run locally via pre-commit or per-module inject).
- No existing module README changes. The `Verify - terraform-docs` CI job will
  fail if the three new READMEs are not regenerated and committed, so the
  implementation PR must run terraform-docs before pushing.

## 8. Testing
Per new module `<path>`:
- `tofu -chdir=<path> init -backend=false && tofu -chdir=<path> validate`
  (Terraform equivalents also acceptable).
- `tofu fmt -check -diff -recursive` (repo-wide formatting gate).
- `terraform-docs markdown table --output-file README.md --output-mode inject <path>`
  and confirm no diff remains (matches the `build.yml` check).
- `checkov -d <path>` locally to confirm no new findings.
- Manual review: cross-check every variable and output against the `aws >= 6.0.0`
  provider schema for the three resources to confirm complete coverage (`AGENTS.md` §1).

## 9. Open questions
- **Bulk / scalable input (`AGENTS.md` §5).** Glue databases and SageMaker user
  profiles can logically scale to many instances. This spec proposes
  single-instance interfaces (matching the `athena/workgroup` precedent) with
  callers using `for_each` on the module block. Should `catalog_database` and/or
  `user_profile` instead accept a `map(object({...}))` input (with map-shaped
  outputs)? The SageMaker domain is one-per-account/region (like a VPC) and stays
  single-instance regardless. Resolve before merge.
- **`app_network_access_type` default.** This spec defaults to the more secure
  `VpcOnly`; the provider default is `PublicInternetOnly`. `VpcOnly` requires the
  caller to supply routable subnets/endpoints. Confirm the secure default is
  acceptable or revert to the provider default.
- **Depth of typed nesting.** Confirm reviewers accept fully-typed
  `optional(object({...}))` for the SageMaker `*_app_settings` blocks in the
  implementation (the spec abstracts the deepest levels as `optional(any)` for
  readability). Reference schemas:
  [`aws_glue_catalog_database`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database),
  [`aws_sagemaker_domain`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_domain),
  [`aws_sagemaker_user_profile`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_user_profile).

## 10. Acceptance criteria
- Three new modules exist at the paths in §3, each with `main.tf`, `variables.tf`,
  `outputs.tf`, and `README.md` derived from `modules/module_template/`.
- Every argument of the underlying `aws >= 6.0.0` resource is exposed as an input
  variable (with a safe default where one exists), and every useful attribute is
  exposed as an output — no silent omissions (`AGENTS.md` §1).
- No cross-cutting resources (IAM, KMS, security groups, EFS, S3, VPC/subnets) are
  declared inline; such dependencies are inputs supplied by the caller (`AGENTS.md` §2).
- Secure-by-default posture where the resource supports it (encryption via
  caller-supplied `kms_key_id`, `VpcOnly` network default for the domain), with
  input `validation` blocks on constrained enums (`auth_mode`,
  `app_network_access_type`, `tag_propagation`, `retention_policy.home_efs_file_system`,
  Glue `name` charset).
- Tagging uses `merge(tomap({ Name = <name-var> }), var.tags)`.
- Each `README.md` has a description, prerequisites (pre-provisioned VPC/subnets,
  IAM execution role, optional KMS key), at least one complete `module {}` usage
  example, a notes/design-decisions section, and a regenerated terraform-docs block.
- `tofu fmt -check`, per-module `validate`, and terraform-docs verification all
  pass in CI.
- Change is additive and non-breaking (§5).
