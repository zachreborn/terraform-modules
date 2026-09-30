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
# Account Assignments
###########################

# One instance of this module exists per group. Because each group already has its own module
# instance address -- module.group_assignments["<group>"] -- the resource key here only needs to be
# unique WITHIN a single group, so the caller's target_accounts label is used directly. There is no
# string concatenation or encoding anywhere, so distinct (group, label) pairs cannot collide by
# construction, and the label is free to contain any characters.
#
# The label (never the account ID) is the key, so it stays known at plan time even when the account
# ID value is only known after apply -- the fix for issue #121 is preserved.
resource "aws_ssoadmin_account_assignment" "this" {
  for_each           = var.target_accounts
  instance_arn       = var.instance_arn
  permission_set_arn = var.permission_set_arn
  principal_id       = var.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}
