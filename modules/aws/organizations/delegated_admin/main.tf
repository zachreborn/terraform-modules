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
        account_id        = admin.account_id
        service_principal = service
      }
    }
  ]...)
  account_id        = each.value.account_id
  service_principal = each.value.service_principal
}
