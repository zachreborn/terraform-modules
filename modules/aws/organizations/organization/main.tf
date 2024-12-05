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
# AWS Organization
###########################################################

resource "aws_organizations_organization" "org" {
  aws_service_access_principals = var.aws_service_access_principals
  enabled_policy_types          = var.enabled_policy_types
  feature_set                   = var.feature_set

  lifecycle {
    prevent_destroy = true
  }
}

###########################################################
# AWS Organization Delegated Administrator
###########################################################

resource "aws_organizations_delegated_administrator" "this" {
  for_each          = var.delegated_administrators != null ? var.delegated_administrators : {}
  account_id        = each.key
  service_principal = each.value
}
