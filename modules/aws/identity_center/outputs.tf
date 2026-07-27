output "user_ids" {
  description = "The IDs of the users in the identity store"
  value = {
    for user in aws_identitystore_user.this :
    user.display_name => user.id
  }
}

output "group_ids" {
  description = "The IDs of the groups in the identity store"
  value = {
    for group in aws_identitystore_group.this :
    group.display_name => group.id
  }
}

output "group_memberships" {
  description = "The group memberships created in the identity store, keyed by '<user_display_name>-<group_name>'"
  value = {
    for k, m in aws_identitystore_group_membership.this :
    k => {
      membership_id = m.membership_id
      member        = m.member_id
      group         = m.group_id
    }
  }
}

output "permission_set_ids" {
  description = "Map of permission set IDs, keyed by the same keys as var.permission_sets."
  value       = { for k, v in module.permission_sets : k => v.id }
}

output "permission_set_resolved_group_keys" {
  description = "Map of permission_sets[*].group_keys resolved directly against this module's own group resources, independent of the permission_set submodule call -- keyed by the same keys as var.permission_sets, each value a map of group_key to resolved group ID. Useful for confirming which of this module's own groups feed a given permission set before/without inspecting the submodule's own outputs."
  value = {
    for k, v in var.permission_sets : k => {
      for gk in coalesce(v.group_keys, []) : gk => lookup(local.group_id_map, gk, null)
    }
  }

  # module blocks cannot host their own lifecycle preconditions (see
  # https://github.com/hashicorp/terraform/issues/31122), so this cross-reference check lives on an
  # output instead. This output's value depends only on var.permission_sets/var.groups/local.group_id_map
  # (never on module.permission_sets itself), so the precondition is always evaluated and reported here
  # even when a bad group_keys entry also causes the permission_sets module call to fail on its own
  # (generic) group_ids validation -- giving callers one clear, actionable message either way.
  precondition {
    condition = alltrue(flatten([
      for k, v in var.permission_sets : [
        for gk in coalesce(v.group_keys, []) : contains(keys(var.groups), gk)
      ]
    ]))
    error_message = "Every permission_sets[*].group_keys entry must be found in var.groups. Check for typos, or use permission_sets[*].groups (by display name) to reference a group not managed by this identity_center module call."
  }
}

output "permission_set_arns" {
  description = "Map of permission set ARNs, keyed by the same keys as var.permission_sets."
  value       = { for k, v in module.permission_sets : k => v.arn }
}

output "permission_set_created_dates" {
  description = "Map of the date each permission set was created, keyed by the same keys as var.permission_sets."
  value       = { for k, v in module.permission_sets : k => v.created_date }
}

output "permission_set_assignment_ids" {
  description = "Map of each permission set's own assignment_ids output (account-assignment IDs and parsed fields), keyed by the same keys as var.permission_sets."
  value       = { for k, v in module.permission_sets : k => v.assignment_ids }
}

output "permission_set_group_ids" {
  description = "Map of each permission set's own effective resolved group-name to group-ID map, keyed by the same keys as var.permission_sets."
  value       = { for k, v in module.permission_sets : k => v.group_ids }
}
