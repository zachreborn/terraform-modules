mock_provider "aws" {}

# Scalar type conversion errors (for example visibility = "invalid") occur
# before variable validation; they are not represented as expect_failures.

variables {
  name           = "work"
  create_kms_key = false
}

run "allow_policy_null_sources" {
  command = plan
  variables {
    redrive_allow_policy = jsonencode({ redrivePermission = "byQueue", sourceQueueArns = null })
  }
  expect_failures = [var.redrive_allow_policy]
}

run "redrive_invalid_arn" {
  command = plan
  variables {
    redrive_policy = jsonencode({ deadLetterTargetArn = "not-an-arn", maxReceiveCount = 4 })
  }
  expect_failures = [var.redrive_policy]
}

run "allow_policy_object_sources" {
  command = plan
  variables {
    redrive_allow_policy = jsonencode({ redrivePermission = "byQueue", sourceQueueArns = { first = "arn:aws:sqs:us-east-1:123456789012:q" } })
  }
  expect_failures = [var.redrive_allow_policy]
}

run "allow_policy_string_sources" {
  command = plan
  variables {
    redrive_allow_policy = jsonencode({ redrivePermission = "byQueue", sourceQueueArns = "arn:aws:sqs:us-east-1:123456789012:q" })
  }
  expect_failures = [var.redrive_allow_policy]
}

run "redrive_null_arn" {
  command = plan
  variables {
    redrive_policy = jsonencode({ deadLetterTargetArn = null, maxReceiveCount = 4 })
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_count_minimum" {
  command = plan
  variables {
    redrive_policy = jsonencode({ deadLetterTargetArn = "arn:aws:sqs:us-east-1:123456789012:dlq", maxReceiveCount = 1 })
  }
  assert {
    condition     = jsondecode(aws_sqs_queue.queue.redrive_policy).maxReceiveCount == 1
    error_message = "One delivery must remain accepted."
  }
}

run "redrive_count_maximum" {
  command = plan
  variables {
    redrive_policy = jsonencode({ deadLetterTargetArn = "arn:aws:sqs:us-east-1:123456789012:dlq", maxReceiveCount = 1000 })
  }
  assert {
    condition     = jsondecode(aws_sqs_queue.queue.redrive_policy).maxReceiveCount == 1000
    error_message = "1000 deliveries must remain accepted."
  }
}

run "allow_policy_ten_sources" {
  command = plan
  variables {
    redrive_allow_policy = jsonencode({ redrivePermission = "byQueue", sourceQueueArns = [for i in range(10) : "arn:aws:sqs:us-east-1:123456789012:q${i}"] })
  }
  assert {
    condition     = jsondecode(aws_sqs_queue.queue.redrive_allow_policy).sourceQueueArns == [for i in range(10) : "arn:aws:sqs:us-east-1:123456789012:q${i}"]
    error_message = "Ten source queue ARNs must be accepted and retained exactly."
  }
}

run "legacy_key_spec_unused" {
  command = plan
  variables {
    key_customer_master_key_spec = "ECC_NIST_P256"
    key_usage                    = "SIGN_VERIFY"
  }
  assert {
    condition     = length(module.kms) == 0
    error_message = "Unused legacy KMS options must not restrict a non-KMS queue."
  }
}

run "delay_seconds_below" {
  command = plan
  variables {
    delay_seconds = -1
  }
  expect_failures = [var.delay_seconds]
}