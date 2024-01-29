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
# Role Configuration
##############################

resource "aws_iam_role" "this" {
  assume_role_policy    = var.assume_role_policy
  description           = var.description
  force_detach_policies = var.force_detach_policies
  max_session_duration  = var.max_session_duration
  name                  = var.name
  path                  = var.path
  permissions_boundary  = var.permissions_boundary
  tags                  = var.tags
}

##############################
# Policy Attachment Configuration
##############################

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = var.policy_arns
  policy_arn = each.key
  role       = aws_iam_role.this.name
}
