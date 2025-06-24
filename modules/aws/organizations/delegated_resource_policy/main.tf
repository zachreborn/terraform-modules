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
# AWS Organization Delegated Resource Policy
###########################################################

resource "aws_organizations_resource_policy" "this" {
  content = var.content
  tags    = var.tags
}
