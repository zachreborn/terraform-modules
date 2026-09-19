# Spec: fix(aws/cloudformation/stack): providing both policy_body+policy_url or template_body+template_url silently nulls out both
**Issue:** #377
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Bug fix

## 1. Background
`modules/aws/cloudformation/stack/main.tf` maps the two mutually-exclusive
policy/template argument pairs onto the `aws_cloudformation_stack` resource with
independent ternaries (`main.tf:37-41`):
```hcl
policy_body   = var.policy_url == null ? var.policy_body : null
policy_url    = var.policy_body == null ? var.policy_url : null

template_body = var.template_url == null ? var.template_body : null
template_url  = var.template_body == null ? var.template_url : null
```
Each ternary checks the *other* variable for nullness in isolation. When a
caller supplies **both** members of a pair (e.g. `policy_body` and `policy_url`),
each expression sees its counterpart as non-null and nulls **itself** out, so
**both** attributes resolve to `null`. Because `policy_url`/`template_url` are
plain Optional (not Computed) attributes in the AWS provider schema, a real
apply would send neither `StackPolicyBody`/`StackPolicyURL` (or
`TemplateBody`/`TemplateURL`) to CloudFormation, silently discarding the
caller's intended policy/template rather than honoring the "Conflicts with …"
semantics documented on the variables (`variables.tf:53-75`).

The variable descriptions already declare the pairs as conflicting, but the
module neither enforces that nor resolves it deterministically — it fails open
to "no value." The issue was found while adding native OpenTofu test coverage;
the module currently ships **no** `tests/` directory, so the fix must also
introduce one per `AGENTS.md` § Module Design Specifications § 6.

See: https://github.com/zachreborn/terraform-modules/issues/377

## 2. Non-goals
- Adding, removing, or retyping any input variable or output. The module's
  public interface (`capabilities`, `disable_rollback`, `iam_role_arn`, `name`,
  `notification_arns`, `on_failure`, `parameters`, `policy_body`, `policy_url`,
  `template_body`, `template_url`, `timeout_in_minutes`, `tags`) is unchanged.
- Changing the unrelated `disable_rollback` / `on_failure` mutual handling
  (`main.tf:31,35`); it is only referenced here so the new tests cover those
  existing conditional branches too.
- Bumping the module's `required_version` constraint. The chosen fix (see §4)
  must work under the existing `>= 1.0.0` constraint (i.e. no cross-variable
  `validation {}`, which needs OpenTofu ≥ 1.9 / Terraform ≥ 1.9).
- Adding KMS, IAM, or other cross-cutting resources — this is a single-resource
  wrapper module and stays that way.

## 3. Affected module path(s)
- `modules/aws/cloudformation/stack/` (existing) — `main.tf` fix.
- `modules/aws/cloudformation/stack/tests/` (new) — native `tofu test` suite.

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
No new variables; no type or default changes. The two `string`/`default = null`
pairs (`policy_body`/`policy_url`, `template_body`/`template_url`) keep their
current signatures. **Recommended (optional):** extend the four descriptions to
state that when both members of a pair are supplied, the URL form takes
precedence (matches the resolved behavior below). Any description edit changes
the auto-generated docs (see §7).

### `outputs.tf`
No changes. `id`, `name`, and `outputs` remain as-is.

### `main.tf`
Replace the four self-nulling ternaries in `aws_cloudformation_stack.this` so
each pair resolves against a **single shared precedence** rather than each
attribute independently nulling itself. Deterministic precedence: the URL form
wins when both are supplied (chosen to match the referenced test name
`policy_url_takes_precedence_over_policy_body` in the issue). Signature-level
shape only:
```hcl
policy_url    = var.policy_url
policy_body   = var.policy_url == null ? var.policy_body : null

template_url  = var.template_url
template_body = var.template_url == null ? var.template_body : null
```
Result matrix per pair (URL precedence):
- only body set → body sent, url null.
- only url set → url sent, body null.
- both set → url sent, body null (deterministic; no longer both-null).
- neither set → both null (unchanged).

No new resources, data sources, locals, or child modules. The `capabilities`,
`disable_rollback`/`on_failure`, `parameters`, `tags`, and
`timeout_in_minutes` handling are untouched.

**Alternative considered (not chosen):** a hard failure when both are supplied.
A per-variable `validation {}` cannot reference the sibling variable without
raising the `required_version` floor, and a resource `lifecycle.precondition`
would need ≥ 1.2. Deterministic URL precedence satisfies the acceptance criteria
without a version bump and keeps single-value callers unaffected, so it is the
primary design; see §9 to confirm at review.

## 5. Breaking-change assessment
- Breaking: **no**. No variable or output is added, removed, or retyped, and no
  resource address changes.
- Behavioral change is confined to the **currently-broken** both-supplied case:
  today both attributes go null; after the fix the URL form is sent. Callers who
  supply only one member of a pair (the normal case) see identical planned
  output before and after. No migration steps required.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. The change only reorders existing conditional
  logic on already-present attributes; no new security-relevant configuration is
  introduced. `.checkov.yaml` and `.trivyignore` are not modified.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
- The `main.tf` ternary change alone does **not** alter the auto-generated
  `<!-- BEGIN_TF_DOCS -->` block (terraform-docs surfaces providers, resources,
  inputs, and outputs — not the right-hand-side expressions of resource
  arguments), so the Resources/Inputs/Outputs tables are unaffected.
- **If** the optional description edits in §4 are applied, the Inputs table
  inside the generated block **will** change and must be regenerated
  (`pre-commit run --all-files`, or per-module
  `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/cloudformation/stack`).
  The `Verify - terraform-docs` CI job fails on a stale README.
- Adding the `tests/` directory does not affect terraform-docs output.

## 8. Testing
- `tofu -chdir=modules/aws/cloudformation/stack init -backend=false && tofu -chdir=modules/aws/cloudformation/stack validate` (Terraform equivalents also acceptable).
- `tofu fmt -check -diff -recursive`.
- `checkov -d modules/aws/cloudformation/stack` (locally; CI runs on schedule).
- `pre-commit run --all-files` to confirm terraform-docs is in sync (relevant only if variable descriptions change per §7).
- Native `tofu test` plan (required — see `AGENTS.md` § Module Design
  Specifications § 6). The module currently has **no** `tests/` directory, so
  the implementation must create one. All cases run offline via
  `mock_provider "aws"` with a `mock_resource "aws_cloudformation_stack"`
  supplying `id`/`name`/`outputs` defaults; `tofu init -backend=false && tofu test`
  from the module directory must pass with no credentials or backend. Model the
  `mock_provider`/`run`/`expect_failures` conventions on
  `modules/aws/organizations/tests/`.
  - **`tests/main.tftest.hcl` — valid baseline:** a `run "plan_succeeds_with_valid_input"`
    (`command = plan`) providing only `name` + `template_body`; assert
    `output.name` equals the supplied name and `output.id`/`output.outputs` are
    non-null.
  - **`tests/main.tftest.hcl` — policy precedence branches** (covers the fixed
    `policy_body`/`policy_url` ternaries):
    - only `policy_body` set → assert `aws_cloudformation_stack.this.policy_body`
      equals the input and `.policy_url` is null.
    - only `policy_url` set → assert `.policy_url` equals the input and
      `.policy_body` is null.
    - both `policy_body` **and** `policy_url` set (the bug) → assert `.policy_url`
      equals the supplied URL and `.policy_body` is null (deterministic URL
      precedence; must **not** null out both).
  - **`tests/main.tftest.hcl` — template precedence branches** (covers the fixed
    `template_body`/`template_url` ternaries): mirror the three policy cases for
    `template_body`/`template_url`, including the both-supplied case asserting
    `.template_url` wins and `.template_body` is null.
  - **`tests/main.tftest.hcl` — disable_rollback / on_failure branches** (covers
    the existing `main.tf:31,35` conditionals):
    - `disable_rollback = true` with `on_failure = null` → assert
      `.disable_rollback == true` and `.on_failure` is null.
    - `on_failure = "DELETE"` with default `disable_rollback` → assert
      `.on_failure == "DELETE"` and `.disable_rollback == false`.
  - **`tests/validation.tftest.hcl` — one `expect_failures` case per
    `validation {}` rule in `variables.tf`**, plus a valid-baseline `run` that
    passes every validation:
    - `capabilities` set to a list containing an unsupported value →
      `expect_failures = [var.capabilities]`.
    - `on_failure` set to a non-`DO_NOTHING|ROLLBACK|DELETE` string →
      `expect_failures = [var.on_failure]`.
    - `timeout_in_minutes = 0` (and/or negative) → `expect_failures = [var.timeout_in_minutes]`.
  - **Output assertions:** every meaningful output (`id`, `name`, `outputs`) is
    asserted in at least the baseline case, not merely checked for existence.
  - Not a wrapper/composition module (no child-module calls), so no submodule
    wiring assertions are required.
  - Do not weaken, skip, or mock away any assertion to force a pass. If a case
    fails, fix the root cause in `main.tf`.

## 9. Open questions
- Confirm at review that **deterministic URL precedence** (URL wins when both
  are supplied) is preferred over raising a hard error. The acceptance criteria
  permit either; precedence is recommended because a cross-variable
  `validation {}` / resource `precondition` would raise the module's
  `required_version` floor above the current `>= 1.0.0` (a non-goal, §2), and
  the issue's referenced test name (`policy_url_takes_precedence_over_policy_body`)
  implies precedence.
- Confirm the default `mock_resource "aws_cloudformation_stack"` echoes the
  configured `policy_body`/`policy_url`/`template_body`/`template_url` attributes
  in the plan so the precedence assertions can read them; if a mocked attribute
  is unknown at plan time, adjust the mock defaults rather than weakening the
  assertion.

## 10. Acceptance criteria
- [ ] Providing both `policy_body` and `policy_url` results in exactly one of
  them being sent to the AWS API (URL takes precedence), never both-null.
- [ ] The same fix is applied to `template_body`/`template_url` (URL precedence,
  never both-null).
- [ ] Single-value callers (only one member of a pair) are unaffected — the
  supplied value is sent and its counterpart is null.
- [ ] A native `tofu test` suite is added under
  `modules/aws/cloudformation/stack/tests/` covering the valid baseline, each
  policy/template precedence branch (including the both-supplied case), the
  `disable_rollback`/`on_failure` branches, one `expect_failures` case per
  variable `validation {}` rule, and assertions on `id`/`name`/`outputs`.
- [ ] `tofu -chdir=modules/aws/cloudformation/stack test` passes offline (mocked,
  no credentials/backend).
- [ ] No breaking interface changes — no variables or outputs added, removed, or
  retyped, and `required_version` is unchanged.
- [ ] `tofu validate`, `tofu fmt -check`, and (if descriptions changed)
  terraform-docs regeneration all pass for the module.
