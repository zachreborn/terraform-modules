terraform {
  # >= 1.3.0: expression-valued error_message in the tags validation blocks below requires >= 1.2.0,
  # and the object-attribute defaults already used in variables.tf (optional(<type>, <default>))
  # require >= 1.3.0. The aws provider constraint is unchanged -- no provider feature is involved.
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

############################################################
# AWS Organization Account
############################################################

resource "aws_organizations_account" "this" {
  for_each = var.accounts

  name                       = coalesce(each.value.name, each.key)
  email                      = each.value.email
  iam_user_access_to_billing = each.value.iam_user_access_to_billing
  parent_id                  = each.value.parent_key != null ? lookup(var.organizational_unit_ids, each.value.parent_key, null) : each.value.parent_id
  role_name                  = each.value.role_name
  close_on_deletion          = each.value.close_on_deletion
  tags                       = merge(var.tags, each.value.tags)

  lifecycle {
    ignore_changes = [role_name]

    precondition {
      condition     = each.value.parent_key == null || contains(keys(var.organizational_unit_ids), each.value.parent_key)
      error_message = "parent_key \"${each.value.parent_key != null ? each.value.parent_key : "(none)"}\" was not found in var.organizational_unit_ids. Pass the OU module's `ids` output through as organizational_unit_ids."
    }
  }
}
