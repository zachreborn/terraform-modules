###########################
# Scalr Agent Pool
###########################

output "ids" {
  description = "Map of Scalr agent pool IDs, keyed by the same keys as var.agent_pools."
  value       = { for k, v in scalr_agent_pool.this : k => v.id }
}

###########################
# Scalr Agent Pool Tokens
###########################

output "token_ids" {
  description = "Map of agent pool token resource IDs, keyed by the same keys as var.agent_pool_tokens."
  value       = module.token.ids
}

output "tokens" {
  description = "Map of the actual agent pool token secret values, keyed by the same keys as var.agent_pool_tokens. Sensitive."
  value       = module.token.tokens
  sensitive   = true
}
