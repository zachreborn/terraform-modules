###########################
# Schedule Outputs
###########################

output "arn" {
  description = "ARN of the schedule."
  value       = aws_scheduler_schedule.this.arn
}

output "id" {
  description = "ID of the schedule (its name)."
  value       = aws_scheduler_schedule.this.id
}

output "name" {
  description = "Resolved name of the schedule, including one generated from name_prefix."
  value       = aws_scheduler_schedule.this.name
}

output "group_name" {
  description = "Schedule group the schedule belongs to."
  value       = aws_scheduler_schedule.this.group_name
}

output "state" {
  description = "Whether the schedule is enabled or disabled, as applied."
  value       = aws_scheduler_schedule.this.state
}

output "schedule_expression" {
  description = "The applied schedule expression."
  value       = aws_scheduler_schedule.this.schedule_expression
}

output "schedule_expression_timezone" {
  description = "The applied schedule expression timezone."
  value       = aws_scheduler_schedule.this.schedule_expression_timezone
}

###########################
# Target Outputs
###########################

output "target_arn" {
  description = "ARN of the invoked target, read from the schedule's target block."
  value       = aws_scheduler_schedule.this.target[0].arn
}

output "target_role_arn" {
  description = "Resolved invoke role ARN, whether supplied via target_role_arn or created by this module."
  value       = local.target_role_arn
}

output "target_role_name" {
  description = "Name of the invoke role created by this module; null when the caller supplied target_role_arn."
  value       = local.create_target_role ? module.target_role[0].name : null
}

output "target_role_created" {
  description = "True when this module created the invoke role."
  value       = local.create_target_role
}

output "target_invoke_policy_arn" {
  description = "ARN of the generated invoke policy; null when the caller supplied target_role_arn."
  value       = local.create_target_role ? module.target_invoke_policy[0].arn : null
}

output "target_assume_role_policy_json" {
  description = "Generated trust policy document for the created invoke role; null when no role was created."
  value       = local.assume_role_policy_json
}

output "target_invoke_policy_json" {
  description = "Generated least-privilege invoke policy document; null when no role was created."
  value       = local.invoke_policy_json
}
