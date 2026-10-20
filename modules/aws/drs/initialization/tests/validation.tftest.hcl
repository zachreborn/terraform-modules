mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mocked-role"
    }
  }

  mock_resource "aws_iam_instance_profile" {
    defaults = {
      arn = "arn:aws:iam::123456789012:instance-profile/mocked-instance-profile"
    }
  }

  mock_resource "aws_iam_service_linked_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/aws-service-role/drs.amazonaws.com/AWSServiceRoleForElasticDisasterRecovery"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  assert {
    condition     = length(module.role) == 6
    error_message = "A default configuration with no overrides should plan successfully and create all six roles."
  }
}

run "rejects_additional_policy_arns_with_unknown_role_name" {
  command = plan

  variables {
    additional_policy_arns = {
      NotARealDrsRole = ["arn:aws:iam::123456789012:policy/extra-policy"]
    }
  }

  expect_failures = [var.additional_policy_arns]
}

run "rejects_max_session_duration_below_minimum" {
  command = plan

  variables {
    max_session_duration = 3599
  }

  expect_failures = [var.max_session_duration]
}

run "rejects_max_session_duration_above_maximum" {
  command = plan

  variables {
    max_session_duration = 43201
  }

  expect_failures = [var.max_session_duration]
}

run "rejects_path_without_leading_slash" {
  command = plan

  variables {
    path = "service-role/"
  }

  expect_failures = [var.path]
}

run "rejects_path_without_trailing_slash" {
  command = plan

  variables {
    path = "/service-role"
  }

  expect_failures = [var.path]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
