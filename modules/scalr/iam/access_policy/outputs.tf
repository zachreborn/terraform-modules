###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Access Policy IDs, keyed by the same keys as var.access_policies."
  value       = { for k, v in scalr_access_policy.this : k => v.id }
}

output "is_system" {
  description = "Map of booleans indicating whether each access policy is a built-in, read-only system policy that cannot be updated or deleted, keyed by the same keys as var.access_policies."
  value       = { for k, v in scalr_access_policy.this : k => v.is_system }
}
