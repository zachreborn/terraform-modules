###########################
# Resource Outputs
###########################

output "id" {
  description = "The ID (ARN) of the ECS cluster."
  value       = aws_ecs_cluster.this.id
}

output "arn" {
  description = "The ARN that identifies the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "name" {
  description = "The name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "kms_key_arn" {
  description = "The ARN of the CMK created for exec-command logging and managed storage encryption, when created."
  value       = var.create_kms_key ? module.kms[0].arn : null
}

output "cloud_watch_log_group_name" {
  description = "The name of the exec-command CloudWatch log group, when created."
  value       = local.create_log_group ? module.log_group[0].name : null
}

output "cloud_watch_log_group_arn" {
  description = "The ARN of the exec-command CloudWatch log group, when created."
  value       = local.create_log_group ? module.log_group[0].arn : null
}
