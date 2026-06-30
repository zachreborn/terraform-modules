###########################
# Resource Outputs
###########################
output "opsgenie_service_object_ids" {
  description = "Map of Opsgenie service object IDs keyed by logical name."
  value       = { for k, v in datadog_integration_opsgenie_service_object.this : k => v.id }
}
