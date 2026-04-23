###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.0"
    }
  }
}

###########################
# Locals
###########################

###########################
# Hook Registry Configurations
###########################
resource "scalr_hook" "this" {
  for_each        = var.hooks
  description     = each.value.description
  interpreter     = each.value.interpreter != null ? each.value.interpreter : var.interpreter
  name            = each.value.name != null ? each.value.name : each.key
  scriptfile_path = each.value.scriptfile_path
  vcs_provider_id = each.value.vcs_provider_id != null ? each.value.vcs_provider_id : var.vcs_provider_id

  dynamic "vcs_repo" {
    for_each = each.value.vcs_repo != null || var.vcs_repo_identifier != null ? [1] : []
    content {
      identifier = each.value.vcs_repo != null ? each.value.vcs_repo.identifier : var.vcs_repo_identifier
      branch     = each.value.vcs_repo != null && each.value.vcs_repo.branch != null ? each.value.vcs_repo.branch : var.vcs_repo_branch
    }
  }
}
