###########################
# Scalr Storage Profile
###########################

output "ids" {
  description = "Map of Scalr storage profile IDs, keyed by the same keys as var.storage_profiles."
  value       = { for k, v in scalr_storage_profile.this : k => v.id }
}

output "error_messages" {
  description = "Map of the last error description for each storage profile (non-null only when the backend settings don't work properly), keyed by the same keys as var.storage_profiles."
  value       = { for k, v in scalr_storage_profile.this : k => v.error_message }
}

output "created_at" {
  description = "Map of the resource creation timestamps, keyed by the same keys as var.storage_profiles."
  value       = { for k, v in scalr_storage_profile.this : k => v.created_at }
}
