mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name = "example-prefix-list"
  }

  assert {
    condition     = aws_ec2_managed_prefix_list.this.address_family == "IPv4"
    error_message = "Expected the prefix list to be planned with the default address family."
  }
}

run "rejects_invalid_address_family" {
  command = plan

  variables {
    name           = "example-prefix-list"
    address_family = "IPv7"
  }

  expect_failures = [var.address_family]
}

run "rejects_max_entries_below_minimum" {
  command = plan

  variables {
    name        = "example-prefix-list"
    max_entries = 0
  }

  expect_failures = [var.max_entries]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
