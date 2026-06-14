###########################
# Cluster Outputs
###########################

output "cluster_id" {
  description = "The ID (ARN) of the ECS cluster."
  value       = module.cluster.id
}

output "cluster_arn" {
  description = "The ARN that identifies the ECS cluster."
  value       = module.cluster.arn
}

output "cluster_name" {
  description = "The name of the ECS cluster."
  value       = module.cluster.name
}

###########################
# Namespace Outputs
###########################

output "namespace_id" {
  description = "The ID of the created Cloud Map namespace, when created."
  value       = local.create_namespace ? module.namespace[0].id : null
}

output "namespace_arn" {
  description = "The effective Cloud Map namespace ARN (created or passed through)."
  value       = local.namespace_arn
}

###########################
# Task Definition Outputs
###########################

output "task_definition_arns" {
  description = "Map of task-definition ARNs keyed by the `task_definitions` map key."
  value       = { for k, m in module.task_definition : k => m.arn }
}

###########################
# Service Outputs
###########################

output "service_ids" {
  description = "Map of service ARNs keyed by the `services` map key."
  value       = { for k, m in module.service : k => m.id }
}

output "service_names" {
  description = "Map of service names keyed by the `services` map key."
  value       = { for k, m in module.service : k => m.name }
}

###########################
# Composition Passthrough Outputs
###########################

output "kms_key_arn" {
  description = "The ARN of the CMK created by the cluster submodule for exec-command logging, when created."
  value       = module.cluster.kms_key_arn
}

output "cloud_watch_log_group_name" {
  description = "The name of the exec-command CloudWatch log group created by the cluster submodule, when created."
  value       = module.cluster.cloud_watch_log_group_name
}
