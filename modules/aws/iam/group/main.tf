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
  group_policies = {
    for item in flatten([
      for group, value in var.groups : [
        for policy in value.policy_arns : {
          group      = group
          policy_arn = policy
        }
      ]
    ]) : "${item.group}_${item.policy_arn}" => item
  }
}

##############################
# Group Configuration
##############################

resource "aws_iam_group" "this" {
  for_each = var.groups
  name     = each.key
}

##############################
# Policy Attachment Configuration
##############################

resource "aws_iam_group_policy_attachment" "this" {
  for_each   = local.group_policies
  group      = each.value.group
  policy_arn = each.value.policy_arn
}
