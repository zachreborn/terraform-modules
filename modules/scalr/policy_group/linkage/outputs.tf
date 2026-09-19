###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Policy Group Linkage IDs, keyed by the same keys as var.linkages."
  value       = { for k, v in scalr_policy_group_linkage.this : k => v.id }
}
