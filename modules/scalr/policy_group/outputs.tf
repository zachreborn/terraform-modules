###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Policy Group IDs, keyed by the same keys as var.policy_groups."
  value       = { for k, v in scalr_policy_group.this : k => v.id }
}

output "statuses" {
  description = "Map of Policy Group system statuses, keyed by the same keys as var.policy_groups."
  value       = { for k, v in scalr_policy_group.this : k => v.status }
}

output "error_messages" {
  description = "Map of detailed Policy Group processing error messages (if any), keyed by the same keys as var.policy_groups."
  value       = { for k, v in scalr_policy_group.this : k => v.error_message }
}

output "policies" {
  description = "Map of the list of OPA policies each Policy Group verifies, keyed by the same keys as var.policy_groups."
  value       = { for k, v in scalr_policy_group.this : k => v.policies }
}

output "linkage_ids" {
  description = "Map of Policy Group Linkage IDs (from the companion ./linkage submodule), keyed by the same keys as var.policy_group_linkages."
  value       = module.linkage.ids
}

output "resolved_linkages" {
  description = "Map of policy_group_id/environment_id pairs actually passed to the companion ./linkage submodule, keyed by the same keys as var.policy_group_linkages. Useful to verify composition wiring."
  value       = local.resolved_linkages
}
