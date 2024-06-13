output "group_memberships" {
  description = "List of AWS Identity Store group memberships created."
  value       = aws_identitystore_group_membership.this[*].id
}
