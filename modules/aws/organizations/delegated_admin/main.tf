terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################################################
# AWS Organization Delegated Administrator
###########################################################

resource "aws_organizations_delegated_administrator" "this" {
  for_each = merge([
    for admin_key, admin in var.delegated_admins : {
      for service in admin.services : "${admin_key}-${service}" => {
        account_id  = admin.account_key != null ? lookup(var.account_ids, admin.account_key, null) : admin.account_id
        account_key = admin.account_key
        service     = service
      }
    }
  ]...)
  account_id        = each.value.account_id
  service_principal = each.value.service

  lifecycle {
    precondition {
      condition     = each.value.account_key == null || contains(keys(var.account_ids), each.value.account_key)
      error_message = "account_key \"${each.value.account_key != null ? each.value.account_key : "(none)"}\" was not found in var.account_ids. Pass a map of account IDs (e.g. the account submodule's `ids` output) through as account_ids, or check for typos."
    }
  }
}
