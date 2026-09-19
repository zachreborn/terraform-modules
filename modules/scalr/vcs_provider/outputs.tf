###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of VCS Provider IDs, keyed by the same keys as var.vcs_providers."
  value       = { for k, v in scalr_vcs_provider.this : k => v.id }
}
