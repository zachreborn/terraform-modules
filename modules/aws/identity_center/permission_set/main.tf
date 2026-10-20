###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Data Sources
###########################

data "aws_ssoadmin_instances" "this" {}

data "aws_identitystore_group" "this" {
  for_each          = toset([for g in var.groups : g if !contains(keys(var.group_ids), g)])
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
  # Effective group display name -> group ID map: looked-up IDs (from the narrowed data source
  # above) merged with the caller-supplied group_ids (group_ids wins on key overlap). Every
  # downstream reference to a group's ID goes through this map instead of the data source directly,
  # so a group covered by group_ids never triggers a GetGroupId API call.
  group_id_map = merge(
    { for g, d in data.aws_identitystore_group.this : g => d.group_id },
    var.group_ids
  )
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

#updated to allow multiple managed policies
resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each           = var.managed_policy_arns != null ? toset(var.managed_policy_arns) : toset([])
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  managed_policy_arn = each.value
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

# One child module instance per group. The group name is the module instance key, and the
# target_accounts label is the resource key inside it, so the two-level address
#   module.group_assignments["<group>"].aws_ssoadmin_account_assignment.this["<label>"]
# is unique by construction -- no concatenation or encoding is needed.
#
# for_each uses toset(keys(...)) so only the (plan-time-known) group names are instance keys; the
# group IDs themselves -- which may be known only after apply -- flow through as plain inputs.
module "group_assignments" {
  source   = "./group_assignment"
  for_each = toset(keys(local.group_id_map))

  group_id           = local.group_id_map[each.key]
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  target_accounts    = var.target_accounts
}
