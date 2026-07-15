# Native OpenTofu tests for the cloudwatch/log_destination module.
#
# These run offline via mock_provider "aws" with mock_resource blocks so
# `tofu init -backend=false && tofu test` requires no real credentials or backend.
#
# Do NOT weaken these assertions to force a pass. If a run block fails, fix the
# root cause in main.tf / variables.tf / outputs.tf, then re-run `tofu test`.

mock_provider "aws" {
  mock_resource "aws_cloudwatch_log_destination" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:destination:test-destination"
      id  = "test-destination"
    }
  }

  mock_resource "aws_cloudwatch_log_destination_policy" {
    defaults = {
      id = "test-destination"
    }
  }
}

variables {
  destination_name       = "test-destination"
  destination_role_arn   = "arn:aws:iam::123456789012:role/cloudwatch-to-firehose"
  destination_target_arn = "arn:aws:firehose:us-east-1:123456789012:deliverystream/test-stream"
}

run "valid_baseline_creates_destination_and_policy" {
  command = plan

  variables {
    destination_policy_access_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "AllowCrossAccount"
        Effect    = "Allow"
        Principal = { AWS = "111122223333" }
        Action    = "logs:PutSubscriptionFilter"
        Resource  = "arn:aws:logs:us-east-1:123456789012:destination:test-destination"
      }]
    })
  }

  assert {
    condition     = aws_cloudwatch_log_destination.this.name == var.destination_name
    error_message = "The log destination name should match var.destination_name."
  }

  assert {
    condition     = aws_cloudwatch_log_destination.this.role_arn == var.destination_role_arn
    error_message = "The log destination role_arn should source from var.destination_role_arn."
  }

  assert {
    condition     = aws_cloudwatch_log_destination.this.target_arn == var.destination_target_arn
    error_message = "The log destination target_arn should source from var.destination_target_arn."
  }

  assert {
    condition     = length(aws_cloudwatch_log_destination_policy.this) == 1
    error_message = "Exactly one destination policy should be created when access_policy is set."
  }

  assert {
    condition     = output.name == var.destination_name
    error_message = "output.name should equal the destination name."
  }

  assert {
    condition     = output.arn != null
    error_message = "output.arn should be non-null in the valid baseline."
  }

  assert {
    condition     = output.id != null
    error_message = "output.id should be non-null in the valid baseline."
  }

  assert {
    condition     = output.access_policy != null
    error_message = "output.access_policy should be non-null when the destination policy is created."
  }
}

run "policy_disabled_when_access_policy_null" {
  command = plan

  variables {
    destination_policy_access_policy = null
  }

  assert {
    condition     = length(aws_cloudwatch_log_destination_policy.this) == 0
    error_message = "No destination policy should be created when access_policy is null."
  }

  assert {
    condition     = output.access_policy == null
    error_message = "output.access_policy should be null when no destination policy is created."
  }

  assert {
    condition     = output.arn != null
    error_message = "output.arn should still be non-null when no destination policy is created."
  }
}
