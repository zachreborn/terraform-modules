mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name      = "example-connection"
    bandwidth = "1Gbps"
    location  = "EqDC2"
  }

  assert {
    condition     = aws_dx_connection.this.encryption_mode == "no_encrypt"
    error_message = "Expected the connection to be planned with the default encryption_mode."
  }
}

run "rejects_invalid_encryption_mode" {
  command = plan

  variables {
    name            = "example-connection"
    bandwidth       = "1Gbps"
    location        = "EqDC2"
    encryption_mode = "always_encrypt"
  }

  expect_failures = [var.encryption_mode]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
