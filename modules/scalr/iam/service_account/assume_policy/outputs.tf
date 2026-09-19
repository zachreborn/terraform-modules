###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Assume Service Account Policy IDs, keyed by the same keys as var.assume_policies."
  value       = { for k, v in scalr_assume_service_account_policy.this : k => v.id }
}

output "service_account_ids" {
  description = "Map of the service_account_id actually passed to each scalr_assume_service_account_policy resource, keyed by the same keys as var.assume_policies. Useful for callers/tests that need to prove which service account was actually wired into each policy."
  value       = { for k, v in scalr_assume_service_account_policy.this : k => v.service_account_id }
}
