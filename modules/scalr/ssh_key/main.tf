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
# Scalr SSH Key
###########################

resource "scalr_ssh_key" "this" {
  for_each = var.ssh_keys

  name         = coalesce(each.value.name, each.key)
  private_key  = lookup(var.private_keys, each.key, null)
  account_id   = each.value.account_id
  environments = each.value.environments
}
