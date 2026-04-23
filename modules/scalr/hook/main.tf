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
  interpreter     = try(each.value.interpreter, var.interpreter)
  name            = try(each.value.name, each.key)
  scriptfile_path = each.value.scriptfile_path
  vcs_provider_id = try(each.value.vcs_provider_id, var.vcs_provider_id)

  dynamic "vcs_repo" {
    for_each = try(each.value.vcs_repo, null) != null || var.vcs_repo_identifier != null ? [1] : []
    content {
      identifier = try(each.value.vcs_repo.identifier, var.vcs_repo_identifier)
      branch     = try(each.value.vcs_repo.branch, var.vcs_repo_branch)
    }
  }
}
