###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr EventBridge integration IDs keyed by the same logical name used in var.event_bridge_integrations."
  value       = { for key, value in scalr_event_bridge_integration.this : key => value.id }
}

output "event_source_arns" {
  description = "Map of the EventBridge event source ARNs keyed by the same logical name used in var.event_bridge_integrations. Accept this event source as an EventBridge partner event source in the target AWS account/region."
  value       = { for key, value in scalr_event_bridge_integration.this : key => value.event_source_arn }
}

output "event_source_names" {
  description = "Map of the EventBridge event source names keyed by the same logical name used in var.event_bridge_integrations."
  value       = { for key, value in scalr_event_bridge_integration.this : key => value.event_source_name }
}

output "event_bridge_integrations" {
  description = "Map of full scalr_event_bridge_integration resource objects keyed by the same logical name used in var.event_bridge_integrations."
  value       = { for key, value in scalr_event_bridge_integration.this : key => value }
}
