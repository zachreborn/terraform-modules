# Note: several validation {} blocks in variables.tf apply to `bool`-typed variables using a
# `can(regex("true|false", var.x))` condition (key_enable_key_rotation, bucket_key_enabled,
# force_destroy, include_global_service_events, is_multi_region_trail, is_organization_trail,
# enable_log_file_validation, enable_s3_bucket_logging). Because those variables are already
# constrained to `bool` by their declared `type`, every value the type system allows through
# (true or false) also satisfies the regex, so there is no reachable input that makes those
# specific validation blocks fail -- there is no distinct failure mode to add a run block
# for. Only the validations below (on variables typed `string` or `number`) can actually be
# violated by a caller.
mock_provider "aws" {
  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/test-policy"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::123456789012:role/test-role"
      name = "test-role"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:test-log-group"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    target_bucket = "test-cloudtrail-logging-target"
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.name == "cloudtrail"
    error_message = "Expected the baseline trail to plan successfully."
  }
}

run "rejects_invalid_key_customer_master_key_spec" {
  command = plan

  variables {
    target_bucket                = "test-cloudtrail-logging-target"
    key_customer_master_key_spec = "INVALID_SPEC"
  }

  expect_failures = [var.key_customer_master_key_spec]
}

run "rejects_invalid_key_deletion_window_in_days" {
  command = plan

  variables {
    target_bucket               = "test-cloudtrail-logging-target"
    key_deletion_window_in_days = 5
  }

  expect_failures = [var.key_deletion_window_in_days]
}

run "rejects_invalid_key_usage" {
  command = plan

  variables {
    target_bucket = "test-cloudtrail-logging-target"
    key_usage     = "SIGN_VERIFY"
  }

  expect_failures = [var.key_usage]
}

run "rejects_invalid_key_is_enabled" {
  command = plan

  variables {
    target_bucket  = "test-cloudtrail-logging-target"
    key_is_enabled = "invalid"
  }

  expect_failures = [var.key_is_enabled]
}

run "rejects_invalid_bucket_lifecycle_expiration_days" {
  command = plan

  variables {
    target_bucket                    = "test-cloudtrail-logging-target"
    bucket_lifecycle_expiration_days = 0
  }

  expect_failures = [var.bucket_lifecycle_expiration_days]
}

run "rejects_invalid_versioning_status" {
  command = plan

  variables {
    target_bucket     = "test-cloudtrail-logging-target"
    versioning_status = "Archived"
  }

  expect_failures = [var.versioning_status]
}

run "rejects_invalid_sse_algorithm" {
  command = plan

  variables {
    target_bucket = "test-cloudtrail-logging-target"
    sse_algorithm = "invalid"
  }

  expect_failures = [var.sse_algorithm]
}

run "rejects_invalid_mfa_delete" {
  command = plan

  variables {
    target_bucket = "test-cloudtrail-logging-target"
    mfa_delete    = "Maybe"
  }

  expect_failures = [var.mfa_delete]
}

run "rejects_invalid_name" {
  command = plan

  variables {
    target_bucket = "test-cloudtrail-logging-target"
    name          = "invalid_name!"
  }

  expect_failures = [var.name]
}
