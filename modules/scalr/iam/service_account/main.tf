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
locals {
  service_account_ids = { for k, v in scalr_service_account.this : k => v.id }
}

###########################
# Service Accounts
###########################
resource "scalr_service_account" "this" {
  for_each = var.service_accounts

  name        = coalesce(each.value.name, each.key)
  account_id  = each.value.account_id != null ? each.value.account_id : var.account_id
  description = each.value.description
  owners      = each.value.owners
  status      = each.value.status
}

###########################
# Service Account Tokens
###########################
module "tokens" {
  source = "./token"

  tokens              = var.tokens
  service_account_ids = local.service_account_ids
}

###########################
# Assume Service Account Policies
###########################
module "assume_policies" {
  source = "./assume_policy"

  assume_policies     = var.assume_policies
  service_account_ids = local.service_account_ids
}
