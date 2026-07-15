# Native OpenTofu tests for the cloudwatch/alarm module. All cases run fully offline
# via `mock_provider`/`mock_resource` — no real credentials or backend are required:
#   tofu init -backend=false && tofu test
#
# See AGENTS.md > Module Design Specifications > Native Test Coverage for the full
# requirement, and modules/aws/organizations/tests/ for a worked example.

mock_provider "aws" {
  mock_resource "aws_cloudwatch_metric_alarm" {
    defaults = {
      id  = "test-alarm"
      arn = "arn:aws:cloudwatch:us-east-1:123456789012:alarm:test-alarm"
    }
  }
}

# Valid baseline: the exact scenario the issue says fails today. Supplying list-typed
# action variables must now plan successfully.
run "plan_succeeds_with_list_actions" {
  command = plan

  variables {
    alarm_name                = "test-alarm"
    comparison_operator       = "GreaterThanOrEqualToThreshold"
    evaluation_periods        = 2
    metric_name               = "CPUUtilization"
    namespace                 = "AWS/EC2"
    period                    = 120
    statistic                 = "Average"
    threshold                 = 80
    alarm_actions             = ["arn:aws:sns:us-east-1:123456789012:test-topic"]
    ok_actions                = ["arn:aws:sns:us-east-1:123456789012:test-topic"]
    insufficient_data_actions = ["arn:aws:sns:us-east-1:123456789012:test-topic"]
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.alarm.alarm_actions) == 1
    error_message = "alarm_actions should contain exactly one ARN."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.alarm.ok_actions) == 1
    error_message = "ok_actions should contain exactly one ARN."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.alarm.insufficient_data_actions) == 1
    error_message = "insufficient_data_actions should contain exactly one ARN."
  }
}

# Output assertions against the mocked resource values.
run "outputs_are_populated" {
  command = apply

  variables {
    alarm_name          = "test-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 120
    statistic           = "Average"
    threshold           = 80
    alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:test-topic"]
  }

  assert {
    condition     = output.arn != null
    error_message = "The arn output should be non-null."
  }

  assert {
    condition     = output.id != null
    error_message = "The id output should be non-null."
  }
}

# Empty-action default branch: omitting all three action variables must still plan,
# proving the new `[]` defaults make the actions optional.
run "plan_succeeds_with_default_empty_actions" {
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
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.alarm.alarm_actions) == 0
    error_message = "alarm_actions should default to an empty set."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.alarm.ok_actions) == 0
    error_message = "ok_actions should default to an empty set."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.alarm.insufficient_data_actions) == 0
    error_message = "insufficient_data_actions should default to an empty set."
  }
}

# Multi-element action list: passing two ARNs must plan, proving the set(string)
# semantics (multiple actions per state transition).
run "plan_succeeds_with_multiple_actions" {
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
    alarm_actions = [
      "arn:aws:sns:us-east-1:123456789012:test-topic-1",
      "arn:aws:sns:us-east-1:123456789012:test-topic-2",
    ]
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.alarm.alarm_actions) == 2
    error_message = "alarm_actions should contain both ARNs."
  }
}
