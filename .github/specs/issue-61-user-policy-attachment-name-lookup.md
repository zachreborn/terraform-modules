# Spec: IAM Policy Attachment - Lookups for built-in policies
**Issue:** #61
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The `modules/aws/iam/user_policy_attachment/` module currently requires the
caller to supply the exact `policy_arn` of the policy to attach. For AWS
managed (built-in) policies this forces callers to know and hardcode an ARN
such as `arn:aws:iam::aws:policy/AWSApplicationDiscoveryAgentAccess`. That is
error-prone (an ARN typo silently fails to match), and inconsistent with the
human-readable policy names shown in the AWS console and AWS documentation.

The AWS provider exposes the `aws_iam_policy` data source, which resolves a
policy ARN from its `name`. This feature extends the module with an optional
name-based lookup path alongside the existing direct-ARN path, so callers can
write:

```hcl
module "example_user_policy" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/user_policy_attachment"

  policy_name = "AWSApplicationDiscoveryAgentAccess"
  user        = module.migration_evaluator_collector.user_name
}
```

instead of supplying the full ARN. The current `main.tf` defines a single
`aws_iam_user_policy_attachment.this` resource consuming `var.policy_arn`
directly; see `modules/aws/iam/user_policy_attachment/main.tf:19`.

Originating issue: #61.

## 2. Non-goals
- No new module is created. This is an additive enhancement to the existing
  `user_policy_attachment` module only.
- No change to the `user` input contract.
- No multi-attachment / `for_each` / YAML-map scaling of this module. Attaching
  many policies or covering many users in one module call is out of scope and
  can be a separate future enhancement.
- No `aws_iam_role_policy_attachment` or `aws_iam_group_policy_attachment`
  equivalents — this spec covers user attachment only.
- No `path_prefix` disambiguation for the lookup data source in the initial
  implementation (see Open questions).

## 3. Affected module path(s)
- `modules/aws/iam/user_policy_attachment/` (existing)
  - `main.tf` — add a conditional data source + a local; rewire the existing
    resource to consume the resolved ARN; add a mutual-exclusivity
    `precondition`.
  - `variables.tf` — make `policy_arn` optional; add `policy_name`.
  - `outputs.tf` — currently empty; add the resolved-ARN output.
  - `README.md` — refresh the usage example and the auto-generated
    terraform-docs block.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
- `user`
  - type: `string`
  - required (no default) — unchanged
  - description: the IAM username the policy is attached to.
- `policy_arn`
  - type: `string`
  - default: `null` (changed from required to optional)
  - description: direct ARN of the policy to attach. Mutually exclusive with
    `policy_name`.
- `policy_name`
  - type: `string`
  - default: `null` (new)
  - description: name of an AWS managed or customer-managed policy to look up
    via the `aws_iam_policy` data source and attach. Mutually exclusive with
    `policy_arn`.

Mutual exclusivity (exactly one of `policy_arn` / `policy_name` must be set) is
enforced in `main.tf` via a resource `precondition` rather than a variable
`validation` block, because the check spans two variables. Cross-variable
references inside a variable `validation` block require OpenTofu >= 1.8 /
Terraform >= 1.9, which exceeds this module's `required_version = ">= 1.0.0"`;
the `precondition` approach matches the established repo pattern (see
`modules/aws/cloudwatch/log_group/main.tf:36`) and needs no version bump.

### `outputs.tf`
- `policy_arn` — the resolved ARN actually attached (from the `policy_name`
  lookup or the `policy_arn` passthrough).
- `id` (recommended, additive) — the `aws_iam_user_policy_attachment.this` ID,
  surfaced to satisfy the repo's complete-resource-coverage convention in
  `AGENTS.md`. The issue requires only `policy_arn`; `id` is a non-breaking
  addition. Final inclusion is for CODEOWNERS to confirm (see Open questions).

### `main.tf`
- `terraform {}` block — unchanged (`required_version = ">= 1.0.0"`,
  `aws >= 6.0.0`).
- `data "aws_iam_policy" "lookup"` — new. Conditional via
  `count = var.policy_name != null ? 1 : 0`, looking the policy up by `name`.
  Only evaluated when `policy_name` is supplied.
- `locals` — new `resolved_arn`, selecting the effective ARN from whichever
  input path is used (the `policy_arn` passthrough or the looked-up ARN).
- `resource "aws_iam_user_policy_attachment" "this"` — unchanged structurally
  except `policy_arn` now consumes `local.resolved_arn` instead of
  `var.policy_arn`. A `lifecycle { precondition { ... } }` enforces that
  exactly one of `policy_arn` / `policy_name` is non-null, with a clear error
  message when neither or both are set (XOR check mirroring
  `modules/aws/cloudwatch/log_group/main.tf:38`).

No tagging is involved (the attachment resource is not taggable), so the
`merge(tomap({ Name = ... }), var.tags)` convention does not apply here.

## 5. Breaking-change assessment
- Breaking: **no.**
- `policy_arn` moves from required to optional (`null` default). Existing
  callers that pass `policy_arn` explicitly continue to work unchanged; the
  `policy_name` path and the new output are purely additive.
- Bump type: **MINOR** (`feat:` per Conventional Commits).

## 6. Checkov / tfsec considerations
- New suppressions: **none.** Adding an `aws_iam_policy` data source and an
  IAM user policy attachment introduces no new findings that require
  suppression. Policy permissiveness remains the caller's responsibility,
  consistent with the library's security-posture philosophy in `AGENTS.md`.
- Existing suppressions affected: **none.**

## 7. terraform-docs impact
Yes — the `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/iam/user_policy_attachment/README.md` will change:
- Resources: add `data.aws_iam_policy.lookup` (data source).
- Inputs: `policy_arn` becomes optional (Required `no`, Default `null`); add
  `policy_name`; `user` unchanged.
- Outputs: changes from "No outputs." to list `policy_arn` (and `id` if
  adopted).
The hand-written usage example above the docs block will also be updated to
show both the `policy_name` and `policy_arn` invocation patterns. Docs must be
regenerated locally (pre-commit or `terraform-docs ... <module_path>`); CI only
verifies the committed output.

## 8. Testing
- `tofu -chdir=modules/aws/iam/user_policy_attachment init -backend=false && tofu -chdir=modules/aws/iam/user_policy_attachment validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/iam/user_policy_attachment` (locally; CI runs on schedule)
- `pre-commit run --all-files` (fmt + terraform-docs hooks green)
- Module-specific checks:
  - With only `policy_arn` set: plan succeeds; no data source is read.
  - With only `policy_name` set: data source is read; `resolved_arn` equals the
    looked-up ARN.
  - With neither set: the `precondition` fails with the documented error.
  - With both set: the `precondition` fails with the documented error.

## 9. Open questions
- Should `id` (and optionally `user`) be surfaced as outputs for
  complete-resource-coverage, or should outputs be limited to the
  issue-required `policy_arn`? Default recommendation: include `policy_arn` and
  `id`.
- Should the `aws_iam_policy` lookup expose an optional `path_prefix` to
  disambiguate customer-managed policies that share a name across paths?
  Default recommendation: defer (non-goal for this iteration).

## 10. Acceptance criteria
- [ ] `policy_name` input variable added with type `string`, default `null`, and
  a clear description noting it accepts any AWS or customer-managed policy name
  visible in IAM.
- [ ] `policy_arn` input variable changed to optional (default `null`).
- [ ] A `precondition` (or `validation`) enforces that exactly one of
  `policy_arn` / `policy_name` is non-null, with a clear error message when
  neither or both are set.
- [ ] `data "aws_iam_policy" "lookup"` data source added with a `count`
  conditional; only invoked when `policy_name` is set.
- [ ] `local.resolved_arn` correctly selects the ARN from whichever input path
  is used.
- [ ] `policy_arn` output added, returning the resolved ARN.
- [ ] `aws_iam_user_policy_attachment.this` uses `local.resolved_arn` (no
  functional change for the existing ARN path).
- [ ] `tofu fmt -recursive` passes with no diff.
- [ ] `tofu -chdir=modules/aws/iam/user_policy_attachment init -backend=false && tofu -chdir=modules/aws/iam/user_policy_attachment validate` passes.
- [ ] `terraform-docs` regenerated and committed (README reflects new variables
  and outputs).
- [ ] Usage example in README updated to show both the `policy_name` and
  `policy_arn` invocation patterns.
- [ ] `pre-commit run --all-files` passes (fmt + terraform-docs hooks green).
