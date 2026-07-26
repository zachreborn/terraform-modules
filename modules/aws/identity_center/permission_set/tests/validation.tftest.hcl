# Native OpenTofu tests for modules/aws/identity_center/permission_set -- variable validation.
#
# All run blocks use command = plan; mock_provider avoids needing real AWS credentials or a backend.
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

run "valid_baseline_name_lookup_plans_successfully" {
  command = plan

  variables {
    name            = "AdministratorAccess"
    groups          = ["admins"]
    target_accounts = ["123456789012"]
  }

  assert {
    condition     = aws_ssoadmin_permission_set.this.name == "AdministratorAccess"
    error_message = "name should pass through unchanged."
  }

  assert {
    condition     = length(data.aws_identitystore_group.this) == 1
    error_message = "The named group should be resolved via the data source (default groups path)."
  }
}

run "empty_groups_and_group_ids_plans_successfully" {
  command = plan

  variables {
    name            = "PolicyOnly"
    target_accounts = ["123456789012"]
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 0
    error_message = "groups and group_ids default to empty; a policy-only permission set with no group associations is a legitimate configuration."
  }
}

run "rejects_empty_group_id_value" {
  command = plan

  variables {
    name            = "AdministratorAccess"
    group_ids       = { readonly = "" }
    target_accounts = ["123456789012"]
  }

  expect_failures = [var.group_ids]
}

run "rejects_null_group_id_value" {
  command = plan

  variables {
    name            = "AdministratorAccess"
    group_ids       = { readonly = null }
    target_accounts = ["123456789012"]
  }

  expect_failures = [var.group_ids]
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a signal that the
# module code has a bug and fix the root cause in main.tf / variables.tf / outputs.tf, then re-run
# `tofu test` until it passes for the right reason.
