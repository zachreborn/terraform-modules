###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

###########################
# Scalr Agent Pool Token
###########################

resource "scalr_agent_pool_token" "this" {
  for_each = var.agent_pool_tokens

  agent_pool_id = each.value.agent_pool_id
  description   = each.value.description
}
