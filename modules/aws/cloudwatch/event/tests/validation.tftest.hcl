mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name                = "test-rule"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.name == "test-rule"
    error_message = "Expected the baseline rule to plan successfully."
  }
}

run "rejects_name_longer_than_64_characters" {
  command = plan

  variables {
    name                = "this-name-is-far-too-long-to-be-a-valid-cloudwatch-event-rule-name-1234567890"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  expect_failures = [var.name]
}

run "rejects_name_prefix_longer_than_38_characters" {
  command = plan

  variables {
    name_prefix         = "this-name-prefix-is-far-too-long-to-be-valid"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  expect_failures = [var.name_prefix]
}

run "rejects_invalid_state" {
  command = plan

  variables {
    name                = "test-rule"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
    state               = "PAUSED"
  }

  expect_failures = [var.state]
}

run "rejects_both_event_pattern_and_schedule_expression_set" {
  command = plan

  variables {
    name                = "test-rule"
    event_pattern       = jsonencode({ source = ["aws.ec2"] })
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  expect_failures = [aws_cloudwatch_event_rule.event_rule]
}

run "rejects_neither_event_pattern_nor_schedule_expression_set" {
  command = plan

  variables {
    name             = "test-rule"
    event_target_arn = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  expect_failures = [aws_cloudwatch_event_rule.event_rule]
}

run "rejects_both_name_and_name_prefix_set" {
  command = plan

  variables {
    name                = "test-rule"
    name_prefix         = "test-rule-"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  expect_failures = [aws_cloudwatch_event_rule.event_rule]
}

run "rejects_neither_name_nor_name_prefix_set" {
  command = plan

  variables {
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  expect_failures = [aws_cloudwatch_event_rule.event_rule]
}
