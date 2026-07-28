###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

###########################
# Data Sources
###########################


###########################
# Locals
###########################

###########################
# Module Configuration
###########################
resource "scalr_hook" "this" {
  for_each        = var.hooks
  name            = each.value.name
  interpreter     = each.value.interpreter
  scriptfile_path = each.value.scriptfile_path
  vcs_provider_id = each.value.vcs_provider_id
  description     = each.value.description

  vcs_repo {
    identifier = each.value.vcs_repo.identifier
    branch     = each.value.vcs_repo.branch
  }
}
