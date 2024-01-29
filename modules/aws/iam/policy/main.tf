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
# Policy Configuration
##############################

resource "aws_iam_policy" "this" {
  description = var.description
  name        = var.name
  path        = var.path
  policy      = var.policy
  tags        = var.tags
}
