mock_provider "aws" {}

# Scalar type conversion errors (for example visibility = "invalid") occur
# before variable validation; they are not represented as expect_failures.

variables {
  name           = "work"
  create_kms_key = false
}



run "message_retention_seconds_above" {
  command = plan
  variables {
    message_retention_seconds = 1209601
  }
  expect_failures = [var.message_retention_seconds]
}

run "message_retention_seconds_fractional" {
  command = plan
  variables {
    message_retention_seconds = 60.5
  }
  expect_failures = [var.message_retention_seconds]
}

run "message_retention_seconds_minimum" {
  command = plan
  variables {
    message_retention_seconds = 60
  }
  assert {
    condition     = aws_sqs_queue.queue.message_retention_seconds == 60
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "message_retention_seconds_maximum" {
  command = plan
  variables {
    message_retention_seconds = 1209600
  }
  assert {
    condition     = aws_sqs_queue.queue.message_retention_seconds == 1209600
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "kms_data_key_reuse_period_seconds_below" {
  command = plan
  variables {
    kms_data_key_reuse_period_seconds = 59
  }
  expect_failures = [var.kms_data_key_reuse_period_seconds]
}

run "kms_data_key_reuse_period_seconds_above" {
  command = plan
  variables {
    kms_data_key_reuse_period_seconds = 86401
  }
  expect_failures = [var.kms_data_key_reuse_period_seconds]
}

run "kms_data_key_reuse_period_seconds_fractional" {
  command = plan
  variables {
    kms_data_key_reuse_period_seconds = 60.5
  }
  expect_failures = [var.kms_data_key_reuse_period_seconds]
}

run "kms_data_key_reuse_period_seconds_minimum" {
  command = plan
  variables {
    kms_data_key_reuse_period_seconds = 60
    kms_master_key_id                 = "alias/aws/sqs"
  }
  assert {
    condition     = aws_sqs_queue.queue.kms_data_key_reuse_period_seconds == 60
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "kms_data_key_reuse_period_seconds_maximum" {
  command = plan
  variables {
    kms_data_key_reuse_period_seconds = 86400
    kms_master_key_id                 = "alias/aws/sqs"
  }
  assert {
    condition     = aws_sqs_queue.queue.kms_data_key_reuse_period_seconds == 86400
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "max_message_size_below" {
  command = plan
  variables {
    max_message_size = 1023
  }
  expect_failures = [var.max_message_size]
}