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
  token                     = var.vcs_provider_tokens[each.key]
  url                       = each.value.url
  username                  = each.value.username
  vcs_type                  = each.value.vcs_type
}
