mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name         = "test-stack"
    capabilities = ["CAPABILITY_IAM"]
    on_failure   = "ROLLBACK"
  }

  assert {
    condition     = aws_cloudformation_stack.this.name == "test-stack"
    error_message = "Expected the stack to plan successfully with valid inputs."
  }
}

run "rejects_invalid_capability" {
  command = plan

  variables {
    name         = "test-stack"
    capabilities = ["CAPABILITY_NOT_REAL"]
  }

  expect_failures = [var.capabilities]
}

run "rejects_invalid_on_failure" {
  command = plan

  variables {
    name       = "test-stack"
    on_failure = "IGNORE"
  }

  expect_failures = [var.on_failure]
}

run "rejects_zero_timeout_in_minutes" {
  command = plan

  variables {
    name               = "test-stack"
    timeout_in_minutes = 0
  }

  expect_failures = [var.timeout_in_minutes]
}

run "rejects_negative_timeout_in_minutes" {
  command = plan

  variables {
    name               = "test-stack"
    timeout_in_minutes = -5
  }

  expect_failures = [var.timeout_in_minutes]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
