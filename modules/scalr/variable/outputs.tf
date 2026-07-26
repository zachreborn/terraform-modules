###########################
# Scalr Variable
###########################

output "ids" {
  description = "Map of Scalr variable IDs, keyed by the same keys as var.variables."
  value       = { for k, v in scalr_variable.this : k => v.id }
}

output "readable_values" {
  description = "Map of the non-sensitive read-only copy of each variable's value, keyed by the same keys as var.variables. Per the Scalr provider, this is null for any entry where sensitive = true."
  value       = { for k, v in scalr_variable.this : k => v.readable_value }
}

output "updated_at" {
  description = "Map of the last-updated timestamps, keyed by the same keys as var.variables."
  value       = { for k, v in scalr_variable.this : k => v.updated_at }
}

output "updated_by_email" {
  description = "Map of the email address of the user who last updated each variable, keyed by the same keys as var.variables."
  value       = { for k, v in scalr_variable.this : k => v.updated_by_email }
}
