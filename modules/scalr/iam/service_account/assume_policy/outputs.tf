###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Assume Service Account Policy IDs, keyed by the same keys as var.assume_policies."
  value       = { for k, v in scalr_assume_service_account_policy.this : k => v.id }
}
