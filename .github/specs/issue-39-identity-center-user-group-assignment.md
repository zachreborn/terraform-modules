# Spec: Identity Center - User to group assignment
**Issue:** #39
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
`modules/aws/identity_center` already manages manually-created AWS IAM Identity
Center users, groups, and their memberships without an external IdP. The
membership interface is user-centric: callers pass a `groups` map and a `users`
map, and each user's optional `groups` list references group keys. The module
flattens these into `aws_identitystore_group_membership` resources via
`local.group_membership` in `modules/aws/identity_center/main.tf` (28-37), keyed
by `"${user_key}-${group}"`.

Two best-practice gaps remain:

1. The membership identifiers are not surfaced as a module output, so callers
   cannot reference `membership_id`, the member (user) ID, or the group ID of a
   membership the module created.
2. `groups[*].description` is declared as a required `string` in
   `modules/aws/identity_center/variables.tf` (5), but the provider attribute
   (`aws_identitystore_group.description`) is optional. Callers are forced to
   supply a description even when they do not want one.

This spec scopes purely additive improvements to the existing module: a new
`group_memberships` output, relaxing `groups[*].description` to
`optional(string)`, and README documentation of the membership interface.

See: https://github.com/zachreborn/terraform-modules/issues/39

## 2. Non-goals
- No new input variables. The existing `users[*].groups` list continues to be
  the sole driver of group membership.
- No IdP-synced / SCIM-provisioned group management. This module remains for
  manually-managed (non-SSO-synced) identities only.
- No changes to the `aws_identitystore_user`, `aws_identitystore_group`, or
  `aws_identitystore_group_membership` resource names, `for_each` keys, or
  membership-flattening logic in `local.group_membership`.
- No changes to the existing `user_ids` / `group_ids` outputs.
- No changes to the nested `modules/aws/identity_center/permission_set`
  submodule.

## 3. Affected module path(s)
- `modules/aws/identity_center/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
One existing attribute changes; no variables are added or removed.

- `groups` (`map(object({...}))`, required) — unchanged variable, one nested
  attribute relaxed:
  - `display_name` (`string`, required) — unchanged.
  - `description` — change from required `string` to `optional(string)`, so
    callers may omit it. The resource already passes `each.value.description`
    straight through (`main.tf` 83), so a `null` value yields the provider
    default (no description).
- `users` (`map(object({...}))`, required) — unchanged, including the existing
  `groups = optional(list(string))` attribute that drives membership.

### `outputs.tf`
Add one new output alongside the existing `user_ids` and `group_ids` outputs
(which remain unchanged):

- **`group_memberships`**
  - type (implicit): `map(object({ membership_id = string, member = string, group = string }))`
  - value: a comprehension over `aws_identitystore_group_membership.this`,
    preserving the existing resource keys (`"<user_key>-<group_key>"`, where
    `user_key` is the user's `display_name` and `group_key` is the referenced
    `groups` map key). Each value exposes:
    - `membership_id` ← `…group_membership.this[k].membership_id`
    - `member` ← `…group_membership.this[k].member_id` (the user ID)
    - `group` ← `…group_membership.this[k].group_id` (the group ID)
  - description: e.g. `"Map of group memberships keyed by \"<user_display_name>-<group_name>\", exposing the membership_id, member (user ID), and group (group ID)."`

### `main.tf`
No resource, data source, or locals changes are required. The
`aws_identitystore_group_membership.this` resource and the
`local.group_membership` map that keys it already exist and already expose the
`membership_id`, `member_id`, and `group_id` attributes the new output reads.
The `description` attribute on `aws_identitystore_group.this` (83) already
references `each.value.description` and tolerates `null`. No `count`/`for_each`,
lifecycle, or tagging changes.

## 5. Breaking-change assessment
- Breaking: **no**.
- The change is purely additive: a new output is declared and a previously
  required nested attribute (`groups[*].description`) becomes optional.
  Relaxing required → optional is backward compatible — existing callers that
  already supply `description` continue to work unchanged, and new callers may
  omit it. No existing variable names, output names, resource addresses, or
  membership keys change, so no state migration is required.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. Adding an output and relaxing a variable
  attribute to optional introduces no security-relevant resource configuration.
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
Yes. The auto-generated `<!-- BEGIN_TF_DOCS -->` block in
`modules/aws/identity_center/README.md` will change:
- The Outputs table gains the new `group_memberships` row.
- The Inputs table entry for `groups` reflects `description` now being optional
  within the object type.
Regeneration is handled by the `terraform_docs` pre-commit hook / `build.yml`
CI verification; the implementation PR must commit the regenerated README.

## 8. Testing
- `tofu -chdir=modules/aws/identity_center init -backend=false && tofu -chdir=modules/aws/identity_center validate`
- `tofu fmt -check -diff -recursive`
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/identity_center` (or `pre-commit run --all-files`)
- `checkov -d modules/aws/identity_center` (locally; CI runs on schedule)
- Confirm a caller that defines a group without `description` plans cleanly, and
  that `group_memberships` returns one entry per `users[*].groups` reference.

## 9. Open questions
- None. The membership key format `"<user_display_name>-<group_name>"` follows
  the module's existing `local.group_membership` keys; the implementation must
  preserve those keys so the output aligns with the underlying resource
  addresses.

## 10. Acceptance criteria
- [ ] `group_memberships` output is present and returns the `membership_id`,
      user ID (`member`), and group ID (`group`) for every membership.
- [ ] `groups[*].description` is `optional(string)` and may be omitted by
      callers without error.
- [ ] README includes a Prerequisites section and a Notes / Design Decisions
      section explaining the user-centric membership interface.
- [ ] `tofu fmt -recursive`, `terraform-docs` regeneration, and `tofu validate`
      all pass with no errors.
- [ ] CI checks (`Linter`, `Test OpenTofu`, `Verify - terraform-docs`,
      `Invisible Unicode Check`) pass on the implementation PR.
- [ ] No breaking changes — additive output plus a required→optional relaxation.
