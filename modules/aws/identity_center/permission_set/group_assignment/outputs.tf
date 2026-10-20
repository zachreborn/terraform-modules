output "assignment_ids" {
  description = "Map of target_accounts label to the parsed account assignment configuration for this group."
  value = {
    for label, assignment in aws_ssoadmin_account_assignment.this : label => {
      principal_id       = split(",", assignment.id)[0]
      principal_type     = split(",", assignment.id)[1]
      target_id          = split(",", assignment.id)[2]
      target_type        = split(",", assignment.id)[3]
      permission_set_arn = split(",", assignment.id)[4]
      instance_arn       = split(",", assignment.id)[5]
    }
  }
}
