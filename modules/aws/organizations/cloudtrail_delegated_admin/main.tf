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
# AWS CloudTrail Organization Delegated Administrator
###########################################################

resource "aws_cloudtrail_organization_delegated_admin_account" "this" {
  account_id = var.account_id
}
