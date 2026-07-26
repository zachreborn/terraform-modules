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
# Data Sources
###########################


###########################
# Locals
###########################


###########################
# Module Configuration
###########################
resource "scalr_role" "this" {
  for_each = var.roles

  name        = coalesce(each.value.name, each.key)
  permissions = each.value.permissions
  account_id  = each.value.account_id != null ? each.value.account_id : var.account_id
  description = each.value.description
}
