##############################
# Provider Configuration
##############################

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

##############################
# User Configuration
##############################

resource "aws_iam_user" "this" {
  force_destroy        = var.force_destroy
  name                 = var.name
  path                 = var.path
  permissions_boundary = var.permissions_boundary
}
