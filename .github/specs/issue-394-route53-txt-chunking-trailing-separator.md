# Spec: Fix route53 TXT 255-char chunking trailing separator on exact multiples of 255
**Issue:** #394
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
All five Route 53 record modules chunk long record strings (TXT/DKIM values that
exceed the DNS 255-character-per-string limit) with the same `locals` expression:
```hcl
locals {
  records = [for record in var.records : replace(record, "/(.{255})/", "$1\"\"")]
}
```
This global `replace()` matches every run of exactly 255 characters and appends a
`""` separator after each match. When a record's length is an exact multiple of
255, the final complete chunk also matches, so a superfluous trailing `""` is
appended even though there is no remaining content to separate.

Observed behavior:
- A 255-char input becomes `<255 chars>""` (257 chars) — a trailing separator
  with nothing after it. The correct result is the record passed through
  unchanged (nothing needs splitting).
- A 510-char input becomes `<255>""<255>""` (514 chars). The correct result is
  `<255>""<255>` (512 chars) — one separator between the two chunks, none after
  the last.

The comment in each module ("split ... with `\"\"` between each 255th and 256th
character") documents the intended behavior: separators belong *between* chunks
only. The identical expression is duplicated verbatim in all five modules, so the
same defect affects each one.

Originating issue: #394. Triaged as a bug (`ready-for-spec`).

## 2. Non-goals
- Extracting the shared chunking logic into a common internal submodule. The
  issue explicitly defers this larger refactor; each module keeps its own
  `locals` block, fixed in place.
- Changing any variable/output surface, resource arguments, routing-policy
  blocks, or default values.
- Altering behavior for records whose length is **not** an exact multiple of 255
  (e.g. a 300-char record must still split into `<255>""<45>`, exactly as today).
- Adding a `tests/` directory retroactively for behaviors unrelated to this bug.

## 3. Affected module path(s)
All five modules that duplicate the chunking `locals`, all existing:
- `modules/aws/route53/simple_record/`
- `modules/aws/route53/weighted_routing_record/`
- `modules/aws/route53/failover_routing_record/`
- `modules/aws/route53/latency_routing_record/`
- `modules/aws/route53/geolocation_routing_record/`

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes in any of the five modules. The existing surface is retained:
`zone_id` (string), `name` (string), `type` (string, with the TXT/A/AAAA/…
`validation {}` block), `ttl` (number, default `300`), `records`
(`list(string)`), `health_check_id` (string, default `null`), plus the
per-module routing-policy inputs (`set_identifier`,
`weighted_routing_policy_weight`, `failover_routing_policy_type`,
`latency_routing_policy_region`, and the three
`geolocation_routing_policy_*` inputs).

### `outputs.tf`
No changes. All five modules currently expose no outputs (empty `outputs.tf`);
this spec does not add any.

### `main.tf`
Only the `locals` block changes in each of the five modules; the
`aws_route53_record.this` resource block, its arguments, and its routing-policy
sub-blocks are unchanged (they continue to reference `local.records`).

Replace the global-`replace()` chunking with an approach that inserts a `""`
separator strictly between chunks. **Signature-level shape** (exact expression to
be finalized in implementation):
```hcl
locals {
  records = [
    for record in var.records :
    join("\"\"", [
      for i in range(ceil(length(record) / 255)) :
      substr(record, i * 255, 255)
    ])
  ]
}
```
Rationale / constraints the implementation must honor:
- OpenTofu/Terraform `replace()` uses the RE2 engine, which does **not** support
  lookahead assertions, so a `(?=.)`-style "only if more follows" regex fix is
  not available. A `for`/`substr`-based chunker (as above) is the recommended
  approach and matches the fix suggested in the issue.
- `join("\"\"", chunks)` yields no separator for a single chunk (records ≤ 255
  chars pass through unchanged) and exactly one separator between each adjacent
  pair — never a trailing one.
- `ceil(length(record) / 255)` gives the chunk count (e.g. 255→1, 300→2, 510→2).
- The implementation must confirm `substr`'s clamping behavior for the final,
  shorter chunk (offset + length exceeding the string) on the supported
  toolchain and adjust the final-chunk length computation if `substr` does not
  clamp, so a 300-char record still produces `<255>""<45>`.
- The `# See https://github.com/hashicorp/terraform-provider-aws/issues/14941`
  comment and the section-header comment style are preserved.
- Apply the identical corrected `locals` to all five modules so they stay in
  sync.

## 5. Breaking-change assessment
- Breaking: no (behavioral change is a bug fix, low risk).
- The emitted TXT value changes **only** for records whose length is an exact
  multiple of 255 — the superfluous trailing `""` is removed. Well-behaved
  records (≤ 255 chars, or non-multiple lengths) are byte-for-byte unchanged.
- A consumer that somehow depended on the current buggy trailing `""` for those
  exact-multiple lengths would observe a value change (and a one-time in-place
  update on `tofu apply`). This is the intended correction, not a regression.

## 6. Checkov / tfsec considerations
- New suppressions: none. The change is confined to a pure-HCL `locals`
  expression and introduces no new resources or provider arguments.
- Existing suppressions affected: none.

## 7. terraform-docs impact
None. No variables or outputs are added, removed, or re-described, so the
auto-generated `<!-- BEGIN_TF_DOCS -->` block in each module's `README.md` is
unaffected. (Docs should still be regenerated as part of the standard
pre-commit/CI check to confirm no drift.)

## 8. Testing
- `tofu -chdir=<path> init -backend=false && tofu -chdir=<path> validate` for
  each of the five module paths.
- `tofu fmt -check -diff -recursive`.
- `checkov -d <path>` (locally; CI runs on schedule).
- Native `tofu test` plan (required — `AGENTS.md` § Module Design Specifications
  § 6). Each module must have a `tests/` directory exercising the chunking fix.
  Four modules already have `tests/main.tftest.hcl` +
  `tests/validation.tftest.hcl`; `simple_record` currently has **no** `tests/`
  directory and the implementation must create one following the same
  `mock_provider "aws" {}` + `command = plan` conventions used by the sibling
  modules.
  Required `run` cases, added/updated in **every** affected module's
  `tests/*.tftest.hcl`:
  - **Valid-baseline** `run` (`command = plan`) with a normal short record,
    asserting the plan succeeds and `zone_id`/`name`/`type`/`ttl` pass through —
    mirrors the existing `plan_succeeds_with_valid_input` pattern (and, for the
    routing modules, that the routing-policy sub-block value is honored).
  - **`type` validation** — one `expect_failures = [var.type]` case supplying an
    unsupported `type` (e.g. `"INVALID"`), matching the existing
    `rejects_unsupported_type` case, since `type` is the only variable with a
    `validation {}` block. (No other variable has a validation rule, so no
    further `expect_failures` cases are required.)
  - **Record ≤ 255 chars (no split)** — assert a short record is present in
    `aws_route53_record.this.records` unchanged (no `""` inserted).
  - **Record exactly 255 chars (boundary, the bug)** — assert the output equals
    the input with **no** trailing `""` (length stays 255, not 257). This is the
    corrected assertion; do not pin the old buggy `<255>""` value.
  - **Record exactly 510 chars (boundary, the bug)** — assert the output equals
    `<255>""<255>` (512 chars) with exactly one separator between the two chunks
    and none after the last.
  - **Record of a non-multiple length > 255 (e.g. 300 chars)** — assert the
    output is `<255>""<45>`, proving the between-chunks separator still works and
    the fix did not regress the normal split path (mirrors the existing
    `record_longer_than_255_characters_is_split` case).
  - **`ttl` default vs. override** — retain/duplicate the existing
    `ttl_defaults_to_300` and `ttl_override_is_honored` cases where present.
  These modules manage a single resource and call no submodules, so no wiring
  assertions are applicable. Every assertion must check real, corrected module
  behavior — do not weaken, skip, or re-pin any case to the buggy value to force
  a pass; if a case fails, fix the `locals` expression, not the test.

## 9. Open questions
- Confirm `substr()` clamping semantics for the final shorter chunk on the
  supported OpenTofu (`>= 1.6.0`) / Terraform (`>= 1.0.0`) versions; if `substr`
  does not clamp when `offset + length` exceeds the string, the final-chunk
  length must be computed explicitly. Resolvable during implementation by running
  the boundary `tofu test` cases.
- Whether to fix all five modules in a single PR (recommended, since the logic is
  identical) — assumed yes unless review directs otherwise.

## 10. Acceptance criteria
- The chunking logic in all five modules (`simple_record`,
  `weighted_routing_record`, `failover_routing_record`,
  `latency_routing_record`, `geolocation_routing_record`) no longer appends a
  trailing `""` when a record's length is an exact multiple of 255.
- A record of exactly 255 characters passes through unchanged (no separator).
- A record of exactly 510 characters becomes `<255>""<255>` (one separator,
  between the chunks only).
- Separators are only ever inserted **between** two chunks, never after the last.
- Records of non-multiple lengths > 255 (e.g. 300) still split correctly into
  `<255>""<45>`.
- Every affected module has native `tofu test` boundary-case `run` blocks
  asserting the corrected (non-buggy) behavior for the 255- and 510-character
  inputs; `simple_record` gains a `tests/` directory if it does not already have
  one on the implementation branch.
- `tofu fmt -check -diff -recursive`, `tofu validate`, and `tofu test` pass for
  every affected module; committed `terraform-docs` output is unchanged.
- No variable, output, or resource-argument surface changes; no new Checkov/tfsec
  suppressions.
