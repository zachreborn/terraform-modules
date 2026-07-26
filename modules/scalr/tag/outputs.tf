###########################
# Scalr Tag
###########################

output "ids" {
  description = "Map of Scalr tag IDs, keyed by the same keys as var.tags."
  value       = { for k, v in scalr_tag.this : k => v.id }
}

output "names" {
  description = "Map of the resolved tag names (after the name-defaults-to-key behavior is applied), keyed by the same keys as var.tags."
  value       = { for k, v in scalr_tag.this : k => v.name }
}
