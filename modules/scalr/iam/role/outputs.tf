###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Role IDs, keyed by the same keys as var.roles."
  value       = { for k, v in scalr_role.this : k => v.id }
}

output "is_system" {
  description = "Map of booleans indicating whether each role is a built-in system role maintained by Scalr (and therefore cannot be edited), keyed by the same keys as var.roles."
  value       = { for k, v in scalr_role.this : k => v.is_system }
}
