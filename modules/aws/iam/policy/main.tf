##############################
# Provider Configuration
##############################

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

##############################
# Policy Configuration
##############################

resource "aws_iam_policy" "this" {
  description = var.description
  name        = var.name_prefix == null ? var.name : null
  name_prefix = var.name_prefix != null ? var.name_prefix : null
  path        = var.path
  policy      = var.policy
  tags        = var.tags
}
