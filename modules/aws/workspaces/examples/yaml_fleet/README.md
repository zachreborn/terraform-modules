# YAML-Driven WorkSpaces Fleet Example

Demonstrates calling `modules/aws/workspaces` (the parent module) with YAML-managed input, across multiple
directory types and identity providers, using a pattern that scales from a handful of desktops to
thousands without hand-authoring more HCL.

## What this shows

- **Multiple directory types/identity providers** (`directories.yaml`):
  - `corp_ad` -- a `PERSONAL` directory backed by native Active Directory.
  - `corp_saml` -- a `PERSONAL` directory backed by an external SAML 2.0 identity provider (Okta in this
    example; Entra ID, ADFS, or an IAM Identity Center SAML application work the same way).
  - `pool_identity_center` -- a `POOLS` directory using IAM Identity Center as the identity provider,
    included to show directory-level support for that combination (see the note in `directories.yaml` about
    why no desktops target it).
- **An IP access control group** (`ip_groups.yaml`) referenced by both `PERSONAL` directories via
  `ip_group_keys`.
- **A fleet that scales to hundreds or thousands of users** (`users.yaml` + `main.tf`): rather than one YAML
  block per desktop, `users.yaml` groups users by directory + bundle and lists only their usernames.
  `main.tf` expands each group's `usernames` list into the full `workspaces` map via a nested
  `for` expression:
  ```
  workspaces = merge([
    for group in local.fleet.groups : {
      for username in group.usernames : "${group.directory_key}-${username}" => {
        directory_key = group.directory_key
        user_name     = username
        bundle_name   = group.bundle_name
      }
    }
  ]...)
  ```
  Growing a group from 5 users to 5,000 only means adding lines to a `usernames` list -- it never means
  writing more HCL or touching module code. Maintain that list however your organization already produces a
  user roster (a scheduled export, a small script querying the directory, etc.).

## Scaling notes

This example is deliberately small (9 desktops) so it plans quickly, but the pattern is what makes real
fleets manageable at scale:

- **Bundle and KMS key lookups are already deduplicated by the module** -- thousands of desktops sharing a
  handful of bundle names only trigger one `aws_workspaces_bundle` lookup per distinct bundle, and one
  shared KMS key is created regardless of fleet size (see `modules/aws/workspaces/workspace`'s README).
- **Check your AWS WorkSpaces service quotas** before provisioning a large fleet -- the default "WorkSpaces
  per Region" quota is often far lower than a large organization's headcount and needs a quota increase
  request.
- **Tune `-parallelism`** on `tofu apply`/`tofu plan` for very large fleets. WorkSpaces provisioning is slow
  per-desktop and the WorkSpaces API enforces its own throttling; the default parallelism of 10 is a
  reasonable starting point, but watch for `ThrottlingException` errors and reduce it if you see them.
- **Shard very large fleets across multiple root modules/states** (e.g. one YAML fleet per department or
  office, each its own `tofu apply`) rather than a single multi-thousand-resource apply, to keep plan/apply
  time and blast radius manageable. Nothing about this pattern requires a single `workspaces.yaml` -- point
  `main.tf` at as many YAML files, in as many separate root modules, as your organization needs.

## Running this example

This example references placeholder directory/subnet IDs and will not apply successfully as-is. Replace
`directories.yaml`'s `directory_id`/`subnet_ids` values with real resources (or module outputs, e.g.
`module.simple_ad.id`) before running `tofu init` and `tofu plan`.
