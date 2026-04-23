###########################
# Resource Outputs
###########################
output "hook_ids" {
  description = "Map of hook keys to their Scalr hook IDs in the format 'hook-<RANDOM STRING>'."
  value       = { for k, v in scalr_hook.this : k => v.id }
}

output "hook_names" {
  description = "Map of hook keys to their registered Scalr hook names."
  value       = { for k, v in scalr_hook.this : k => v.name }
}
