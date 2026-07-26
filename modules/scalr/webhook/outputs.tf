###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr webhook IDs keyed by the same logical name used in var.webhooks."
  value       = { for key, value in scalr_webhook.this : key => value.id }
}

output "webhooks" {
  description = "Map of scalr_webhook resource objects (excluding the write-only, provider-sensitive secret_key attribute) keyed by the same logical name used in var.webhooks."
  value = {
    for key, value in scalr_webhook.this : key => {
      id                = value.id
      name              = value.name
      url               = value.url
      events            = value.events
      account_id        = value.account_id
      enabled           = value.enabled
      environments      = value.environments
      max_attempts      = value.max_attempts
      timeout           = value.timeout
      last_triggered_at = value.last_triggered_at
    }
  }
}

output "secret_keys" {
  description = "Map of the resolved secret_key for each webhook -- either the caller-supplied value from var.webhook_secret_keys, or the value Scalr generated automatically when it was omitted -- keyed by the same logical name used in var.webhooks. Sensitive."
  value       = { for key, value in scalr_webhook.this : key => value.secret_key }
  sensitive   = true
}
