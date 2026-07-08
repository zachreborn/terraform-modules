mock_provider "aws" {
  # ARN-shaped defaults are required here (even though this file only exercises variable
  # validation) because several resources pass another resource's computed .arn into an
  # argument that the AWS provider itself validates as ARN-shaped at plan time (e.g.
  # aws_iam_role_policy_attachment.policy_arn, aws_cloudtrail.kms_key_id). Without these,
  # OpenTofu's auto-generated mock values (short random strings) fail that client-side check
  # before a run's own validation failure is ever reached.
  mock_resource "aws_kms_key" {
    defaults = {
      key_id = "11111111-2222-3333-4444-555555555555"
      arn    = "arn:aws:kms:us-east-1:222222222222:key/11111111-2222-3333-4444-555555555555"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:222222222222:log-group:mock-cloudtrail-lg"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::222222222222:role/mock-cloudtrail-role"
      name = "mock-cloudtrail-role"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::222222222222:policy/mock-cloudtrail-policy"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      id  = "mock-cloudtrail-bucket"
      arn = "arn:aws:s3:::mock-cloudtrail-bucket"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    enable_s3_bucket_logging = false
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.name == "cloudtrail"
    error_message = "Expected the default trail name to be 'cloudtrail'."
  }
}

run "rejects_invalid_name" {
  command = plan

  variables {
    name                     = "invalid_name_with_underscore"
    enable_s3_bucket_logging = false
  }

  expect_failures = [var.name]
}

run "rejects_invalid_key_customer_master_key_spec" {
  command = plan

  variables {
    key_customer_master_key_spec = "INVALID_SPEC"
    enable_s3_bucket_logging     = false
  }

  expect_failures = [var.key_customer_master_key_spec]
}

run "rejects_key_deletion_window_in_days_below_minimum" {
  command = plan

  variables {
    key_deletion_window_in_days = 5
    enable_s3_bucket_logging    = false
  }

  expect_failures = [var.key_deletion_window_in_days]
}

run "rejects_invalid_key_usage" {
  command = plan

  variables {
    key_usage                = "SIGN_VERIFY"
    enable_s3_bucket_logging = false
  }

  expect_failures = [var.key_usage]
}

run "rejects_invalid_key_is_enabled" {
  command = plan

  variables {
    key_is_enabled           = "maybe"
    enable_s3_bucket_logging = false
  }

  expect_failures = [var.key_is_enabled]
}

run "rejects_zero_bucket_lifecycle_expiration_days" {
  command = plan

  variables {
    bucket_lifecycle_expiration_days = 0
    enable_s3_bucket_logging         = false
  }

  expect_failures = [var.bucket_lifecycle_expiration_days]
}

run "rejects_invalid_versioning_status" {
  command = plan

  variables {
    versioning_status        = "Archived"
    enable_s3_bucket_logging = false
  }

  expect_failures = [var.versioning_status]
}

run "rejects_invalid_sse_algorithm" {
  command = plan

  variables {
    sse_algorithm            = "AES128"
    enable_s3_bucket_logging = false
  }

  expect_failures = [var.sse_algorithm]
}

run "rejects_invalid_mfa_delete" {
  command = plan

  variables {
    mfa_delete               = "Maybe"
    enable_s3_bucket_logging = false
  }

  expect_failures = [var.mfa_delete]
}

run "rejects_iam_role_max_session_duration_below_minimum" {
  command = plan

  variables {
    iam_role_max_session_duration = 100
    enable_s3_bucket_logging      = false
  }

  expect_failures = [var.iam_role_max_session_duration]
}

run "rejects_invalid_organization_management_account_id" {
  command = plan

  variables {
    organization_management_account_id = "12345"
    enable_s3_bucket_logging           = false
  }

  expect_failures = [var.organization_management_account_id]
}

run "accepts_null_organization_management_account_id" {
  command = plan

  variables {
    organization_management_account_id = null
    enable_s3_bucket_logging           = false
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.name == "cloudtrail"
    error_message = "A null organization_management_account_id should be accepted and fall back to the caller's account ID."
  }
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to make
# `tofu test` pass. A validation test that unexpectedly fails means either the `validation {}` block
# in variables.tf has a bug or the test's inputs are wrong -- find and fix the root cause, then re-run
# `tofu test` until it passes for the right reason.
