###########################
# Resource Outputs
###########################
output "cloudflare_account_ids" {
  description = "Map of Cloudflare integration IDs keyed by logical name."
  value       = { for k, v in datadog_integration_cloudflare_account.this : k => v.id }
}
