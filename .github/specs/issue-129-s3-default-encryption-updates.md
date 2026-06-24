# Spec: S3 Default Encryption Updates
**Issue:** #129
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
S3 has applied server-side encryption (SSE-S3 / AES-256) to all new object
uploads by default since January 5, 2023, and AWS has since introduced
additional encryption capabilities that the `modules/aws/s3/bucket/` module does
not yet expose. See the originating issue #129 and the AWS reference:
https://docs.aws.amazon.com/AmazonS3/latest/userguide/default-encryption-faq.html

Four misalignments exist today between the module and the current AWS S3
encryption landscape:

1. **Missing `aws:kms:dsse` support.** The `sse_algorithm` variable validation
   (`modules/aws/s3/bucket/variables.tf:326`) only accepts `AES256` and
   `aws:kms`. AWS added Dual-Layer Server-Side Encryption with KMS keys
   (`aws:kms:dsse`) in 2023 and the provider accepts it; the validation regex
   must be widened.
2. **Deprecated `expected_bucket_owner` on the encryption resource.** The
   argument on `aws_s3_bucket_server_side_encryption_configuration`
   (`modules/aws/s3/bucket/main.tf:237`) is deprecated in `aws >= 6.0.0`. It
   should be removed from the encryption resource only; it remains valid on
   `aws_s3_bucket_lifecycle_configuration` (`main.tf:101`) and
   `aws_s3_bucket_versioning` (`main.tf:279`), which keep the variable.
3. **No `blocked_encryption_types` support.** The provider added a
   `blocked_encryption_types` argument to
   `aws_s3_bucket_server_side_encryption_configuration`. Starting April 2026 AWS
   automatically blocks SSE-C for new buckets. The module exposes no variable
   for this, so callers cannot manage it via Terraform.
4. **Ambiguous `bucket_key_enabled` default.** The variable
   (`modules/aws/s3/bucket/variables.tf:316`) defaults to `true`, which is only
   meaningful for SSE-KMS (`aws:kms` / `aws:kms:dsse`). When
   `sse_algorithm = "AES256"` the setting has no effect but still surfaces in
   plans.

The default `sse_algorithm` of `aws:kms` (with `enable_kms_key = false`, i.e.
the AWS-managed `aws/s3` key) is intentionally retained: it provides a
CloudTrail audit trail and a posture consistent with CIS benchmarks. The README
will document this rationale.

## 2. Non-goals
- Changing the default `sse_algorithm` value (remains `aws:kms`).
- Changing the default `enable_kms_key` value (remains `false`).
- Any change to `modules/aws/s3/access_log_bucket/`, which already correctly
  uses `AES256` and is explicitly out of scope.
- Adding or changing any module outputs.
- Refactoring the inline KMS key resources out of the bucket module (tracked
  separately under the composition rule in `AGENTS.md`).

## 3. Affected module path(s)
- `modules/aws/s3/bucket/` (existing) — `variables.tf`, `main.tf`, `README.md`.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Add one new variable:
- `blocked_encryption_types` — `list(string)`, default `["SSE-C"]`. List of
  encryption types to block on object uploads. Valid values: `SSE-C`, `NONE`.
  Includes a validation that each element is one of `SSE-C` or `NONE`. Defaults
  to blocking SSE-C to align with the April 2026 AWS enforcement; callers may
  set `[]` or `["NONE"]` to opt out.

Modify one existing variable:
- `sse_algorithm` — keep `type = string`, keep `default = "aws:kms"`. Widen the
  validation regex (currently `AES256|aws:kms`) to also accept `aws:kms:dsse`
  with an anchored pattern (e.g. `^(AES256|aws:kms|aws:kms:dsse)$`) and update
  the description and error message to list all three values.
- `bucket_key_enabled` — unchanged signature (`bool`, default `true`); update
  only the description to note it is ignored when `sse_algorithm = "AES256"` and
  that the module derives an effective value internally (see `main.tf`).

`expected_bucket_owner` remains declared (still consumed by the lifecycle and
versioning resources); no signature change.

### `outputs.tf`
No changes. All existing outputs remain unchanged.

### `main.tf`
- Add a local, e.g. `bucket_key_enabled`, in the existing `locals` block that
  resolves to `false` when `var.sse_algorithm == "AES256"` and otherwise to
  `var.bucket_key_enabled`.
- `aws_s3_bucket_server_side_encryption_configuration.this`:
  - Remove the `expected_bucket_owner = var.expected_bucket_owner` argument.
  - Add `blocked_encryption_types = var.blocked_encryption_types` to the `rule`
    block.
  - Reference the new local for `bucket_key_enabled` instead of the variable
    directly.
- No `count`/`for_each`, lifecycle ignore, or tagging changes. The
  `expected_bucket_owner` argument is retained on
  `aws_s3_bucket_lifecycle_configuration.this` and `aws_s3_bucket_versioning.this`.

## 5. Breaking-change assessment
- Breaking: yes — minor scope. No MAJOR bump required because no required
  variable and no default (`sse_algorithm`, `enable_kms_key`) changes; a MINOR
  bump (`feat:`) is appropriate.
- Migration notes for callers:
  - The new `blocked_encryption_types` default `["SSE-C"]` denies SSE-C object
    uploads after the update. Callers relying on SSE-C (rare) must set
    `blocked_encryption_types = []` (or `["NONE"]`) to opt out. AWS enforces the
    same block automatically from April 2026.
  - Removing `expected_bucket_owner` from the encryption resource may produce a
    one-time plan diff on next apply but causes no functional regression (the
    argument is deprecated and ignored by the provider on that resource).
  - The effective `bucket_key_enabled` local eliminates spurious plan diffs for
    `AES256` buckets and changes no externally visible interface.

## 6. Checkov / tfsec considerations
- New suppressions: none. The changes strengthen or maintain the encryption
  posture (DSSE support, SSE-C blocking) and do not introduce a new security
  finding requiring suppression.
- Existing suppressions affected: none.

## 7. terraform-docs impact
Yes. The auto-generated `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/s3/bucket/README.md` will change: the new
`blocked_encryption_types` input row is added, and the `sse_algorithm` /
`bucket_key_enabled` description text updates. `terraform-docs` must be
regenerated for `modules/aws/s3/bucket/` and committed. No other module's docs
change.

## 8. Testing
- `tofu -chdir=modules/aws/s3/bucket init -backend=false && tofu -chdir=modules/aws/s3/bucket validate`
  (Terraform equivalents are also acceptable).
- `tofu fmt -check -diff -recursive` passes with no diffs.
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/s3/bucket`
  produces no uncommitted diff (or run `pre-commit run --all-files`).
- `checkov -d modules/aws/s3/bucket` (locally; CI runs on schedule) reports no
  new findings.
- Manual validation: confirm `tofu validate` accepts
  `sse_algorithm = "aws:kms:dsse"` and that an `AES256` plan no longer surfaces
  a `bucket_key_enabled = true` change.

## 9. Open questions
- None blocking. Validation of `blocked_encryption_types` element values
  (`SSE-C`, `NONE`) follows the current provider-accepted set; if the provider
  later expands the accepted values, the validation regex can be widened in a
  follow-up.

## 10. Acceptance criteria
- [ ] `sse_algorithm` validation accepts `aws:kms:dsse` in addition to `AES256`
  and `aws:kms`, and its description/error message lists all three.
- [ ] A `blocked_encryption_types` variable exists with default `["SSE-C"]`,
  validates against `SSE-C`/`NONE`, and is wired into the `rule` block of
  `aws_s3_bucket_server_side_encryption_configuration`.
- [ ] `expected_bucket_owner` is removed from the
  `aws_s3_bucket_server_side_encryption_configuration` resource block (and
  retained on the lifecycle and versioning resources).
- [ ] A local resolves the effective `bucket_key_enabled` to `false` when
  `sse_algorithm = "AES256"` to eliminate spurious plan diffs.
- [ ] `tofu fmt -recursive` passes with no diffs.
- [ ] `terraform-docs` is regenerated for `modules/aws/s3/bucket/` and committed.
- [ ] `tofu validate` passes for `modules/aws/s3/bucket/`.
- [ ] README documents the security rationale for keeping `aws:kms`
  (AWS-managed key) as the default `sse_algorithm` and notes the
  `blocked_encryption_types` behavior.
