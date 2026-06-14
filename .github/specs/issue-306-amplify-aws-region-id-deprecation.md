# Spec: fix(amplify): replace deprecated `data.aws_region.current.id` with `.name`
**Issue:** #306
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
The `modules/aws/amplify` module pins the AWS provider at `>= 6.0.0`
(`modules/aws/amplify/main.tf:9`). In that provider line the `id` attribute on
the `aws_region` data source is **deprecated**; the canonical attribute for the
region string (e.g. `us-east-1`) is now `name`.

The module reads `data.aws_region.current.id` in a single place — the
`notification_rule_arn` local at `modules/aws/amplify/main.tf:27` — to build the
EventBridge rule ARN deterministically (so the SNS topic policy can reference it
without a dependency cycle). Because of the deprecated read, `tofu plan` /
`terraform plan` now emit:

```
Warning: Deprecated attribute

  on .../modules/aws/amplify/main.tf line 27, in locals:
   27:   notification_rule_arn = "arn:aws:events:${data.aws_region.current.id}:..."

The attribute "id" is deprecated. Refer to the provider documentation for
details.
```

The warning is non-blocking today but is expected to become a hard error in a
future provider major version, and it adds noise to every plan that uses this
module. Replacing the read with `data.aws_region.current.name` produces the
identical region string, so the rendered ARN is byte-for-byte unchanged.

Provider reference: `aws_region` data source —
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region
(the `name` attribute is the region identifier; `id` is deprecated as of
`aws >= 6.0.0`). Triage classified this as a non-breaking bug fix
(issue #306 triage comment).

## 2. Non-goals
- No change to the `data "aws_region" "current" {}` declaration itself — only the
  attribute that reads from it.
- No change to module inputs (`variables.tf`), outputs (`outputs.tf`), or any
  resource/module wiring.
- No change to notification behaviour, EventBridge wiring, or the SNS topic
  policy logic — the computed ARN value is identical before and after.
- The issue's plan output mentions "one more similar warning elsewhere". A
  repo-wide search (`data.aws_region.<name>.id`) finds **no other occurrence**
  inside `terraform-modules`; the second warning originates from a different
  source in the reporter's caller configuration and is out of scope for this
  module fix.
- No broader audit of other deprecated `aws >= 6.0.0` attributes across other
  modules — that would be a separate issue/spec.

## 3. Affected module path(s)
- `modules/aws/amplify/` (existing)
  - `modules/aws/amplify/main.tf` — line 27 only.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No changes. No variables are added, removed, or retyped.

### `outputs.tf`
No changes. The existing outputs (`app_arn`, `app_id`, `default_domain`,
`notification_event_rule_arn`, `sns_topic_arn`) are unaffected; the value of
`notification_event_rule_arn` is unchanged because the underlying ARN string is
identical.

### `main.tf`
No blocks are added or removed. The single change is within the existing
`locals` block:

- `local.notification_rule_arn` — swap the region reference in the
  interpolation from `data.aws_region.current.id` to
  `data.aws_region.current.name`. The surrounding ARN template
  (`arn:aws:events:<region>:<account_id>:rule/<rule_name>`) is otherwise
  unchanged.

Unchanged for context (no edits):
- `data "aws_region" "current" {}` and `data "aws_caller_identity" "current" {}`
  data sources.
- `local.notification_sns_policy`, which references `local.notification_rule_arn`
  (it transitively benefits from the fix but needs no edit).
- `aws_amplify_app.this`, `aws_amplify_branch.this`,
  `aws_amplify_domain_association.this` resources and the
  `amplify_notifications_sns` / `amplify_notifications_event` child module calls.

## 5. Breaking-change assessment
- Breaking: **no**.
- `data.aws_region.current.name` returns the same region string as the
  deprecated `id` attribute, so `local.notification_rule_arn` and the derived
  `notification_event_rule_arn` output resolve to identical values. No caller
  inputs/outputs change and no state migration is required. For an already
  deployed stack, `tofu plan` should show **no diff** beyond the disappearance of
  the deprecation warning.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. The change does not introduce or alter any
  security-relevant resource configuration.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
No change to the auto-generated `<!-- BEGIN_TF_DOCS -->` block. terraform-docs
lists the `aws_region.current` *data source* (it remains declared) and the
module's inputs/outputs (all unchanged). Editing an attribute read inside a
local does not alter any documented surface, so the committed `README.md` for
`modules/aws/amplify` will regenerate identically.

## 8. Testing
- `tofu -chdir=modules/aws/amplify init -backend=false && tofu -chdir=modules/aws/amplify validate`
  (equivalently `terraform -chdir=modules/aws/amplify ...`).
- `tofu fmt -check -diff -recursive` (equivalently `terraform fmt ...`).
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/amplify`
  and confirm git reports no change to `modules/aws/amplify/README.md`.
- `checkov -d modules/aws/amplify` (locally; CI runs on schedule).
- Manual confirmation: run `tofu plan` against a configuration using the module
  with `enable_notifications = true` and verify the
  `Deprecated attribute` warning for `data.aws_region.current.id` no longer
  appears and that no resource diff is produced for an existing deployment.

## 9. Open questions
- None. The fix, scope, and non-breaking nature are confirmed by triage and by a
  repo-wide search showing a single affected line.

## 10. Acceptance criteria
- `modules/aws/amplify/main.tf` no longer references
  `data.aws_region.current.id`; the `notification_rule_arn` local uses
  `data.aws_region.current.name`.
- `tofu plan` (and `terraform plan`) against a module consumer with
  `enable_notifications = true` emits **no** `Deprecated attribute` warning for
  the `aws_region` data source from this module.
- No change to module inputs, outputs, or the generated EventBridge rule ARN
  value; an existing deployment shows no resource diff.
- `tofu fmt -check` passes and `modules/aws/amplify/README.md` is unchanged after
  regenerating terraform-docs.
- No new Checkov/tfsec suppressions are added.
