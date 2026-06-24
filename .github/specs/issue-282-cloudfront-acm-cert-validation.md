# Spec: feat(cloudfront): prevent ACM certificate race condition (validated-ARN contract + optional in-module validation wait)
**Issue:** #282
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The `modules/aws/cloudfront` module exposes `acm_certificate_arn` as a plain
`string` and wires it straight into the distribution's `viewer_certificate`
block (`modules/aws/cloudfront/main.tf:176`). `aws_cloudfront_distribution`
requires the referenced ACM certificate to be in `ISSUED` state at create time.

Because the input is an opaque string, the module cannot tell whether the
caller passed:
- the **raw** `aws_acm_certificate.x.arn` — which creates **no** implicit
  dependency on validation completing, so the apply races and fails with
  `InvalidViewerCertificate: The specified SSL certificate doesn't exist,
  isn't in us-east-1 region, isn't valid, or doesn't include a valid
  certificate chain.`, or
- the **validated** `aws_acm_certificate_validation.x.certificate_arn` — which
  carries an implicit dependency on the cert reaching `ISSUED`, so the apply is
  safe.

Today the only thing keeping the module safe is the caller remembering to pass
the validated ARN. That is an easy footgun. Issue #282 proposes two
complementary, non-DNS-owning changes to harden the module. DNS validation
records live in whatever zone the caller controls (Route 53 or external DNS),
so the module deliberately does **not** own DNS record creation under either
option.

This spec covers both options, with one maintainer-directed deferral: the
dedicated **required** `aws.acm` provider alias
(`configuration_aliases = [aws.acm]`) is postponed to the next major version
to keep this release non-breaking (see §5).

## 2. Non-goals
- **DNS validation record creation** (Route 53 or otherwise). The caller
  continues to own the CNAME/validation records in their own DNS zone.
- **Full cert-lifecycle ownership** (certificate + DNS records + validation)
  inside the module. Rejected because it only works for Route 53-managed zones
  and breaks for external DNS.
- **Introducing the `aws.acm` provider alias / `configuration_aliases`** in
  this release. Deferred to the next major version (see §5 and §9). In this
  release the gated validation resource uses the module's existing default
  `aws` provider.
- **Guaranteeing `ISSUED` at plan time.** Terraform cannot verify certificate
  state during plan; the Option 1 `precondition` is a guardrail that steers
  callers toward the correct pattern, not a proof.
- Changes to any other module or to CloudFront features unrelated to the viewer
  certificate.

## 3. Affected module path(s)
- `modules/aws/cloudfront/` (existing)
  - `variables.tf` — one tightened description + two new variables.
  - `main.tf` — one new gated resource, one `viewer_certificate` change, one
    added `precondition`. The in-file `terraform {}` block is **unchanged**
    this release.
  - `README.md` — new usage example + prerequisites note (terraform-docs block
    regenerated).
  - `outputs.tf` — no change (see §4).

Note on file layout: the issue's Option 2 snippet references a `versions.tf`
with `configuration_aliases`. This repository keeps the `terraform {}` block in
`main.tf` (four-file layout per `AGENTS.md` and `modules/module_template/`), and
the alias is deferred regardless, so **no `versions.tf` is added** and the
`terraform {}` block is not modified in this release.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Tighten one existing variable and add two new ones.

```hcl
# EXISTING — tighten description only (type/default unchanged)
variable "acm_certificate_arn" {
  description = "(Optional) The ARN of the ACM certificate for the distribution. The certificate must be in us-east-1. IMPORTANT: pass the certificate_arn from an aws_acm_certificate_validation resource (NOT the raw aws_acm_certificate arn) so CloudFront waits for the certificate to reach ISSUED state. Alternatively set wait_for_certificate_validation = true to have the module gate on validation internally."
  type        = string
  default     = null
}

# NEW
variable "wait_for_certificate_validation" {
  description = "(Optional) When true, the module creates an aws_acm_certificate_validation resource so the distribution waits for the certificate to reach ISSUED before creation. Requires acm_certificate_arn to be set. The module does not create DNS validation records; the caller must still create those in their own DNS zone. NOTE (this release): the validation resource uses the module's default aws provider, which must be configured for us-east-1 when this is true."
  type        = bool
  default     = false
  # validation: wait_for_certificate_validation == false || acm_certificate_arn != null
}

# NEW
variable "certificate_validation_timeout" {
  description = "(Optional) The create timeout for the aws_acm_certificate_validation resource when wait_for_certificate_validation is true."
  type        = string
  default     = "45m"
}
```

The `wait_for_certificate_validation` variable carries a `validation {}` block
enforcing `var.wait_for_certificate_validation == false || var.acm_certificate_arn != null`
with the error message `wait_for_certificate_validation = true requires acm_certificate_arn to be set.`

### `outputs.tf`
No new outputs. The only attribute `aws_acm_certificate_validation.this`
surfaces is `certificate_arn`, which equals the caller-supplied
`acm_certificate_arn` and is therefore not worth re-exposing. See §9 for the
open question on optionally surfacing a validation status output.

### `main.tf`
Resource block types and high-level relationships:

- `terraform {}` (existing, **unchanged**): keeps `aws = { source = "hashicorp/aws", version = ">= 6.0.0" }`. Per the maintainer deferral, **do not** add `configuration_aliases = [aws.acm]` in this release.
- `aws_acm_certificate_validation.this` (**new**, gated):
  - `count = var.wait_for_certificate_validation ? 1 : 0`.
  - Uses the module's **default `aws` provider** this release (no `provider = aws.acm`).
  - `certificate_arn = var.acm_certificate_arn`.
  - nested `timeouts { create = var.certificate_validation_timeout }`.
  - Creates no DNS records; it only polls until the caller's DNS records drive the cert to `ISSUED`.
- `aws_cloudfront_distribution.this` (existing) — two changes:
  - `viewer_certificate.acm_certificate_arn` changes from `var.acm_certificate_arn` to `try(aws_acm_certificate_validation.this[0].certificate_arn, var.acm_certificate_arn)`. The other `viewer_certificate` arguments (`cloudfront_default_certificate`, `iam_certificate_id`, `minimum_protocol_version`, `ssl_support_method`) are unchanged.
  - A **second `precondition`** is added to the existing `lifecycle {}` block (which already holds the OAC-name precondition at `modules/aws/cloudfront/main.tf:187`). Proposed condition:

    ```hcl
    precondition {
      condition = (
        var.acm_certificate_arn == null ||
        var.cloudfront_default_certificate ||
        var.iam_certificate_id != null ||
        var.wait_for_certificate_validation
      )
      error_message = "When using a custom ACM certificate, either set wait_for_certificate_validation = true, or pass acm_certificate_arn from an aws_acm_certificate_validation resource (not aws_acm_certificate) so CloudFront waits for ISSUED state."
    }
    ```

No `for_each`, tagging, or `lifecycle ignore_changes` changes are introduced
(`aws_acm_certificate_validation` does not take `tags`).

## 5. Breaking-change assessment
- **Default path: not breaking.** `wait_for_certificate_validation` defaults to
  `false`, the `try()` in `viewer_certificate` falls back to
  `var.acm_certificate_arn` when the gate is off, and no new required provider
  or alias is introduced (the `aws.acm` alias is deferred to the next major).
  Existing callers need no new providers or variables.
- **`aws.acm` alias deferred (non-breaking this release).** Per the maintainer
  decision recorded on the issue, `configuration_aliases = [aws.acm]` is **not**
  added now. The gated validation resource uses the module's existing default
  `aws` provider, which the README must document as needing to target
  `us-east-1` when `wait_for_certificate_validation = true`. The dedicated alias
  is reserved for the next major version bump.
- **Option 1 `precondition`: potentially breaking for a specific subset — must
  be reconciled before implementation (see §9).** The issue states the
  precondition is "backward compatible for any caller already passing a
  validated ARN." That claim does not hold as written: Terraform cannot
  distinguish a validated ARN (`aws_acm_certificate_validation.x.certificate_arn`)
  from a raw ARN (`aws_acm_certificate.x.arn`) at plan time — both are opaque
  strings. The proposed condition keys off the **variable flags**, not the
  ARN's provenance. Therefore an existing caller who today correctly passes a
  **validated** ARN but sets none of `cloudfront_default_certificate`,
  `iam_certificate_id`, or `wait_for_certificate_validation` will newly fail the
  precondition at plan time.
  - Impact: limited to callers using a custom ACM certificate (i.e.
    `acm_certificate_arn != null`) who validate externally and do not flip a
    flag. Callers using the CloudFront default cert or an IAM cert, and callers
    who set `wait_for_certificate_validation = true`, are unaffected.
  - Remediation if shipped as proposed: set `wait_for_certificate_validation = true`
    (creating the in-module wait), or adopt an explicit acknowledgment escape
    hatch if one is added per §9.
  - This means the breaking-change risk is **low but non-zero**, contrary to the
    triage note's "existing callers passing a validated ARN are unaffected."
    §9 proposes resolutions; the chosen resolution determines whether the final
    classification is "no" or "minor/plan-time with documented remediation."

## 6. Checkov / tfsec considerations
- **New suppressions: none.** `aws_acm_certificate_validation` is a
  no-infrastructure waiter resource with no Checkov/tfsec posture checks. The
  new variables and the added `precondition` introduce no scannable resources.
- **Existing suppressions affected: none.** The CloudFront suppressions in
  `.checkov.yaml` (`CKV_AWS_34`, `CKV_AWS_310`, `CKV_AWS_374`, `CKV2_AWS_32`,
  `CKV2_AWS_47`) relate to viewer protocol, origin failover, geo restriction,
  response-headers policy, and WAF — none touch ACM/certificate validation and
  none need changes.

## 7. terraform-docs impact
Yes — the `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/cloudfront/README.md`
will change:
- **Inputs:** two new rows (`wait_for_certificate_validation`,
  `certificate_validation_timeout`) and an updated description for
  `acm_certificate_arn`.
- **Resources:** one new row, `aws_acm_certificate_validation.this`.
- **Providers / Requirements:** unchanged (no new provider or alias this
  release; the `aws >= 6.0.0` requirement is untouched).
- **Outputs:** unchanged.

The hand-written portion of the README must also add a usage example for the
validation-wait pattern and a prerequisites note that the caller creates the
DNS validation records and (this release) configures the `aws` provider for
`us-east-1` when `wait_for_certificate_validation = true`.

## 8. Testing
- `tofu -chdir=modules/aws/cloudfront init -backend=false && tofu -chdir=modules/aws/cloudfront validate` (Terraform equivalents also acceptable).
- `tofu fmt -check -diff -recursive`.
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/cloudfront` (or `pre-commit run --all-files`) and commit the regenerated README.
- `checkov -d modules/aws/cloudfront` (locally; CI runs on schedule).
- Module-specific behavior checks:
  - Precondition **fails** when `acm_certificate_arn` is set and none of
    `cloudfront_default_certificate`, `iam_certificate_id`,
    `wait_for_certificate_validation` is present, with the documented message.
  - Precondition **passes** when `wait_for_certificate_validation = true` (or a
    validated ARN path that satisfies the final agreed condition from §9).
  - Variable `validation` **fails** when `wait_for_certificate_validation = true`
    and `acm_certificate_arn == null`.
  - With `wait_for_certificate_validation = true`, plan shows the gated
    `aws_acm_certificate_validation.this[0]` resource and the distribution
    depends on it; with the default `false`, no validation resource is planned
    and behavior matches today.

## 9. Open questions
- **Reconcile the Option 1 precondition with existing validated-ARN callers
  (blocking).** As written, the precondition will fail plan for existing
  callers who pass a validated ARN without setting a flag (see §5). Choose one
  before implementation:
  1. **Add an explicit acknowledgment escape hatch** (e.g. a new
     `acm_certificate_validated` `bool`, default `false`) and add it as a fourth
     OR-clause to the precondition. This keeps a guardrail while giving
     external-validation callers a non-resource-creating opt-out — but they must
     still set the new flag, so it is still a minor, documented caller action.
  2. **Accept the minor break** and document the remediation (set
     `wait_for_certificate_validation = true` or the new flag). Update the
     breaking-change classification accordingly.
  3. **Soften the precondition** (e.g. emit a warning-style check only, or scope
     it so it never fires when `acm_certificate_arn != null` regardless of
     flags), accepting a weaker guardrail.
  Recommendation: option 1, as it preserves the footgun protection with the
  smallest caller burden.
- **Optional validation status output.** Should `outputs.tf` expose a
  `certificate_validation_id` (or similar) when the gate is on, for caller
  observability/`depends_on` wiring? Current proposal: no.
- **Next-major follow-up.** Confirm the `aws.acm`
  `configuration_aliases = [aws.acm]` migration is tracked for the next major so
  ACM validation can target `us-east-1` independently of the distribution's
  provider region.

## 10. Acceptance criteria
The implementation PR must satisfy every item below (mirrors issue #282).

### Scope
- Both Option 1 (documented validated-ARN contract + fail-fast `precondition`)
  and Option 2 (optional in-module validation wait) are implemented.
- The dedicated **required** `aws.acm` provider alias
  (`configuration_aliases = [aws.acm]`) is **deferred to the next major
  version**. In this release the gated `aws_acm_certificate_validation` resource
  uses the module's existing/default `aws` provider, and the README documents
  that this provider must target `us-east-1` when
  `wait_for_certificate_validation = true`.

### Option 1 — precondition
- When `acm_certificate_arn` is set and none of `cloudfront_default_certificate`,
  `iam_certificate_id`, or `wait_for_certificate_validation = true` is present,
  `tofu plan` / `terraform plan` fails the `precondition` with the documented
  error message.
- When a caller satisfies the agreed condition from §9 (at minimum sets
  `wait_for_certificate_validation = true`), the precondition passes.
- The `acm_certificate_arn` variable description documents the validated-ARN
  contract.

### Option 2 — in-module validation wait
- A new `wait_for_certificate_validation` variable (`bool`, default `false`) is
  added. When `true`, the module creates a gated
  `aws_acm_certificate_validation` resource so the distribution is created only
  after the certificate reaches `ISSUED`.
- A new `certificate_validation_timeout` variable (`string`, default `"45m"`)
  controls the validation create timeout.
- A variable `validation` block enforces that
  `wait_for_certificate_validation = true` requires `acm_certificate_arn != null`.
- The `viewer_certificate` block consumes the validated ARN via
  `try(aws_acm_certificate_validation.this[0].certificate_arn, var.acm_certificate_arn)`.
- The module does **not** create DNS validation records.

### Backward compatibility / non-functional
- With `wait_for_certificate_validation = false` (the default), existing callers
  see no behavior change and need no new providers or variables, **except** for
  the Option 1 precondition behavior finalized per §9.
- The module `README.md` gains a usage example for the new validation-wait
  pattern plus a prerequisites note that the caller creates the DNS validation
  records (and, this release, configures the `aws` provider for `us-east-1`).
- `tofu fmt -check`, `terraform-docs`, and `tofu validate` all pass for the
  module.
