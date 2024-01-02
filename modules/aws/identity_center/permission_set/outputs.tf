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
  description = "Map of the IDs of the permission set assignments and their corresponding configuration"
  value = {
    for assignment in aws_ssoadmin_account_assignment.this : "${split(",", assignment.id)[0]}_${split(",", assignment.id)[2]}" => {
      principal_id       = split(",", assignment.id)[0]
      principal_type     = split(",", assignment.id)[1]
      target_id          = split(",", assignment.id)[2]
      target_type        = split(",", assignment.id)[3]
      permission_set_arn = split(",", assignment.id)[4]
      instance_arn       = split(",", assignment.id)[5]
    }
  }
}
