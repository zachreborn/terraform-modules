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
# Scalr Tag
###########################

resource "scalr_tag" "this" {
  for_each = var.tags

  name       = coalesce(each.value.name, each.key)
  account_id = each.value.account_id
}
