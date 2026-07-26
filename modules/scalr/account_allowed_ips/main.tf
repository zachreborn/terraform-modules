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
resource "scalr_account_allowed_ips" "this" {
  for_each    = var.account_allowed_ips
  account_id  = try(coalesce(each.value.account_id, var.account_id), null)
  allowed_ips = each.value.allowed_ips
}
