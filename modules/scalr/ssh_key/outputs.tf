###########################
# Scalr SSH Key
###########################

output "ids" {
  description = "Map of Scalr SSH key IDs, keyed by the same keys as var.ssh_keys."
  value       = { for k, v in scalr_ssh_key.this : k => v.id }
}

output "names" {
  description = "Map of the resolved SSH key names (after the name-defaults-to-key behavior is applied), keyed by the same keys as var.ssh_keys."
  value       = { for k, v in scalr_ssh_key.this : k => v.name }
}
