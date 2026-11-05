###########################
# Resource Outputs
###########################
# Explicit non-sensitive projections only. The whole scalr_docker_integration object is
# deliberately NOT output because it carries the sensitive password attribute.
output "ids" {
  description = "Map of Scalr Docker integration IDs (in-<RANDOM STRING>) keyed by the same logical name used in var.docker_integrations. Pass an ID to the docker_integration_id of an OCI-sourced scalr_module."
  value       = { for key, value in scalr_docker_integration.this : key => value.id }
}

output "statuses" {
  description = "Map of Scalr Docker integration statuses, as reported by the latest registry connection test, keyed by the same logical name used in var.docker_integrations."
  value       = { for key, value in scalr_docker_integration.this : key => value.status }
}
