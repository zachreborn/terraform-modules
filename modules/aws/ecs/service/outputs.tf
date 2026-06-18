###########################
# Resource Outputs
###########################

output "id" {
  description = "The ARN that identifies the ECS service."
  value       = one(concat(aws_ecs_service.this[*].id, aws_ecs_service.ignore_desired_count[*].id))
}

output "name" {
  description = "The name of the ECS service."
  value       = one(concat(aws_ecs_service.this[*].name, aws_ecs_service.ignore_desired_count[*].name))
}

output "cluster" {
  description = "The ARN of the cluster the service runs on."
  value       = one(concat(aws_ecs_service.this[*].cluster, aws_ecs_service.ignore_desired_count[*].cluster))
}

output "desired_count" {
  description = "The number of instances of the task definition the service maintains."
  value       = one(concat(aws_ecs_service.this[*].desired_count, aws_ecs_service.ignore_desired_count[*].desired_count))
}

output "security_group_id" {
  description = "The ID of the service security group, when created via composition."
  value       = var.create_security_group ? module.security_group[0].id : null
}
