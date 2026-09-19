mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name            = "example-gateway"
    amazon_side_asn = "64512"
  }

  assert {
    condition     = aws_dx_gateway.this.amazon_side_asn == "64512"
    error_message = "Expected the gateway to be planned with the given amazon_side_asn."
  }
}

run "rejects_amazon_side_asn_below_private_range" {
  command = plan

  variables {
    name            = "example-gateway"
    amazon_side_asn = "64511"
  }

  expect_failures = [var.amazon_side_asn]
}

run "rejects_amazon_side_asn_in_gap_between_ranges" {
  command = plan

  variables {
    name            = "example-gateway"
    amazon_side_asn = "65535"
  }

  expect_failures = [var.amazon_side_asn]
}

run "rejects_amazon_side_asn_above_private_range" {
  command = plan

  variables {
    name            = "example-gateway"
    amazon_side_asn = "4294967295"
  }

  expect_failures = [var.amazon_side_asn]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
