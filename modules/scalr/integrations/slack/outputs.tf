###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Slack integration IDs keyed by the same logical name used in var.slack_integrations."
  value       = { for key, value in scalr_slack_integration.this : key => value.id }
}

output "slack_integrations" {
  description = "Map of full scalr_slack_integration resource objects keyed by the same logical name used in var.slack_integrations."
  value       = { for key, value in scalr_slack_integration.this : key => value }
}
