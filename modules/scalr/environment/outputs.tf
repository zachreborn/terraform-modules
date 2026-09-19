###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Environment IDs, keyed by the same keys as var.environments."
  value       = { for k, v in scalr_environment.this : k => v.id }
}

output "status" {
  description = "Map of the status of each environment, keyed by the same keys as var.environments."
  value       = { for k, v in scalr_environment.this : k => v.status }
}

output "policy_groups" {
  description = "Map of the list of policy-group IDs associated with each environment, keyed by the same keys as var.environments."
  value       = { for k, v in scalr_environment.this : k => v.policy_groups }
}

output "created_by" {
  description = "Map of the details (email, full_name, username) of the user that created each environment, keyed by the same keys as var.environments."
  value       = { for k, v in scalr_environment.this : k => v.created_by }
}
