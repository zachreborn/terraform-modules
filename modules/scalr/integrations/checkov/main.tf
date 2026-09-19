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
resource "scalr_checkov_integration" "this" {
  for_each                = var.checkov_integrations
  name                    = each.value.name
  cli_args                = each.value.cli_args
  environments            = each.value.environments
  external_checks_enabled = each.value.external_checks_enabled
  vcs_provider_id         = each.value.vcs_provider_id
  version                 = each.value.version

  dynamic "vcs_repo" {
    for_each = each.value.vcs_repo != null ? [each.value.vcs_repo] : []
    content {
      identifier = vcs_repo.value.identifier
      branch     = vcs_repo.value.branch
      path       = vcs_repo.value.path
    }
  }
}
