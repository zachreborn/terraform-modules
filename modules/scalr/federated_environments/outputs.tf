###########################
# Resource Outputs
###########################
# Note: scalr_federated_environments does not expose a separate read-only `id` attribute in the
# upstream provider's documented schema (unlike most other Scalr resources) -- it is keyed
# entirely by environment_id. These pass-through outputs are exposed instead of `.id` so callers
# and tests do not depend on an attribute the schema does not document.
output "environment_ids" {
  description = "Map of the hub environment_id managed by each entry, keyed by the same keys as var.federated_environments."
  value       = { for k, v in scalr_federated_environments.this : k => v.environment_id }
}

output "federated_environment_sets" {
  description = "Map of the federated_environments set managed by each entry, keyed by the same keys as var.federated_environments."
  value       = { for k, v in scalr_federated_environments.this : k => v.federated_environments }
}
