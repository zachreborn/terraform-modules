# Spec: feat(cloudfront): add native Origin Access Control (OAC) management to the cloudfront module
**Issue:** #276
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
Origin Access Control (OAC) is the AWS-recommended mechanism for securing
S3 (and other) origins behind CloudFront, superseding the legacy Origin
Access Identity (OAI). Today the `modules/aws/cloudfront` module can *use*
an OAC but cannot *create* one: callers must declare an
`aws_cloudfront_origin_access_control` resource outside the module and pass
its ID into `origins[*].origin_access_control_id` (already exposed at
`variables.tf:244` and wired through the `origin` dynamic block at
`main.tf:110`).

This forces every consumer to manage a cross-cutting resource by hand and
makes OAC a second-class concern of the module. This spec makes OAC a
first-class, optional feature: the module can create and manage a map of
OACs and resolve them by name from the `origins` map, while preserving the
existing "bring your own OAC ID" path unchanged.

See: https://github.com/zachreborn/terraform-modules/issues/276

## 2. Non-goals
- Managing OAI (`s3_origin_config.origin_access_identity`) — the existing
  OAI path in the `origins` object is untouched.
- Generating or attaching the S3 bucket policy that grants the OAC access
  to the origin bucket. That belongs to the S3 bucket module/caller and is
  out of scope here.
- Refactoring the `aws_cloudfront_distribution.this` resource or any other
  existing `origins` / cache-behavior fields beyond the single
  `origin_request_policy_id` optionality fix described below.
- Adding OAC support to any module other than `modules/aws/cloudfront`.

## 3. Affected module path(s)
- `modules/aws/cloudfront/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
1. **New variable `origin_access_controls`** — map of OAC configs the module
   creates and manages. The map key doubles as the OAC `name` and is the
   value referenced from `origins[*].origin_access_control_name`.
   - type:
     ```hcl
     map(object({
       description                       = optional(string, "")
       origin_access_control_origin_type = optional(string, "s3")
       signing_behavior                  = optional(string, "always")
       signing_protocol                  = optional(string, "sigv4")
     }))
     ```
   - default: `null`
   - description: `"(Optional) Map of Origin Access Control configurations to create and manage within the module. The map key is used as the OAC name and can be referenced in the origins map via origin_access_control_name. Mutually exclusive with passing origin_access_control_id directly in origins."`
   - validations (all guarded by `var.origin_access_controls == null ? true : ...`):
     - `origin_access_control_origin_type` ∈ {`s3`, `mediastore`, `lambda`, `mediapackagev2`}
     - `signing_behavior` ∈ {`always`, `never`, `no-override`}
     - `signing_protocol` == `sigv4`

2. **Update `origins` object type** — add one optional field alongside the
   existing `origin_access_control_id = optional(string)`:
   - `origin_access_control_name = optional(string)` — references a key in
     `var.origin_access_controls`; the module resolves the ID. Mutually
     exclusive with `origin_access_control_id`; both `null` is valid (custom
     origins). Optionally add an intra-object validation rejecting an origin
     that sets *both* fields (see §9).

3. **Fix `ordered_cache_behavior.origin_request_policy_id`** — change from
   required `string` to `optional(string)`. S3-origin-with-OAC behaviors do
   not require an origin request policy, so the current required field is
   incorrect. Loosening to optional is backward compatible.

No other variables change.

### `outputs.tf`
- **New output `origin_access_control_ids`** — map of created OAC IDs keyed
  by OAC name; empty `{}` when `origin_access_controls` is `null`.
  - description: `"Map of Origin Access Control IDs created by this module, keyed by OAC name. Empty when origin_access_controls is null."`
- **Recommended for resource coverage (AGENTS.md §1):** also surface
  `origin_access_control_arns` and `origin_access_control_etags` (same
  keyed-map shape) so the OAC resource's `arn`/`etag` attributes are not
  silently omitted. Treated as recommended; see §9.

Existing outputs (`arn`, `domain_name`, `hosted_zone_id`, `id`) are
unchanged.

### `main.tf`
1. **New resource `aws_cloudfront_origin_access_control.this`** created with
   `for_each = var.origin_access_controls != null ? var.origin_access_controls : {}`.
   Argument mapping (full provider coverage — the OAC resource has no other
   arguments and supports no tags):
   - `name = each.key`
   - `description = each.value.description`
   - `origin_access_control_origin_type = each.value.origin_access_control_origin_type`
   - `signing_behavior = each.value.signing_behavior`
   - `signing_protocol = each.value.signing_protocol`

2. **Update the `origin` dynamic block** (`main.tf:110`) so
   `origin_access_control_id` resolves by name first, then falls back to a
   directly supplied ID, then `null`:
   ```hcl
   origin_access_control_id = try(
     aws_cloudfront_origin_access_control.this[origin.value.origin_access_control_name].id,
     origin.value.origin_access_control_id,
     null
   )
   ```

No new data sources, locals, `count`, lifecycle ignores, or tagging changes
are required. (The `aws_cloudfront_origin_access_control` resource does not
support tags, so the repo's `merge(tomap({ Name = ... }), var.tags)` tagging
convention does not apply to it.)

## 5. Breaking-change assessment
- Breaking: **no**.
- `origin_access_controls` defaults to `null`, so no existing call must
  change and no OAC resources are created unless opted in.
- `origins.origin_access_control_name` is `optional(string)`, so existing
  `origins` maps remain valid; the `try()` fallback preserves the existing
  `origin_access_control_id` path exactly.
- Making `ordered_cache_behavior.origin_request_policy_id` `optional(string)`
  only loosens an existing constraint — callers already supplying a value
  are unaffected, and the `origin_request_policy_id` argument is simply
  omitted (provider default) when null.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. Adding an OAC resource and additive
  variables/outputs introduces no findings that require suppression; OAC
  strengthens origin security rather than weakening it.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
**Yes** — `modules/aws/cloudfront/README.md`'s
`<!-- BEGIN_TF_DOCS -->` block will change and must be regenerated:
- Inputs table gains the new `origin_access_controls` variable.
- The `origins` input type signature gains `origin_access_control_name`.
- The `ordered_cache_behavior` input type signature changes
  `origin_request_policy_id` from `string` to `optional(string)`.
- Outputs table gains `origin_access_control_ids` (plus the recommended
  `origin_access_control_arns` / `origin_access_control_etags` if adopted).

Regenerate locally via `pre-commit run --all-files` (or per-module
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/cloudfront`)
and commit the result — CI verifies but does not auto-commit.

## 8. Testing
- `tofu -chdir=modules/aws/cloudfront init -backend=false && tofu -chdir=modules/aws/cloudfront validate`
  (Terraform equivalents are also acceptable.)
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/cloudfront` (locally; CI runs on schedule)
- Manual plan checks:
  - `origin_access_controls` set + `origins.origin_access_control_name`
    referencing it → OAC created and its ID attached to the origin.
  - Legacy path: `origins.origin_access_control_id` only (no
    `origin_access_controls`) → unchanged plan, no OAC resource created.
  - Custom origin with neither field → `origin_access_control_id` resolves
    to `null`.
  - `ordered_cache_behavior` without `origin_request_policy_id` → validates.

## 9. Open questions
- **Dangling-name safety:** with the proposed `try()` chain, an
  `origin_access_control_name` that does not match a key in
  `origin_access_controls` silently falls back to `null` (no OAC attached)
  instead of failing fast. Recommend a `lifecycle { precondition { ... } }`
  on `aws_cloudfront_distribution.this` (or equivalent) to assert every
  non-null `origin_access_control_name` exists in `var.origin_access_controls`.
  Note: a cross-variable `validation` block inside `origins` cannot be used
  because the module's `required_version = ">= 1.0.0"` predates cross-variable
  validation support (OpenTofu 1.8 / Terraform 1.9).
- **Mutual-exclusivity enforcement:** confirm whether to hard-fail (validation
  / precondition) when an origin sets both `origin_access_control_name` and
  `origin_access_control_id`, or to document name-takes-precedence behavior
  implied by the `try()` order.
- **Output completeness:** confirm whether to ship the recommended
  `origin_access_control_arns` / `origin_access_control_etags` outputs
  alongside the required `origin_access_control_ids` output.

## 10. Acceptance criteria
- [ ] `modules/aws/cloudfront/variables.tf` declares `origin_access_controls`
      (map of objects, default `null`) with the origin-type, signing-behavior,
      and signing-protocol validations.
- [ ] The `origins` object type gains `origin_access_control_name = optional(string)`
      alongside the existing `origin_access_control_id`.
- [ ] `ordered_cache_behavior.origin_request_policy_id` is `optional(string)`.
- [ ] `modules/aws/cloudfront/main.tf` adds
      `aws_cloudfront_origin_access_control.this` with `for_each` over
      `var.origin_access_controls`, covering all OAC resource arguments.
- [ ] The `origin` dynamic block resolves `origin_access_control_id` via the
      name→ID lookup with a fallback to the supplied ID, preserving the legacy
      path.
- [ ] `modules/aws/cloudfront/outputs.tf` declares `origin_access_control_ids`
      (keyed by OAC name, empty when the variable is `null`).
- [ ] No breaking changes — additive variable/output plus a loosened
      constraint; existing callers plan with no diff.
- [ ] `terraform-docs` auto-update keeps `README.md` in sync (Inputs +
      Outputs reflect the changes above).
- [ ] `tofu fmt -recursive` and `tofu -chdir=modules/aws/cloudfront validate`
      pass.
