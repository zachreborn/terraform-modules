###########################
# Scalr Agent Pool Token
###########################

output "ids" {
  description = "Map of Scalr agent pool token resource IDs, keyed by the same keys as var.agent_pool_tokens."
  value       = { for k, v in scalr_agent_pool_token.this : k => v.id }
}

output "tokens" {
  description = "Map of the actual agent pool token secret values, keyed by the same keys as var.agent_pool_tokens. Sensitive."
  value       = { for k, v in scalr_agent_pool_token.this : k => v.token }
  sensitive   = true
}
