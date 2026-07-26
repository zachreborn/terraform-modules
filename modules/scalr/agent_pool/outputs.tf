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

output "token_agent_pool_ids" {
  description = "Map of the agent_pool_id actually passed to each scalr_agent_pool_token resource (from the composed ./token submodule), keyed by the same keys as var.agent_pool_tokens. Useful for callers/tests that need to prove which agent pool was actually wired into each token."
  value       = module.token.agent_pool_ids
}

output "tokens" {
  description = "Map of the actual agent pool token secret values, keyed by the same keys as var.agent_pool_tokens. Sensitive."
  value       = module.token.tokens
  sensitive   = true
}
