# Spec: bug(cloudwatch/log_destination): make the module compile
**Issue:** #388
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/cloudwatch/log_destination` does not compile. `variables.tf` and
`outputs.tf` are both empty (0 bytes), yet `main.tf` references thirteen
undeclared input variables and two undeclared resources:

- **Undeclared variables** referenced in `main.tf`:
  `destination_policy_access_policy`, `iam_policy_description`,
  `iam_policy_name_prefix`, `iam_policy_path`, `tags`,
  `iam_role_assume_role_policy`, `iam_role_description`,
  `iam_role_force_detach_policies`, `iam_role_max_session_duration`,
  `iam_role_name_prefix`, `iam_role_permissions_boundary`, `destination_name`,
  `destination_target_arn`.
- **`aws_s3_bucket.firehose_bucket`** is referenced in the
  `aws_iam_policy.firehose_policy` document (`main.tf` lines 36-37) but never
  declared.
- **`aws_iam_role.iam_for_cloudwatch`** is referenced by
  `aws_cloudwatch_log_destination.this.role_arn` (`main.tf` line 69), but the
  role that the module actually declares is `aws_iam_role.firehose_role`.

Running `tofu init -backend=false && tofu validate` in the module directory
fails with `Reference to undeclared resource` and `Reference to undeclared
input variable` errors.

The module's intent is to manage an [`aws_cloudwatch_log_destination`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination)
(a cross-account CloudWatch Logs subscription target) plus its companion
[`aws_cloudwatch_log_destination_policy`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_destination_policy).
The half-written IAM role, IAM policy, and S3 bucket references are
cross-cutting resources that, per `AGENTS.md` § 2 (Module Composition — No
Inline Cross-Cutting Resources), do not belong inline in this module. The fix
makes the module a focused leaf module for the two log-destination resources
and accepts the IAM role ARN and target ARN from the caller.

See: https://github.com/zachreborn/terraform-modules/issues/388

## 2. Non-goals
- Declaring an IAM role, IAM policy, or S3 bucket inside this module. Those are
  cross-cutting concerns owned by `modules/aws/iam/role`,
  `modules/aws/iam/policy`, and `modules/aws/s3/bucket` respectively (see
  `AGENTS.md` § 2). The caller wires the role ARN and target ARN into this
  module.
- Adding a Kinesis Firehose delivery stream or any delivery-pipeline resource.
- Converting the module to a map/`for_each` (`AGENTS.md` § 5) multi-instance
  interface. This bug fix keeps the existing single-resource shape; a scalable
  map input can be a follow-up feature.
- Changing the `terraform {}` / `required_providers` block (already correct:
  `required_version = ">= 1.0.0"`, `aws >= 6.0.0`).

## 3. Affected module path(s)
- `modules/aws/cloudwatch/log_destination/` (existing) — `main.tf`,
  `variables.tf`, `outputs.tf`, `README.md`, and a new `tests/` directory.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Declare the following variables (all currently missing). Names for the two
resources' arguments are kept aligned with the existing `main.tf` references
where they already exist (`destination_name`, `destination_target_arn`,
`destination_policy_access_policy`) and a new `destination_role_arn` is added
to replace the broken `aws_iam_role.iam_for_cloudwatch.arn` reference.

- `destination_name` — `string`, required. Name of the log destination.
- `destination_target_arn` — `string`, required. ARN of the physical target the
  destination delivers to (e.g. a Kinesis stream or Firehose delivery stream).
- `destination_role_arn` — `string`, required. ARN of the IAM role that grants
  CloudWatch Logs permission to write to `destination_target_arn`. Supplied by
  the caller (e.g. from `modules/aws/iam/role`).
- `destination_policy_access_policy` — `string`, default `null`. The
  cross-account access policy (JSON) attached via
  `aws_cloudwatch_log_destination_policy`. When `null`, no destination policy
  resource is created.
  - `validation { ... }`: when non-null, the value must be parseable JSON —
    `can(jsondecode(var.destination_policy_access_policy))`.
- `destination_policy_force_update` — `bool`, default `null`. Maps to the
  `force_update` argument of `aws_cloudwatch_log_destination_policy`.
- `tags` — `map(string)`, default `{}`. Merged with a computed `Name` tag per
  the repo tagging convention.

### `outputs.tf`
Currently empty. Add:

- `arn` — `aws_cloudwatch_log_destination.this.arn`. The ARN of the log
  destination (used by other accounts as the `destination_arn` of a
  subscription filter).
- `name` — `aws_cloudwatch_log_destination.this.name`.
- `id` — `aws_cloudwatch_log_destination.this.id`.
- `access_policy` — the effective access policy, sourced from the destination
  policy resource when created (guarded for the `count = 0` case), else `null`.

### `main.tf`
Keep the `terraform {}` block unchanged. Resources:

- `aws_cloudwatch_log_destination.this` — arguments `name =
  var.destination_name`, `role_arn = var.destination_role_arn` (replacing the
  broken `aws_iam_role.iam_for_cloudwatch.arn`), `target_arn =
  var.destination_target_arn`, and `tags = merge(tomap({ Name =
  var.destination_name }), var.tags)`.
- `aws_cloudwatch_log_destination_policy.this` — created conditionally with
  `count = var.destination_policy_access_policy != null ? 1 : 0`. Arguments:
  `destination_name = aws_cloudwatch_log_destination.this.name`, `access_policy
  = var.destination_policy_access_policy`, `force_update =
  var.destination_policy_force_update`.

**Remove** the following inline blocks (they reference undeclared
variables/resources and violate `AGENTS.md` § 2): `aws_iam_policy.firehose_policy`,
`aws_iam_role.firehose_role`, and `aws_iam_role_policy_attachment.role_attach`.
No `aws_s3_bucket` resource is declared. No lifecycle-ignore rules are needed.

## 5. Breaking-change assessment
- Breaking: **no (in practice)**. The module has never compiled in its current
  form — `variables.tf` and `outputs.tf` are empty — so there are no working
  callers to break. There is no released, functioning interface to preserve.
- Interface note for anyone who copied the draft: the IAM role, IAM policy, and
  S3 bucket are no longer created inside the module. Callers must now provision
  the IAM role separately (via `modules/aws/iam/role`) and pass its ARN through
  the new required `destination_role_arn` variable, and pass the delivery target
  ARN through `destination_target_arn`.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. The module manages only
  `aws_cloudwatch_log_destination` and `aws_cloudwatch_log_destination_policy`;
  the access-policy content is caller-supplied, so no least-privilege check is
  triggered by the module itself.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
Yes. The `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/cloudwatch/log_destination/README.md` currently lists five
resources (including `aws_iam_policy.firehose_policy`,
`aws_iam_role.firehose_role`, `aws_iam_role_policy_attachment.role_attach`) and
"No inputs / No outputs". After the fix it must be regenerated to show two
resources (`aws_cloudwatch_log_destination.this`,
`aws_cloudwatch_log_destination_policy.this`), the new Inputs table, and the new
Outputs table. The implementation must also replace the placeholder Usage
example and `module_name`/`module_description` boilerplate with a real usage
block per `AGENTS.md` § 4. Regenerate locally with
`terraform-docs markdown table --output-file README.md --output-mode inject
modules/aws/cloudwatch/log_destination` (or `pre-commit run --all-files`); CI
only verifies the committed output.

## 8. Testing
- `tofu -chdir=modules/aws/cloudwatch/log_destination init -backend=false && tofu -chdir=modules/aws/cloudwatch/log_destination validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/cloudwatch/log_destination` (locally; CI runs on schedule)
- Native `tofu test` plan (required — `AGENTS.md` § 6). Add a `tests/` directory
  (start from `modules/module_template/tests/`) whose cases run offline via
  `mock_provider "aws"` with `mock_resource` blocks for
  `aws_cloudwatch_log_destination` and `aws_cloudwatch_log_destination_policy`
  (see `modules/aws/organizations/tests/` for the pattern). Required cases:
  - **Valid baseline** (`command = plan`): supply `destination_name`,
    `destination_role_arn`, `destination_target_arn`, and a valid-JSON
    `destination_policy_access_policy`. Assert
    `aws_cloudwatch_log_destination.this.name == var.destination_name` and
    `length(aws_cloudwatch_log_destination_policy.this) == 1`.
  - **Conditional branch — policy disabled**: omit
    `destination_policy_access_policy` (leave `null`) and assert
    `length(aws_cloudwatch_log_destination_policy.this) == 0`, exercising the
    other side of the `count` toggle.
  - **`expect_failures` — invalid access policy JSON**: set
    `destination_policy_access_policy` to a non-JSON string; assert
    `expect_failures = [var.destination_policy_access_policy]`, covering the one
    `validation { ... }` rule.
  - **Output assertions**: assert `output.arn`, `output.name`, and `output.id`
    are non-null in the valid baseline, and that `output.access_policy` is
    non-null when the policy is created and `null` when it is not.
  - Wiring assertions: **not applicable** — this is a leaf module that calls no
    submodules.
  Do not weaken any assertion, skip a case, or mock away the behavior under test
  to force a pass; fix the module code if a case fails.

## 9. Open questions
- Should `destination_policy_access_policy` be required rather than optional? A
  destination is only useful cross-account when a policy is attached, but making
  it optional (default `null`) keeps single-account/same-account uses valid and
  gives a clean `count` branch to test. This spec proposes optional; confirm at
  review.

## 10. Acceptance criteria
- [ ] `tofu -chdir=modules/aws/cloudwatch/log_destination init -backend=false`
      and `tofu ... validate` succeed with no "undeclared resource" or
      "undeclared input variable" errors.
- [ ] `variables.tf` declares every variable referenced by `main.tf`
      (`destination_name`, `destination_target_arn`, `destination_role_arn`,
      `destination_policy_access_policy`, `destination_policy_force_update`,
      `tags`), with types, descriptions, and safe defaults.
- [ ] `main.tf` references only declared resources — no
      `aws_s3_bucket.firehose_bucket`, and the destination's `role_arn` sources
      from `var.destination_role_arn` (no `aws_iam_role.iam_for_cloudwatch`).
- [ ] Inline IAM/S3 resources are removed (no cross-cutting resources inline per
      `AGENTS.md` § 2).
- [ ] `outputs.tf` exposes `arn`, `name`, `id`, and `access_policy`.
- [ ] A `tests/` directory ships the cases in § 8 and `tofu test` passes offline
      (via `mock_provider`) with no real credentials.
- [ ] `README.md` has a real usage example and a regenerated
      `<!-- BEGIN_TF_DOCS -->` block reflecting the new inputs, outputs, and
      resources.
- [ ] `tofu fmt -check -diff -recursive` passes.
