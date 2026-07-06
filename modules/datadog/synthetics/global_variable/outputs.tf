###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of global variable IDs keyed by logical name."
  value       = { for k, v in datadog_synthetics_global_variable.this : k => v.id }
}
