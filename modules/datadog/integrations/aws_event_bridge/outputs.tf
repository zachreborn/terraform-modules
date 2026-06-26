###########################
# Resource Outputs
###########################
output "event_bridge_ids" {
  description = "Map of EventBridge integration IDs keyed by logical name."
  value       = { for k, v in datadog_integration_aws_event_bridge.this : k => v.id }
}
