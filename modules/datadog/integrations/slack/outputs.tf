###########################
# Resource Outputs
###########################
output "slack_channel_ids" {
  description = "Map of Slack channel integration IDs keyed by logical name."
  value       = { for k, v in datadog_integration_slack_channel.this : k => v.id }
}
