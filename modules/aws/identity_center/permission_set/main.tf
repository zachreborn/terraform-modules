###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Data Sources
###########################

data "aws_ssoadmin_instances" "this" {}

data "aws_identitystore_group" "this" {
  for_each          = var.groups
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  alternate_identifier {
    unique_attribute {
      attribute_path  = var.group_attribute_path
      attribute_value = each.key
    }
  }
}

###########################
# Locals
###########################

locals {
  # TODO Create a map of groups and accounts to use with for_each for assignment
  # groupname_accountid = {
  # group = group_id
  # account = account_id
  # }
  group_ids = {
    for group in var.groups : group => data.aws_identitystore_group.this[group].group_id
  }
  #   {
  #     "admins" = "1234",
  #     "terraform" = "5678"
  #   }
  #  [
  #     "12345678",
  #     "87654321",
  #     "940821941"
  #  ]
  # for group in groups {
  # for account in target_accounts {
  # groupname_accountid = {
  # group = group_id
  # account = account_id
  # }

  assignments = {
    for item in flatten([
      for group in var.groups : [
        for account in var.target_accounts : {
          group_id   = data.aws_identitystore_group.this[group].group_id
          account_id = account
        }
      ]
    ]) : "${item.group_id}_${item.account_id}" => item
  }
}

###########################
# Permission Set
###########################

resource "aws_ssoadmin_permission_set" "this" {
  name             = var.name
  description      = var.description
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  relay_state      = var.relay_state
  session_duration = var.session_duration
  tags             = merge(var.tags, { "Name" = var.name })
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "this" {
  count              = var.customer_managed_iam_policy_name != null ? 1 : 0
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  customer_managed_policy_reference {
    name = var.customer_managed_iam_policy_name
    path = var.customer_managed_iam_policy_path
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  count              = var.managed_policy_arn != null ? 1 : 0
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  managed_policy_arn = var.managed_policy_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  count              = var.inline_policy != null ? 1 : 0
  inline_policy      = var.inline_policy
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
}

###########################
# Account Assignments
###########################

resource "aws_ssoadmin_account_assignment" "this" {
  # TODO for_each needs to be target accounts as well as group_ids
  for_each           = local.assignments
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  # principal_id   = data.aws_identitystore_group.this.group_id
  principal_id   = each.value.group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}
