# Validation tests for the cloudwatch/alarm module. One valid-baseline case plus one
# `expect_failures` case per `validation {}` block in variables.tf. All cases run offline
# via `mock_provider`:
#   tofu init -backend=false && tofu test
#
# See modules/aws/organizations/account/tests/validation.tftest.hcl for the pattern.

mock_provider "aws" {
  mock_resource "aws_cloudwatch_metric_alarm" {
    defaults = {
      id  = "test-alarm"
      arn = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:test-alarm"
    }
  }
}

# Valid baseline: satisfies every validation block.
run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    alarm_name          = "test-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 120
    statistic           = "Average"
    threshold           = 80
    treat_missing_data  = "missing"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alarm.comparison_operator == "GreaterThanOrEqualToThreshold"
    error_message = "comparison_operator should pass through unchanged for a valid value."
  }
}

# Invalid comparison_operator is rejected by its validation block.
run "rejects_invalid_comparison_operator" {
  command = plan

  variables {
    alarm_name          = "test-alarm"
    comparison_operator = "NotARealOperator"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 120
    statistic           = "Average"
    threshold           = 80
  }

  expect_failures = [var.comparison_operator]
}

# Invalid treat_missing_data is rejected by its validation block.
run "rejects_invalid_treat_missing_data" {
  command = plan

  variables {
    alarm_name          = "test-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 120
    statistic           = "Average"
    threshold           = 80
    treat_missing_data  = "notAValidOption"
  }

  expect_failures = [var.treat_missing_data]
}
