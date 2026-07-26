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
# Locals
###########################

locals {
  # Resolve each agent_pool_tokens entry's agent_pool_id: a literal agent_pool_id passes through
  # unchanged; an agent_pool_key looks up the ID of a scalr_agent_pool created by this same module call.
  agent_pool_tokens_resolved = {
    for k, v in var.agent_pool_tokens : k => {
      agent_pool_id = v.agent_pool_id != null ? v.agent_pool_id : scalr_agent_pool.this[v.agent_pool_key].id
      description   = v.description
    }
  }
}

###########################
# Scalr Agent Pool
###########################

resource "scalr_agent_pool" "this" {
  for_each = var.agent_pools

  name            = coalesce(each.value.name, each.key)
  account_id      = each.value.account_id
  environment_id  = each.value.environment_id
  environments    = each.value.environments
  vcs_enabled     = each.value.vcs_enabled
  api_gateway_url = each.value.api_gateway_url

  dynamic "header" {
    for_each = each.value.headers
    content {
      name = header.value.name
      # Sensitive header values are never read from the non-sensitive headers.value.value (the
      # provider's sensitive flag only controls masking in the Scalr UI, not in Terraform/OpenTofu
      # plan output) -- they must be supplied via var.agent_pool_header_values instead, keyed by
      # this agent pool's logical name (each.key) and the header's own name.
      value     = header.value.sensitive ? try(var.agent_pool_header_values[each.key][header.value.name], null) : header.value.value
      sensitive = header.value.sensitive
    }
  }
}

###########################
# Scalr Agent Pool Tokens (composition)
###########################

module "token" {
  source = "./token"

  agent_pool_tokens = local.agent_pool_tokens_resolved
}
