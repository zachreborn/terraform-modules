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
# Locals
##############################

locals {
  policy_map = { for idx, policy_arn in var.policy_arns : policy => {
    name       = "policy-${idx}"
    policy_arn = policy_arn
  } }
}

##############################
# Role Configuration
##############################

resource "aws_iam_role" "this" {
  assume_role_policy    = var.assume_role_policy
  description           = var.description
  force_detach_policies = var.force_detach_policies
  max_session_duration  = var.max_session_duration
  name_prefix           = var.name_prefix
  path                  = var.path
  permissions_boundary  = var.permissions_boundary
  tags                  = var.tags
}

##############################
# Policy Attachment Configuration
##############################

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = local.policy_map
  policy_arn = each.key
  role       = aws_iam_role.this.name
}
