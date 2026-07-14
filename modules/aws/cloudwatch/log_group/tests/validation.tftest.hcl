mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name = "test-log-group"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.name == "test-log-group"
    error_message = "Expected the baseline log group to plan successfully."
  }
}

run "rejects_invalid_log_group_class" {
  command = plan

  variables {
    name            = "test-log-group"
    log_group_class = "INVALID_CLASS"
  }

  expect_failures = [var.log_group_class]
}

run "rejects_invalid_retention_in_days" {
  command = plan

  variables {
    name              = "test-log-group"
    retention_in_days = 2
  }

  expect_failures = [var.retention_in_days]
}

run "rejects_both_name_and_name_prefix_set" {
  command = plan

  variables {
    name        = "test-log-group"
    name_prefix = "test-log-group-"
  }

  expect_failures = [aws_cloudwatch_log_group.this]
}

run "rejects_neither_name_nor_name_prefix_set" {
  command = plan

  variables {}

  expect_failures = [aws_cloudwatch_log_group.this]
}
