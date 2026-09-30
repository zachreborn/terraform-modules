output "arn" {
  description = "The ARN of the permission set"
  value       = aws_ssoadmin_permission_set.this.arn
}

output "created_date" {
  description = "The date the permission set was created"
  value       = aws_ssoadmin_permission_set.this.created_date
}

output "id" {
  description = "The ID of the permission set"
  value       = aws_ssoadmin_permission_set.this.id
}

output "assignment_ids" {
  description = "Nested map of the permission set's account assignments: group name -> target_accounts label (not the account ID) -> parsed assignment configuration. The nesting mirrors the module.group_assignments[\"<group>\"] / aws_ssoadmin_account_assignment.this[\"<label>\"] resource addresses."
  value       = { for group, m in module.group_assignments : group => m.assignment_ids }
}

output "group_ids" {
  description = "Map of the effective resolved group display name to Identity Store group ID actually used for assignments -- the merge of name-based data source lookups and the group_ids input."
  value       = local.group_id_map
}

output "group_attribute_path" {
  description = "The group attribute path actually used for the name-based aws_identitystore_group data source lookup (var.group_attribute_path, echoed back for callers/tests to confirm wiring without inspecting the underlying data source directly)."
  value       = var.group_attribute_path
}
