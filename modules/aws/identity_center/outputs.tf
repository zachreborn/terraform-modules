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
