###########################
# Resource Outputs
###########################

output "ids" {
  description = "Map of metric logical name to RUM metric ID."
  value       = { for k, v in datadog_rum_metric.this : k => v.id }
}
