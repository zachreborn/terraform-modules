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
  # This translates the policy_arns list into a map of objects that can be used by the aws_iam_role_policy_attachment resource. This is needed
  # in order to utilize `for_each` when using policies which have not yet been created within modules.
  # Example Output:
  # {
  #   "policy-0" = {
  #     name       = "policy-0"
  #     policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  #   },
  #   "policy-1" = {
  #     name       = "policy-1"
  #     policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  #   }
  # }
  policy_map = { for idx, policy_arn in var.policy_arns : "policy-${idx}" => {
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
  policy_arn = each.key.policy_arn
  role       = aws_iam_role.this.name
}
