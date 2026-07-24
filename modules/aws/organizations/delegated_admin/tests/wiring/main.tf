###########################################################
# Wiring / harness module for the delegated_admin composition
# test (mixed account_id sources).
#
# This module simulates a caller that creates an AWS account
# and immediately registers it as a delegated administrator
# for a service in the same apply. The account_id flows from
# aws_organizations_account.new.id into the delegated_admin
# module as a VALUE (not a for_each KEY), which is the fix
# for the "Invalid for_each argument" bug.
#
# aws_organizations_account is mocked with a valid 12-digit
# ID so the test can exercise the composition without real
# credentials. The static-key tests in delegated_admin.tftest.hcl
# independently prove the for_each key is always the logical
# name, never the account_id.
###########################################################

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_organizations_account" "new" {
  email     = "new-account@example.com"
  name      = "new-account"
  parent_id = "r-abcd1234"
}

module "delegated_admin" {
  source = "../.."

  delegated_admins = {
    # account_id comes from a concurrently-created account resource. In real usage,
    # this value is unknown at plan time; in tests the mock provider supplies a
    # valid 12-digit ID. Either way, it flows as a resource-argument VALUE, not a KEY.
    new_account = {
      account_id = aws_organizations_account.new.id
      services   = ["backup.amazonaws.com"]
    }
    # account_id is a static literal — always known at plan time.
    existing_account = {
      account_id = "999999999999"
      services   = ["config.amazonaws.com"]
    }
  }
}

output "delegated_administrators" {
  description = "Delegated administrator objects from the delegated_admin module."
  value       = module.delegated_admin.delegated_administrators
}

output "delegated_administrator_ids" {
  description = "Delegated administrator IDs from the delegated_admin module."
  value       = module.delegated_admin.delegated_administrator_ids
}
