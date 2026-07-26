# Native OpenTofu tests for modules/aws/identity_center/permission_set -- for_each branch coverage.
#
# The "group_ids_branch_bypasses_data_source" run is the regression proof for issue #456: it asserts
# zero aws_identitystore_group data source reads occur when a group is covered entirely by group_ids,
# which is exactly the case that previously failed with a plan-time GetGroupId ResourceNotFoundException
# when the group was created in the same apply.
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

  mock_data "aws_identitystore_group" {
    defaults = {
      group_id = "94481408-a061-70b9-9ae4-163731112222"
    }
  }

  mock_resource "aws_ssoadmin_permission_set" {
    defaults = {
      arn          = "arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890"
      created_date = "2024-01-01T00:00:00Z"
      id           = "arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890"
    }
  }

  # A single static mocked id is shared by every aws_ssoadmin_account_assignment instance. This is
  # sufficient to prove the assignment_ids output can parse the comma-delimited id shape, but multiple
  # instances in the same run will collide onto one parsed output key -- so tests with more than one
  # assignment instance assert on the raw resource count, not on output.assignment_ids' length.
  mock_resource "aws_ssoadmin_account_assignment" {
    defaults = {
      id = "94481408-a061-70b9-9ae4-163731112222,GROUP,123456789012,AWS_ACCOUNT,arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890,arn:aws:sso:::instance/ssoins-1234567890abcdef"
    }
  }
}

run "name_lookup_branch_reads_data_source" {
  command = plan

  variables {
    name            = "AdministratorAccess"
    groups          = ["admins"]
    target_accounts = ["123456789012"]
  }

  assert {
    condition     = length(data.aws_identitystore_group.this) == 1
    error_message = "The named group should be resolved via the data source when group_ids does not cover it."
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 1
    error_message = "Expected one assignment (1 group x 1 account)."
  }

  assert {
    condition     = output.group_ids["admins"] == "94481408-a061-70b9-9ae4-163731112222"
    error_message = "group_ids output should expose the data-source-resolved group ID."
  }
}

run "group_ids_branch_bypasses_data_source" {
  command = plan

  variables {
    name            = "ReadOnlyAccess"
    groups          = []
    group_ids       = { readonly = "94481408-a061-70b9-9ae4-163731119999" }
    target_accounts = ["123456789012", "123456789013"]
  }

  assert {
    condition     = length(data.aws_identitystore_group.this) == 0
    error_message = "No GetGroupId lookup should occur when the group is covered entirely by group_ids -- this is the regression proof for issue #456."
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 2
    error_message = "Expected two assignments (1 group x 2 accounts) built entirely from group_ids."
  }

  assert {
    condition     = output.group_ids["readonly"] == "94481408-a061-70b9-9ae4-163731119999"
    error_message = "group_ids output should forward the caller-supplied ID unchanged."
  }
}

run "mixed_groups_and_group_ids" {
  command = plan

  variables {
    name            = "MixedAccess"
    groups          = ["existing"]
    group_ids       = { new_group = "94481408-a061-70b9-9ae4-163731110000" }
    target_accounts = ["123456789012"]
  }

  assert {
    condition     = length(data.aws_identitystore_group.this) == 1
    error_message = "Only the name not covered by group_ids should be looked up."
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 2
    error_message = "Expected one assignment per resolved group (existing + new_group) x 1 account."
  }
}

run "group_ids_key_present_in_both_prefers_group_ids" {
  command = plan

  variables {
    name            = "OverlapAccess"
    groups          = ["admins"]
    group_ids       = { admins = "94481408-a061-70b9-9ae4-163731117777" }
    target_accounts = ["123456789012"]
  }

  assert {
    condition     = length(data.aws_identitystore_group.this) == 0
    error_message = "A key present in both groups and group_ids should be resolved from group_ids, skipping the data source lookup entirely."
  }

  assert {
    condition     = output.group_ids["admins"] == "94481408-a061-70b9-9ae4-163731117777"
    error_message = "group_ids should win over the name-based lookup for an overlapping key."
  }
}

run "managed_policy_toggle_branches" {
  command = plan

  variables {
    name                = "ManagedPolicyAccess"
    group_ids           = { readonly = "94481408-a061-70b9-9ae4-163731118888" }
    managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess", "arn:aws:iam::aws:policy/AWSSupportAccess"]
    target_accounts     = ["123456789012"]
  }

  assert {
    condition     = length(aws_ssoadmin_managed_policy_attachment.this) == 2
    error_message = "Expected one managed_policy_attachment per entry in managed_policy_arns."
  }

  assert {
    condition     = length(aws_ssoadmin_customer_managed_policy_attachment.this) == 0
    error_message = "customer_managed_iam_policy_name is unset; no customer managed policy attachment should be planned."
  }

  assert {
    condition     = length(aws_ssoadmin_permission_set_inline_policy.this) == 0
    error_message = "inline_policy is unset; no inline policy resource should be planned."
  }
}

run "customer_managed_and_inline_policy_toggle_branches" {
  command = plan

  variables {
    name                             = "CustomAccess"
    group_ids                        = { readonly = "94481408-a061-70b9-9ae4-163731116666" }
    customer_managed_iam_policy_name = "test-policy"
    inline_policy                    = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    target_accounts                  = ["123456789012"]
  }

  assert {
    condition     = length(aws_ssoadmin_customer_managed_policy_attachment.this) == 1
    error_message = "customer_managed_iam_policy_name is set; exactly one customer managed policy attachment should be planned."
  }

  assert {
    condition     = length(aws_ssoadmin_permission_set_inline_policy.this) == 1
    error_message = "inline_policy is set; exactly one inline policy resource should be planned."
  }

  assert {
    condition     = length(aws_ssoadmin_managed_policy_attachment.this) == 0
    error_message = "managed_policy_arns is unset (empty); no managed_policy_attachment should be planned."
  }
}

run "policy_only_permission_set_with_no_groups" {
  command = plan

  variables {
    name                = "PolicyOnly"
    managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    target_accounts     = ["123456789012"]
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 0
    error_message = "No groups or group_ids means no group_id_map entries, so no account assignments should be planned even though target_accounts is non-empty."
  }

  assert {
    condition     = length(aws_ssoadmin_managed_policy_attachment.this) == 1
    error_message = "The permission set and its managed policy attachment should still be planned even with no group associations."
  }
}

run "assignment_ids_output_parses_composite_id" {
  command = plan

  variables {
    name            = "AdministratorAccess"
    groups          = ["admins"]
    target_accounts = ["123456789012"]
  }

  assert {
    condition     = length(output.assignment_ids) == 1
    error_message = "Expected exactly one assignment_ids entry."
  }

  assert {
    condition     = output.assignment_ids["admins_123456789012"].principal_type == "GROUP"
    error_message = "assignment_ids should be keyed by '<group_name>_<account_id>' and parse the mocked comma-delimited id into its component fields."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a signal that the
# module code has a bug and fix the root cause in main.tf / variables.tf / outputs.tf, then re-run
# `tofu test` until it passes for the right reason.
