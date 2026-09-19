# Validation tests for the cloudwatch/log_destination module.
#
# Covers the single validation { ... } rule on destination_policy_access_policy,
# which requires the value to be parseable JSON when non-null.
#
# Do NOT loosen or skip the expect_failures case to force a pass. If it fails
# unexpectedly, fix the validation block in variables.tf, not the test.

mock_provider "aws" {}

variables {
  destination_name       = "test-destination"
  destination_role_arn   = "arn:aws:iam::123456789012:role/cloudwatch-to-firehose"
  destination_target_arn = "arn:aws:firehose:us-east-1:123456789012:deliverystream/test-stream"
}

run "valid_json_access_policy_does_not_fail" {
  command = plan

  variables {
    destination_policy_access_policy = jsonencode({ Version = "2012-10-17", Statement = [] })
  }

  assert {
    condition     = length(aws_cloudwatch_log_destination_policy.this) == 1
    error_message = "A valid-JSON access policy should satisfy validation and create the policy."
  }
}

run "rejects_non_json_access_policy" {
  command = plan

  variables {
    destination_policy_access_policy = "this is not valid json"
  }

  expect_failures = [var.destination_policy_access_policy]
}
