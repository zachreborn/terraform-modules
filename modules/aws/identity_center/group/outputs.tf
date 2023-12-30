output "group_ids" {
  description = "The IDs of the groups in the identity store"
  value       = {
    for group in aws_identitystore_group.this :
    group.display_name => group.id
  }
}
