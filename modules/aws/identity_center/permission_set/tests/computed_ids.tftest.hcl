# Native OpenTofu test for modules/aws/identity_center/permission_set -- computed (known-after-apply)
# group and account IDs.
#
# The harness in ./tests/computed_ids feeds terraform_data IDs (unknown at plan time) into group_ids
# and target_accounts. Assignment addresses must depend only on the group name and the target_accounts
# label -- never on either ID -- so the plan must succeed and expose a plan-time-known entry for the
# new group and new account. This is the regression proof for issues #121 (computed account ID) and
# #456 (computed group ID) against the per-group module.group_assignments layout.
#
# Run offline with:
#   tofu -chdir=modules/aws/identity_center/permission_set init -backend=false
#   tofu -chdir=modules/aws/identity_center/permission_set test

mock_provider "aws" {
  mock_data "aws_ssoadmin_instances" {
    defaults = {
      identity_store_ids = ["d-1234567890"]
      arns               = ["arn:aws:sso:::instance/ssoins-1234567890abcdef"]
    }
  }

  mock_resource "aws_ssoadmin_permission_set" {
    defaults = {
      arn          = "arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890"
      created_date = "2024-01-01T00:00:00Z"
      id           = "arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890"
    }
  }

  mock_resource "aws_ssoadmin_account_assignment" {
    defaults = {
      id = "94481408-a061-70b9-9ae4-163731112222,GROUP,123456789012,AWS_ACCOUNT,arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890,arn:aws:sso:::instance/ssoins-1234567890abcdef"
    }
  }
}

run "computed_group_and_account_ids_plan_successfully" {
  command = plan
  module {
    source = "./tests/computed_ids"
  }

  assert {
    condition     = contains(keys(output.assignment_ids), "new_group")
    error_message = "The new group should have a plan-time-known assignment_ids entry even though its group ID is only known after apply."
  }

  assert {
    condition     = contains(keys(output.assignment_ids["new_group"]), "new_account")
    error_message = "The new account's label should have a plan-time-known entry under the new group even though its account ID is only known after apply."
  }

  assert {
    condition     = contains(keys(output.group_ids), "new_group")
    error_message = "group_ids should expose the new group's logical name (plan-time-known) even though its ID is only known after apply."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a signal that the
# module code has a bug and fix the root cause in main.tf / variables.tf / outputs.tf, then re-run
# `tofu test` until it passes for the right reason.
