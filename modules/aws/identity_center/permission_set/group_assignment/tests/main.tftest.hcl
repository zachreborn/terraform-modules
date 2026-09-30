# Native OpenTofu tests for modules/aws/identity_center/permission_set/group_assignment.
#
# Run offline with:
#   tofu -chdir=modules/aws/identity_center/permission_set/group_assignment init -backend=false
#   tofu -chdir=modules/aws/identity_center/permission_set/group_assignment test

mock_provider "aws" {
  mock_resource "aws_ssoadmin_account_assignment" {
    defaults = {
      id = "94481408-a061-70b9-9ae4-163731112222,GROUP,123456789012,AWS_ACCOUNT,arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890,arn:aws:sso:::instance/ssoins-1234567890abcdef"
    }
  }
}

variables {
  group_id           = "94481408-a061-70b9-9ae4-163731112222"
  instance_arn       = "arn:aws:sso:::instance/ssoins-1234567890abcdef"
  permission_set_arn = "arn:aws:sso:::permissionSet/ssoins-1234567890abcdef/ps-abcdef1234567890"
}

run "valid_baseline_plans_one_assignment_per_label" {
  command = plan

  variables {
    target_accounts = { primary = "123456789012", secondary = "123456789013" }
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 2
    error_message = "One assignment should be planned per target_accounts label."
  }

  assert {
    condition     = alltrue([for k in ["primary", "secondary"] : contains(keys(output.assignment_ids), k)])
    error_message = "assignment_ids should be keyed directly by the target_accounts label."
  }
}

# Every label below would need escaping under a flat string-key scheme. Here the label IS the key.
run "labels_with_any_characters_are_used_verbatim" {
  command = plan

  variables {
    target_accounts = {
      under_score  = "123456789012"
      hy-phen      = "123456789013"
      "with space" = "123456789014"
      "pi|pe"      = "123456789015"
      "at@sign"    = "123456789016"
    }
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 5
    error_message = "All five unusual labels must produce distinct assignments."
  }

  assert {
    condition = alltrue([
      for k in ["under_score", "hy-phen", "with space", "pi|pe", "at@sign"] :
      contains(keys(output.assignment_ids), k)
    ])
    error_message = "Labels must appear verbatim as assignment_ids keys with no encoding."
  }
}

run "empty_target_accounts_plans_no_assignments" {
  command = plan

  variables {
    target_accounts = {}
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 0
    error_message = "An empty target_accounts map should plan no assignments."
  }
}

run "region_is_forwarded_to_every_assignment" {
  command = plan

  variables {
    region          = "us-west-2"
    target_accounts = { primary = "123456789012", secondary = "123456789013" }
  }

  assert {
    condition     = alltrue([for k, a in aws_ssoadmin_account_assignment.this : a.region == "us-west-2"])
    error_message = "region should be forwarded to every aws_ssoadmin_account_assignment."
  }
}

run "timeouts_are_forwarded_to_every_assignment" {
  command = plan

  variables {
    timeouts        = { create = "10m", delete = "15m" }
    target_accounts = { primary = "123456789012", secondary = "123456789013" }
  }

  assert {
    condition = alltrue([
      for k, a in aws_ssoadmin_account_assignment.this :
      a.timeouts.create == "10m" && a.timeouts.delete == "15m"
    ])
    error_message = "create and delete timeouts should be forwarded to every aws_ssoadmin_account_assignment."
  }
}

run "rejects_unknown_timeouts_key" {
  command = plan

  variables {
    timeouts        = { update = "10m" }
    target_accounts = { primary = "123456789012" }
  }

  expect_failures = [var.timeouts]
}

run "rejects_duplicate_target_accounts_values" {
  command = plan

  variables {
    # Two labels for the identical account ID would create two resources managing the same AWS
    # assignment under separate addresses, so direct callers of this module are rejected too.
    target_accounts = { primary = "123456789012", duplicate = "123456789012" }
  }

  expect_failures = [var.target_accounts]
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a signal that the
# module code has a bug and fix the root cause in main.tf / variables.tf / outputs.tf, then re-run
# `tofu test` until it passes for the right reason.
