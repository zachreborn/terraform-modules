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
  for_each          = var.delegated_admins
  account_id        = each.key
  service_principal = each.value
}
