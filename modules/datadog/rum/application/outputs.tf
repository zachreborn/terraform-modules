###########################
# Resource Outputs
###########################

output "ids" {
  description = "Map of application logical name to RUM application ID."
  value       = { for k, v in datadog_rum_application.this : k => v.id }
}

output "client_tokens" {
  description = "Map of application logical name to client token. Sensitive — do not log."
  value       = { for k, v in datadog_rum_application.this : k => v.client_token }
  sensitive   = true
}

output "api_key_ids" {
  description = "Map of application logical name to the ID of the API key associated with the application."
  value       = { for k, v in datadog_rum_application.this : k => v.api_key_id }
}
