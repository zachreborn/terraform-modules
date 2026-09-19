mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    zone_id                      = "Z1234567890ABC"
    name                         = "app.example.com"
    type                         = "A"
    records                      = ["primary-target.example.com"]
    set_identifier               = "primary"
    failover_routing_policy_type = "PRIMARY"
  }

  assert {
    condition     = aws_route53_record.this.type == "A"
    error_message = "A supported record type should plan successfully."
  }
}

run "rejects_unsupported_type" {
  command = plan

  variables {
    zone_id                      = "Z1234567890ABC"
    name                         = "app.example.com"
    type                         = "INVALID"
    records                      = ["primary-target.example.com"]
    set_identifier               = "primary"
    failover_routing_policy_type = "PRIMARY"
  }

  expect_failures = [var.type]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
