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
# Scalr VCS Provider
###########################
resource "scalr_vcs_provider" "this" {
  for_each = var.vcs_providers

  name                      = coalesce(each.value.name, each.key)
  account_id                = each.value.account_id != null ? each.value.account_id : var.account_id
  agent_pool_id             = each.value.agent_pool_id
  comments_enabled          = each.value.comments_enabled
  draft_pr_runs_enabled     = each.value.draft_pr_runs_enabled
  environments              = each.value.environments
  pr_merge_comments_enabled = each.value.pr_merge_comments_enabled
  # Safe lookup (rather than var.vcs_provider_tokens[each.key]) so a missing token surfaces the
  # clear precondition error below instead of a cryptic "Invalid index" error.
  token    = lookup(var.vcs_provider_tokens, each.key, null)
  url      = each.value.url
  username = each.value.username
  vcs_type = each.value.vcs_type

  lifecycle {
    # The upstream provider requires a token for every VCS provider, and the token is supplied via
    # the separate var.vcs_provider_tokens map. Fail fast with an actionable message naming the key
    # that is missing its token rather than letting a null token reach the provider.
    precondition {
      condition     = contains(keys(var.vcs_provider_tokens), each.key)
      error_message = "vcs_providers[\"${each.key}\"] has no matching entry in var.vcs_provider_tokens. Every VCS provider requires a token; add an entry keyed \"${each.key}\" to vcs_provider_tokens."
    }
  }
}
