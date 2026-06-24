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
