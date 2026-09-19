###########################
# Resource Outputs
###########################

output "arn" {
  description = "The full ARN of the task definition (including revision)."
  value       = aws_ecs_task_definition.this.arn
}

output "arn_without_revision" {
  description = "The ARN of the task definition without the revision number."
  value       = aws_ecs_task_definition.this.arn_without_revision
}

output "family" {
  description = "The family of the task definition."
  value       = aws_ecs_task_definition.this.family
}

output "revision" {
  description = "The revision of the task definition."
  value       = aws_ecs_task_definition.this.revision
}

output "execution_role_arn" {
  description = "The ARN of the task execution role (created or passed through)."
  value       = local.execution_role_arn
}

output "task_role_arn" {
  description = "The ARN of the task role (created or passed through)."
  value       = local.task_role_arn
}
