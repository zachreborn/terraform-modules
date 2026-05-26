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
# AWS Organization Policy
###########################################################

resource "aws_organizations_policy" "this" {
  content      = var.content
  description  = var.description
  name         = var.name
  skip_destroy = var.skip_destroy
  tags         = var.tags
  type         = var.type
}
