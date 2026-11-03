mock_provider "aws" {}

# Scalar type conversion errors (for example visibility = "invalid") occur
# before variable validation; they are not represented as expect_failures.

variables {
  name           = "work"
  create_kms_key = false
}



run "delay_seconds_above" {
  command = plan
  variables {
    delay_seconds = 901
  }
  expect_failures = [var.delay_seconds]
}

run "delay_seconds_fractional" {
  command = plan
  variables {
    delay_seconds = 0.5
  }
  expect_failures = [var.delay_seconds]
}

run "delay_seconds_minimum" {
  command = plan
  variables {
    delay_seconds = 0
  }
  assert {
    condition     = aws_sqs_queue.queue.delay_seconds == 0
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "delay_seconds_maximum" {
  command = plan
  variables {
    delay_seconds = 900
  }
  assert {
    condition     = aws_sqs_queue.queue.delay_seconds == 900
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "visibility_timeout_seconds_below" {
  command = plan
  variables {
    visibility_timeout_seconds = -1
  }
  expect_failures = [var.visibility_timeout_seconds]
}

run "visibility_timeout_seconds_above" {
  command = plan
  variables {
    visibility_timeout_seconds = 43201
  }
  expect_failures = [var.visibility_timeout_seconds]
}

run "visibility_timeout_seconds_fractional" {
  command = plan
  variables {
    visibility_timeout_seconds = 0.5
  }
  expect_failures = [var.visibility_timeout_seconds]
}

run "visibility_timeout_seconds_minimum" {
  command = plan
  variables {
    visibility_timeout_seconds = 0
  }
  assert {
    condition     = aws_sqs_queue.queue.visibility_timeout_seconds == 0
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "visibility_timeout_seconds_maximum" {
  command = plan
  variables {
    visibility_timeout_seconds = 43200
  }
  assert {
    condition     = aws_sqs_queue.queue.visibility_timeout_seconds == 43200
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "message_retention_seconds_below" {
  command = plan
  variables {
    message_retention_seconds = 59
  }
  expect_failures = [var.message_retention_seconds]
}