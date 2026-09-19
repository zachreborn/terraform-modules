###########################
# Resource Outputs
###########################

output "id" {
  description = "The ID of the capacity provider."
  value       = aws_ecs_capacity_provider.this.id
}

output "name" {
  description = "The name of the capacity provider."
  value       = aws_ecs_capacity_provider.this.name
}

output "arn" {
  description = "The ARN that identifies the capacity provider."
  value       = aws_ecs_capacity_provider.this.arn
}
