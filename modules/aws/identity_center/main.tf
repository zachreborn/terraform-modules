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

###########################
# Locals
###########################

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  group_membership = {
    for entry in flatten([
      for user_key, user in var.users : [
        for group in coalesce(user.groups, []) : {
          key    = "${user_key}-${group}"
          member = user_key
          group  = group
        }
      ]
    ]) : entry.key => entry
  }

  # Group display name -> Identity Store group ID, sourced directly from this module's own group
  # resources (a resource attribute, never a data source). Used to resolve permission_sets[*].group_keys
  # without ever triggering the eager aws_identitystore_group lookup that causes issue #456.
  group_id_map = { for k, v in aws_identitystore_group.this : k => v.group_id }
}

###########################
# Users Configuration
###########################

resource "aws_identitystore_user" "this" {
  for_each = var.users

  display_name       = each.key
  identity_store_id  = local.identity_store_id
  nickname           = each.value.nickname
  preferred_language = each.value.preferred_language
  timezone           = each.value.timezone
  title              = each.value.title
  user_name          = each.value.user_name
  user_type          = each.value.user_type

  emails {
    primary = each.value.email_is_primary
    value   = each.value.email
    type    = each.value.email_type
  }

  name {
    given_name       = each.value.given_name
    honorific_prefix = each.value.honorific_prefix
    honorific_suffix = each.value.honorific_suffix
    middle_name      = each.value.middle_name
    family_name      = each.value.family_name
  }

  phone_numbers {
    primary = each.value.phone_number_is_primary
    value   = each.value.phone_number
    type    = each.value.phone_number_type
  }
}

###########################
# Groups Configuration
###########################

resource "aws_identitystore_group" "this" {
  for_each          = var.groups
  description       = each.value.description
  display_name      = each.value.display_name
  identity_store_id = local.identity_store_id
}

resource "aws_identitystore_group_membership" "this" {
  for_each          = local.group_membership
  group_id          = aws_identitystore_group.this[each.value.group].group_id
  identity_store_id = local.identity_store_id
  member_id         = aws_identitystore_user.this[each.value.member].user_id
}

###########################
# Permission Sets
###########################

module "permission_sets" {
  source = "./permission_set"

  for_each = var.permission_sets

  name        = coalesce(each.value.name, each.key)
  description = each.value.description
  groups      = toset(coalesce(each.value.groups, []))
  # A group_keys entry not found in var.groups is filtered out here (rather than passed through as a
  # null value) so the permission_set submodule's own generic group_ids validation never trips on it --
  # the permission_set_resolved_group_keys output (outputs.tf) carries a precondition that is solely
  # responsible for surfacing that misconfiguration, with one clear, actionable message.
  group_ids = {
    for k in coalesce(each.value.group_keys, []) : k => local.group_id_map[k]
    if contains(keys(local.group_id_map), k)
  }
  customer_managed_iam_policy_name = each.value.customer_managed_iam_policy_name
  customer_managed_iam_policy_path = each.value.customer_managed_iam_policy_path
  inline_policy                    = each.value.inline_policy
  managed_policy_arns              = each.value.managed_policy_arns
  relay_state                      = each.value.relay_state
  session_duration                 = each.value.session_duration
  target_accounts                  = each.value.target_accounts
  tags                             = each.value.tags
}
