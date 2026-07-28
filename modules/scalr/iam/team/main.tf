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
resource "scalr_iam_team" "this" {
  for_each = var.teams

  name                 = coalesce(each.value.name, each.key)
  account_id           = each.value.account_id != null ? each.value.account_id : var.account_id
  description          = each.value.description
  identity_provider_id = each.value.identity_provider_id
  users                = each.value.users
}
