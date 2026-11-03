mock_provider "aws" {}

# Scalar type conversion errors (for example visibility = "invalid") occur
# before variable validation; they are not represented as expect_failures.

variables {
  name           = "work"
  create_kms_key = false
}



run "max_message_size_above" {
  command = plan
  variables {
    max_message_size = 1048577
  }
  expect_failures = [var.max_message_size]
}

run "max_message_size_fractional" {
  command = plan
  variables {
    max_message_size = 1024.5
  }
  expect_failures = [var.max_message_size]
}

run "max_message_size_minimum" {
  command = plan
  variables {
    max_message_size = 1024
  }
  assert {
    condition     = aws_sqs_queue.queue.max_message_size == 1024
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "max_message_size_maximum" {
  command = plan
  variables {
    max_message_size = 1048576
  }
  assert {
    condition     = aws_sqs_queue.queue.max_message_size == 1048576
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "receive_wait_time_seconds_below" {
  command = plan
  variables {
    receive_wait_time_seconds = -1
  }
  expect_failures = [var.receive_wait_time_seconds]
}

run "receive_wait_time_seconds_above" {
  command = plan
  variables {
    receive_wait_time_seconds = 21
  }
  expect_failures = [var.receive_wait_time_seconds]
}

run "receive_wait_time_seconds_fractional" {
  command = plan
  variables {
    receive_wait_time_seconds = 0.5
  }
  expect_failures = [var.receive_wait_time_seconds]
}

run "receive_wait_time_seconds_minimum" {
  command = plan
  variables {
    receive_wait_time_seconds = 0
  }
  assert {
    condition     = aws_sqs_queue.queue.receive_wait_time_seconds == 0
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "receive_wait_time_seconds_maximum" {
  command = plan
  variables {
    receive_wait_time_seconds = 20
  }
  assert {
    condition     = aws_sqs_queue.queue.receive_wait_time_seconds == 20
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "key_deletion_window_in_days_below" {
  command = plan
  variables {
    key_deletion_window_in_days = 6
  }
  expect_failures = [var.key_deletion_window_in_days]
}