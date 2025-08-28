terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

###########################################################
# AWS Organization Delegated Administrator
###########################################################

resource "aws_organizations_delegated_administrator" "this" {
  for_each = merge([
    for account_id, services in var.delegated_admins : {
      for service in services : "${account_id}-${service}" => {
        account_id        = account_id
        service_principal = service
      }
    }
  ]...)
  account_id        = each.value.account_id
  service_principal = each.value.service_principal
}
