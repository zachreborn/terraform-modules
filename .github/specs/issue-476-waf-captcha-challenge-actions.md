# Spec: feat(waf): support captcha/challenge rule actions
**Issue:** #476
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
`modules/aws/waf` manages rules as separate `aws_wafv2_web_acl_rule` resources
(`modules/aws/waf/main.tf:151`). Each rule's action is driven by the string
`rule[*].action`, which the module fans out into a `dynamic "action"` block
containing only three nested dynamics — `allow`, `block`, and `count`
(`modules/aws/waf/main.tf (158-174)`).

The provider resource, however, accepts five action types: `allow`, `block`,
`count`, `captcha`, and `challenge`. `captcha` and `challenge` are simply
unreachable through this module today. Any other string a caller passes for
`action` (including `"captcha"`) silently matches none of the three inner
`for_each` guards, so the module emits an empty `action {}` block and the WAFv2
API rejects it at apply time with no plan-time signal — there is currently no
`validation {}` block on `var.rule` at all, only comments enumerating the
intended values (`modules/aws/waf/variables.tf:70`).

This makes the CAPTCHA/Challenge surface the module already exposes inert.
PR #445 correctly made `rule[*].captcha_config` / `rule[*].challenge_config`
opt-in `dynamic` blocks (`modules/aws/waf/main.tf (228-244)`), and
`var.token_domains`, `var.captcha_config`, and `var.challenge_config` are all
wired at the Web ACL level. But `CaptchaConfig`/`ChallengeConfig` only take
effect for a rule whose own action actually *is* `Captcha`/`Challenge`, so
callers can configure immunity times for a CAPTCHA that no rule can ever
trigger.

Separately, the provider allows a `custom_request_handling { insert_header { … } }`
sub-block on the `allow`, `count`, `captcha`, and `challenge` actions (see the
"Custom Request Handling" example and the Action reference in the
[`aws_wafv2_web_acl_rule` docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_rule)).
The module exposes none of it. Inserting a header is the standard way to tell a
downstream application that a CAPTCHA/Challenge action fired, so the issue
explicitly scopes it in alongside the new action types.

This is a "Complete Resource Coverage" gap per `AGENTS.md` § Module Design
Specifications § 1.

See: https://github.com/zachreborn/terraform-modules/issues/476
Discovered while reviewing https://github.com/zachreborn/terraform-modules/pull/445.

## 2. Non-goals
- **No new statement types.** `statement` keeps supporting exactly
  `managed_rule_group_statement`, `not_statement`, and
  `ip_set_reference_statement`. Broadening statement coverage is #254's
  ("Phase 3 — full WAFv2 statement type coverage") job.
- **No `rule_action_overrides` changes.** Making `captcha`/`challenge` valid
  values for a *managed rule group's* per-rule overrides is also #254; this spec
  only touches the top-level `rule[*].action`. `rule_action_overrides` remains a
  `list(string)` that forces `count {}`.
- **No `block { custom_response { … } }` support.** The `block` action's
  `custom_response` sub-block (and therefore any real use for the existing
  ACL-level `var.custom_response_body`) is a separate coverage gap and should be
  filed as its own issue. This spec adds only `custom_request_handling`, which
  `block` does not accept.
- **No `override_action` validation.** Adding a `validation {}` rule for
  `override_action`'s `none`/`count` enum is deliberately left out to keep this
  change reviewable; the `action`/`override_action` mutual-exclusion rule is
  likewise not validated here.
- **No Web ACL `default_action` change.** `captcha`/`challenge` are rule-only
  actions per the AWS API ("This action option is available for rules. It isn't
  available for web ACL default actions"), so `var.default_action` keeps its
  `allow`/`block` enum and validation untouched.
- **No new outputs.** See § 4.
- **No change to `captcha_config` / `challenge_config` semantics.** They stay
  opt-in exactly as PR #445 left them; this spec does not couple them to
  `action` (a caller may still set `action = "captcha"` and rely on the Web
  ACL-level `var.captcha_config`, or on the AWS 300s default).
- **No `required_providers` bump.** See § 9.

## 3. Affected module path(s)
- `modules/aws/waf/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Only `var.rule` changes. Its `map(object({ … }))` type gains one new attribute
and its `action` comment/description are corrected; three `validation {}` blocks
are added.

- **`rule`** — `map(object({ … }))`, default `{}` (unchanged name, kind, and
  default).
  - `action` — `optional(string)`. Unchanged type/optionality. The trailing
    comment becomes `# "allow", "block", "count", "captcha", or "challenge" — used for non-managed-rule-group statements`.
  - `custom_request_handling` — **new** —
    `optional(object({ insert_header = list(object({ name = string, value = string })) }))`.
    Headers WAF inserts into the request when this rule's action fires. Valid
    only with `action` ∈ {`allow`, `count`, `captcha`, `challenge`}; the
    provider does not accept it on `block`.
  - All other attributes (`name`, `priority`, `override_action`, `statement`,
    `captcha_config`, `challenge_config`, `visibility_config`) are unchanged,
    byte-for-byte.
  - `description` — reworded to enumerate all five `action` values and to note
    that `custom_request_handling` is not valid with `block`.
  - **`validation` #1 — `action` enum.** Condition shape:
    `alltrue([for v in values(var.rule) : v.action == null || contains(["allow", "block", "count", "captcha", "challenge"], v.action)])`.
    `error_message`: names the five valid values. Rationale: today an
    unrecognized `action` silently produces an empty `action {}` block that only
    fails at apply; this surfaces it at plan time. `action == null` must keep
    passing so `override_action`-only (managed rule group) rules are unaffected.
  - **`validation` #2 — `custom_request_handling` action compatibility.**
    Condition shape:
    `alltrue([for v in values(var.rule) : v.custom_request_handling == null || contains(["allow", "count", "captcha", "challenge"], coalesce(v.action, "block"))])`.
    `error_message`: `custom_request_handling` is only valid when `action` is
    one of `allow`, `count`, `captcha`, or `challenge`. Using `coalesce(v.action, "block")`
    makes a null `action` (managed-rule-group rule) fail too, which is correct —
    `override_action` rules have no per-rule request handling.
  - **`validation` #3 — non-empty `insert_header`.** Condition shape:
    `alltrue([for v in values(var.rule) : v.custom_request_handling == null || length(v.custom_request_handling.insert_header) > 0])`.
    `error_message`: at least one `insert_header` is required when
    `custom_request_handling` is set. Rationale: the WAFv2 API rejects a
    `CustomRequestHandling` with an empty `InsertHeaders` list.

No other variable in the file is touched — in particular `default_action`,
`captcha_config`, `challenge_config`, and `token_domains` keep their current
types, defaults, and validations.

### `outputs.tf`
**No changes.** `waf_acl_id`, `waf_acl_arn`, `waf_acl_name`, `ip_sets`,
`association_id`, `associated_resource_arn`, and `logging_configuration_id` all
stay as-is. The rule's configured action is already reflected in
`aws_wafv2_web_acl_rule.this` attributes; adding a per-rule action output is not
required by the issue and would be a new interface to maintain.

### `main.tf`
Only the `dynamic "action"` block inside `resource "aws_wafv2_web_acl_rule" "this"`
(`modules/aws/waf/main.tf (158-174)`) changes. The outer
`for_each = each.value.action != null ? [each.value.action] : []` guard and the
`for_each = { for k, v in var.rule : v.name => v }` keying are unchanged.

Inside `dynamic "action"`, the block list becomes:

- `dynamic "allow"` — existing guard `action.value == "allow"`; **now contains** a
  nested `dynamic "custom_request_handling"`.
- `dynamic "block"` — existing guard, unchanged, still `content {}` (no
  `custom_request_handling`; `block` takes `custom_response`, which is a non-goal).
- `dynamic "count"` — existing guard `action.value == "count"`; **now contains** a
  nested `dynamic "custom_request_handling"`.
- `dynamic "captcha"` — **new**, guard `action.value == "captcha" ? [1] : []`;
  contains a nested `dynamic "custom_request_handling"`.
- `dynamic "challenge"` — **new**, guard `action.value == "challenge" ? [1] : []`;
  contains a nested `dynamic "custom_request_handling"`.

The nested `custom_request_handling` shape, identical in all four places:

- `dynamic "custom_request_handling"` — guard
  `each.value.custom_request_handling != null ? [each.value.custom_request_handling] : []`
  (`each` is still in scope inside the nested dynamics, so the rule object is
  reachable without threading it through `action.value`, which is the action
  *string*).
  - `dynamic "insert_header"` — `for_each` over
    `custom_request_handling.value.insert_header`; `content` sets `name` and
    `value`.

Everything else in `main.tf` is untouched: `aws_wafv2_ip_set.this`,
`aws_wafv2_web_acl.this` (including its `default_action`, ACL-level
`captcha_config`/`challenge_config`, `lifecycle { ignore_changes = [rule] }`, and
`tags = merge(tomap({ Name = var.name }), var.tags)` tagging),
`aws_wafv2_web_acl_association.this`, the rule's `override_action` / `statement` /
`captcha_config` / `challenge_config` / `visibility_config` blocks, and
`aws_wafv2_web_acl_logging_configuration.this`.

### `README.md` (hand-written sections)
Per `AGENTS.md` § Module Design Specifications § 4, the non-generated prose must
be updated alongside the generated table:

- Add a **CAPTCHA / Challenge usage example** `module {}` block showing
  `action = "captcha"` on an IP-set or NOT-statement rule, an explicit
  `captcha_config.immunity_time_property.immunity_time`, and a
  `custom_request_handling.insert_header` entry.
- Extend the **Notes / Design Decisions** bullet on `action` vs. `override_action`
  to list all five action values, to state that `custom_request_handling` is
  invalid on `block` and on `override_action`-only rules, and to note that
  `token_domains` is required when serving CAPTCHA/Challenge across multiple
  domains.

## 5. Breaking-change assessment
- Breaking: **no**.
- The change is additive: `allow`, `block`, and `count` keep emitting exactly
  the same `action` block; `override_action` rules (`action == null`) are
  untouched; rules with no `custom_request_handling` emit no new nested block, so
  existing configurations produce a **no-op plan**.
- The three new `validation {}` rules only *tighten* plan-time checking on
  configurations that were already invalid at the AWS API:
  - An out-of-enum `action` (e.g. `"captcha"` before this change, or a typo like
    `"blok"`) previously produced an empty `action {}` and failed at apply. It
    now fails at plan. That is the intended correction, not a regression.
  - `custom_request_handling` is new, so its two validations cannot break any
    existing caller.
- Conventional Commit type: `feat:` → MINOR (per `AGENTS.md` § Release & Tag
  Strategy). No migration steps for callers.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. Adding action types and a request-header
  sub-block introduces no publicly exposed surface, no encryption/logging
  decision, and no IAM policy. Checkov's WAF checks concern Web ACL association
  and logging, neither of which changes.
- Existing suppressions affected: **none**. The `CKV2_AWS_31` suppression noted
  in `modules/aws/waf/README.md:160` (caller-supplied WAF log destination) is
  unrelated and stays as-is. No inline `#tfsec:ignore:` comments are added or
  removed.
- `.checkov.yaml` is not modified.

## 7. terraform-docs impact
**Yes — `modules/aws/waf/README.md` only.** The `<!-- BEGIN_TF_DOCS -->` Inputs
table row for `rule` (`modules/aws/waf/README.md:209`) is regenerated because
both the rendered `type` block (new `custom_request_handling` attribute plus the
edited inline `action` comment) and the `description` column change. No other
row changes: no variable is added or removed, no default changes, the Resources
table is unchanged (no new resource types), the Outputs table is unchanged, and
the Requirements/Providers tables are unchanged (see § 9).

The implementation must regenerate docs locally and commit the result — CI's
`Verify - terraform-docs` job fails on a diff and does not auto-commit:

```sh
pre-commit run --all-files
# or, per module:
terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/waf
```

## 8. Testing
Standard local checks:
- `tofu -chdir=modules/aws/waf init -backend=false && tofu -chdir=modules/aws/waf validate`
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/waf` (locally; CI runs on schedule)

Native `tofu test` plan (required — `AGENTS.md` § Module Design Specifications
§ 6). `modules/aws/waf/tests/` already contains `main.tftest.hcl` (valid
baseline) and `captcha_challenge_config.tftest.hcl` (PR #445 regression
coverage). **Neither existing file may be weakened or have cases removed.** The
implementation adds a third file,
`modules/aws/waf/tests/rule_action.tftest.hcl`, opening with the same offline
`mock_provider "aws"` / `mock_resource "aws_wafv2_web_acl"` scaffolding used by
the existing files (mocking `id` and `arn`) so `tofu init -backend=false && tofu test`
passes with no credentials. `expect_failures` cases follow the conventions in
`modules/aws/organizations/account/tests/validation.tftest.hcl`.

Every `run` block below supplies `name = "example-acl"` plus a single `rule`
entry with a `visibility_config` and an `ip_set_reference_statement` (unless
noted), mirroring the existing files.

**Valid baseline**

- **`plan_succeeds_with_captcha_action`** (`command = plan`) — one rule with
  `action = "captcha"`. Assert the `captcha` block is emitted exactly once
  (`length(one(aws_wafv2_web_acl_rule.this["…"].action).captcha) == 1`) and that
  the other four action blocks are absent (`allow`, `block`, `count`,
  `challenge` each length `0`). This is the core new capability.

**Conditional branch coverage** — one case per side of every new/changed
`for_each` guard inside `dynamic "action"`:

- **`plan_succeeds_with_challenge_action`** — `action = "challenge"`; assert the
  `challenge` block is emitted once and `captcha` is absent.
- **`allow_action_still_emits_only_allow`** — `action = "allow"`; assert `allow`
  length `1` and `captcha`/`challenge` length `0`. Regression guard for the
  pre-existing branch.
- **`block_action_still_emits_only_block`** — `action = "block"`; assert `block`
  length `1` and `captcha`/`challenge` length `0`.
- **`count_action_still_emits_only_count`** — `action = "count"`; assert `count`
  length `1` and `captcha`/`challenge` length `0`.
- **`override_action_rule_emits_no_action_block`** — a
  `managed_rule_group_statement` rule with `override_action = "none"` and no
  `action`; assert `length(aws_wafv2_web_acl_rule.this["…"].action) == 0` and
  `length(…override_action) == 1`. Proves the `action == null` branch and that
  managed-rule-group rules are unaffected.
- **`captcha_action_without_custom_request_handling`** — `action = "captcha"`,
  `custom_request_handling` omitted; assert the `captcha` block is present and
  its nested `custom_request_handling` is absent (length `0`). Covers the false
  side of the new nested guard.
- **`captcha_action_with_custom_request_handling`** — `action = "captcha"` plus
  `custom_request_handling = { insert_header = [{ name = "x-captcha-rule", value = "triggered" }] }`;
  assert `custom_request_handling` length `1`, `insert_header` length `1`, and
  that the header's `name`/`value` equal the caller's values. Covers the true
  side of the nested guard and the `insert_header` `for_each`.
- **`challenge_action_with_multiple_insert_headers`** — `action = "challenge"`
  with two `insert_header` entries; assert `insert_header` length `2` and that
  both names round-trip. Proves the `insert_header` `for_each` is not
  single-element-only.
- **`allow_action_with_custom_request_handling`** — `action = "allow"` with one
  `insert_header`; assert the header is emitted under `allow`, not under
  `captcha`/`challenge`. Proves the sub-block was added to the pre-existing
  `allow` branch.
- **`count_action_with_custom_request_handling`** — same as above for
  `action = "count"`.

**Validation coverage** — one `expect_failures` case per new `validation {}`
rule (§ 4):

- **`rejects_unknown_action_value`** — `action = "invalid-action"`;
  `expect_failures = [var.rule]`. Exercises validation #1.
- **`rejects_custom_request_handling_with_block_action`** — `action = "block"`
  plus a `custom_request_handling` block; `expect_failures = [var.rule]`.
  Exercises validation #2 on the `block` path.
- **`rejects_custom_request_handling_without_action`** — a
  `managed_rule_group_statement` rule with `override_action = "none"`, no
  `action`, and a `custom_request_handling` block; `expect_failures = [var.rule]`.
  Exercises validation #2 on the `action == null` path.
- **`rejects_empty_insert_header_list`** —
  `custom_request_handling = { insert_header = [] }` with
  `action = "captcha"`; `expect_failures = [var.rule]`. Exercises validation #3.

**Interaction with `captcha_config` / `challenge_config`** (acceptance criterion
2 of the issue):

- **`captcha_action_with_explicit_captcha_config`** — `action = "captcha"` and
  `captcha_config.immunity_time_property.immunity_time = 120`; assert the
  `captcha` action block is present *and*
  `one(…captcha_config).immunity_time_property[0].immunity_time == 120`. Proves
  action and per-rule config coexist.
- **`challenge_action_with_explicit_challenge_config`** — same for
  `action = "challenge"` with `immunity_time = 90`.

**Output assertions.** The module's outputs are unchanged by this feature and
are already asserted in `modules/aws/waf/tests/main.tftest.hcl`. To keep output
coverage complete in the presence of the new action types, the baseline
`plan_succeeds_with_captcha_action` case must also assert
`output.waf_acl_arn == aws_wafv2_web_acl.this.arn` and
`output.waf_acl_name == aws_wafv2_web_acl.this.name`, confirming a CAPTCHA rule
does not disturb the Web ACL outputs.

**Wiring assertions.** Not applicable — `modules/aws/waf` calls no child modules
(its README's Modules table reads "No modules"), so there is no parent/submodule
boundary to assert.

Implementation note (not a licence to weaken anything): `aws_wafv2_web_acl_rule`
is a plugin-framework resource, so nested blocks surface as lists in test
expressions — hence the `length(...) == n` / `one(...)` accessor style already
used in `captcha_challenge_config.tftest.hcl`. Use whatever accessor `tofu test`
reports for the *real* nested shape, but keep every assertion checking the exact
values above. If a case fails, fix the root cause in
`modules/aws/waf/main.tf` / `variables.tf` — do not narrow an assertion, delete
a `run` block, loosen an `expect_failures` case, or mock away the behavior under
test.

## 9. Open questions
- **Pre-existing provider floor mismatch (out of scope).**
  `modules/aws/waf/main.tf:9` declares `aws version = ">= 6.0.0"`, but
  `aws_wafv2_web_acl_rule` — which the module already uses today — was
  introduced in `hashicorp/aws` **v6.37.0**
  (https://github.com/hashicorp/terraform-provider-aws/pull/46682). The
  `captcha`/`challenge` action blocks and `custom_request_handling` shipped as
  part of that same initial resource schema, so this feature introduces **no
  new** minimum. Correcting the declared floor to `>= 6.37.0` per `AGENTS.md`
  § Module Design Specifications § 7 is a pre-existing gap; should it ride along
  in this PR (it would also change the README Requirements/Providers rows in
  § 7) or be filed as its own `fix:` issue? Default assumption for the
  implementation: **file separately, leave the constraint untouched.**
- **Should validation #2 reject `custom_request_handling` on `action == null`?**
  The proposed condition does (via `coalesce(v.action, "block")`), on the
  grounds that a managed-rule-group rule has no per-rule request handling.
  Confirm reviewers agree that is a hard error rather than a silently ignored
  input.
- **Is a rule-level `action` output wanted?** § 4 proposes none. If reviewers
  want per-rule introspection, a `rules` map output (name → id/action) could be
  added, but that is a new interface the issue does not ask for.

## 10. Acceptance criteria
- [ ] `rule[*].action = "captcha"` plans successfully and produces
      `action { captcha {} }` on `aws_wafv2_web_acl_rule`.
- [ ] `rule[*].action = "challenge"` plans successfully and produces
      `action { challenge {} }` on `aws_wafv2_web_acl_rule`.
- [ ] A rule with `action = "captcha"` (or `"challenge"`) plus an explicit
      `captcha_config`/`challenge_config` applies the caller's `immunity_time`.
- [ ] `rule[*].custom_request_handling.insert_header` is emitted under the
      selected `allow`, `count`, `captcha`, or `challenge` action, with the
      caller's header `name`/`value`.
- [ ] Existing `allow` / `block` / `count` rules, and rules using
      `override_action` + `managed_rule_group_statement`, produce a byte-for-byte
      unchanged plan (no new nested blocks, no removed blocks).
- [ ] An unknown `action` value fails at plan time with a message naming the
      five valid values.
- [ ] `custom_request_handling` combined with `action = "block"`, or with a rule
      that has no `action`, fails at plan time.
- [ ] `custom_request_handling` with an empty `insert_header` list fails at plan
      time.
- [ ] `modules/aws/waf/tests/rule_action.tftest.hcl` is added with every `run`
      block enumerated in § 8, and `tofu -chdir=modules/aws/waf test` passes
      offline (`mock_provider`, no credentials/backend) with the pre-existing
      `main.tftest.hcl` and `captcha_challenge_config.tftest.hcl` cases still
      passing unmodified.
- [ ] `modules/aws/waf/README.md` gains a CAPTCHA/Challenge usage example and an
      updated `action` vs. `override_action` design note, and its
      `<!-- BEGIN_TF_DOCS -->` block is regenerated (the `rule` input row) and
      committed.
- [ ] No new Checkov/tfsec suppressions; `.checkov.yaml` unchanged.
- [ ] No changes to `outputs.tf`, `var.default_action`, `var.captcha_config`,
      `var.challenge_config`, `var.token_domains`, or the `statement` /
      `rule_action_overrides` surface.
- [ ] `tofu fmt -check -diff -recursive` and
      `tofu -chdir=modules/aws/waf validate` pass.
