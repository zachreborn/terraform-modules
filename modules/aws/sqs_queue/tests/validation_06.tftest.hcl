mock_provider "aws" {}

# Scalar type conversion errors (for example visibility = "invalid") occur
# before variable validation; they are not represented as expect_failures.

variables {
  name           = "work"
  create_kms_key = false
}



run "redrive_missing_dlq" {
  command = plan
  variables {
    redrive_policy = "{\"maxReceiveCount\": 4}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_empty_dlq" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"\", \"maxReceiveCount\": 4}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_missing_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\"}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_string_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\", \"maxReceiveCount\": \"4\"}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_fractional_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\", \"maxReceiveCount\": 1.5}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_zero_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\", \"maxReceiveCount\": 0}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_large_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\", \"maxReceiveCount\": 1001}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_null_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\", \"maxReceiveCount\": null}"
  }
  expect_failures = [var.redrive_policy]
}

run "allow_policy_bad_permission" {
  command = plan
  variables {
    redrive_allow_policy = "{\"redrivePermission\": \"no\"}"
  }
  expect_failures = [var.redrive_allow_policy]
}

run "allow_policy_missing_permission" {
  command = plan
  variables {
    redrive_allow_policy = "{}"
  }
  expect_failures = [var.redrive_allow_policy]
}