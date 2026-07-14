mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name_prefix = "example-key"
  }

  assert {
    condition     = aws_kms_key.this.customer_master_key_spec == "SYMMETRIC_DEFAULT"
    error_message = "Expected the KMS key to be planned with the default key spec."
  }
}

run "rejects_invalid_customer_master_key_spec" {
  command = plan

  variables {
    name_prefix              = "example-key"
    customer_master_key_spec = "INVALID_SPEC"
  }

  expect_failures = [var.customer_master_key_spec]
}

run "rejects_deletion_window_below_minimum" {
  command = plan

  variables {
    name_prefix             = "example-key"
    deletion_window_in_days = 6
  }

  expect_failures = [var.deletion_window_in_days]
}

run "rejects_deletion_window_above_maximum" {
  command = plan

  variables {
    name_prefix             = "example-key"
    deletion_window_in_days = 31
  }

  expect_failures = [var.deletion_window_in_days]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
