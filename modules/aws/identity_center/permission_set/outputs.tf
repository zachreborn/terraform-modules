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
  description = "Map of the IDs of the permission set assignments and their corresponding configuration, keyed by '<group_name>_<account_id>' -- the same key already used by the underlying for_each, which is guaranteed unique by construction (unlike re-deriving a key from the resource's own runtime id)."
  value = {
    for key, assignment in aws_ssoadmin_account_assignment.this : key => {
      principal_id       = split(",", assignment.id)[0]
      principal_type     = split(",", assignment.id)[1]
      target_id          = split(",", assignment.id)[2]
      target_type        = split(",", assignment.id)[3]
      permission_set_arn = split(",", assignment.id)[4]
      instance_arn       = split(",", assignment.id)[5]
    }
  }
}

output "group_ids" {
  description = "Map of the effective resolved group display name to Identity Store group ID actually used for assignments -- the merge of name-based data source lookups and the group_ids input."
  value       = local.group_id_map
}
