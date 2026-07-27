# Native OpenTofu tests for modules/aws/identity_center/permission_set -- large input map coverage.
#
# These runs exercise a large number of for_each entries (generated via `range()`/`for` expressions
# rather than hand-written literals) to prove the module scales linearly with input size and imposes
# no artificial per-entry limits, per AGENTS.md Module Design Specifications section 5 (Scalable
# Inputs via YAML / for_each). The group_ids case also re-proves the issue #456 fix holds at scale:
# zero aws_identitystore_group data source reads occur no matter how many groups are covered by
# group_ids.
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

  mock_resource "aws_ssoadmin_account_assignment" {
    defaults = {
      id = "94481408-a061-70b9-9ae4-163731112222,GROUP,123456789012,AWS_ACCOUNT,arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890,arn:aws:sso:::instance/ssoins-1234567890abcdef"
    }
  }
}

run "large_group_ids_map_scales_without_data_source_reads" {
  command = plan

  variables {
    name            = "LargeGroupIdsAccess"
    group_ids       = { for i in range(50) : format("group-%02d", i) => format("94481408-a061-70b9-9ae4-%012d", i) }
    target_accounts = [for i in range(5) : format("1000000000%02d", i)]
  }

  assert {
    condition     = length(data.aws_identitystore_group.this) == 0
    error_message = "Every group is covered by group_ids; no GetGroupId lookups should occur even at scale (50 groups)."
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 250
    error_message = "Expected 50 groups x 5 target_accounts = 250 account assignments."
  }

  assert {
    condition     = length(output.group_ids) == 50
    error_message = "group_ids output should contain all 50 resolved group entries."
  }
}

run "large_groups_set_scales_via_data_source" {
  command = plan

  variables {
    name            = "LargeNameLookupAccess"
    groups          = toset([for i in range(50) : format("group-%02d", i)])
    target_accounts = ["123456789012"]
  }

  assert {
    condition     = length(data.aws_identitystore_group.this) == 50
    error_message = "All 50 group names should be resolved via the data source (none covered by group_ids)."
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 50
    error_message = "Expected 50 groups x 1 target_account = 50 account assignments."
  }
}

run "large_mixed_groups_and_group_ids_scales" {
  command = plan

  variables {
    name            = "LargeMixedAccess"
    groups          = toset([for i in range(25) : format("existing-%02d", i)])
    group_ids       = { for i in range(25) : format("new-%02d", i) => format("94481408-a061-70b9-9ae4-%012d", i) }
    target_accounts = [for i in range(4) : format("1000000000%02d", i)]
  }

  assert {
    condition     = length(data.aws_identitystore_group.this) == 25
    error_message = "Only the 25 names not covered by group_ids should be looked up."
  }

  assert {
    condition     = length(output.group_ids) == 50
    error_message = "group_ids output should merge all 50 resolved groups (25 looked up + 25 pre-resolved)."
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 200
    error_message = "Expected (25 + 25) groups x 4 target_accounts = 200 account assignments."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a signal that the
# module code has a bug and fix the root cause in main.tf / variables.tf / outputs.tf, then re-run
# `tofu test` until it passes for the right reason.
