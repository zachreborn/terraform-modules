# KNOWN MODULE BUG (tracked in https://github.com/zachreborn/terraform-modules/issues/386):
# `alarm_actions`, `ok_actions`, and `insufficient_data_actions` are declared `type = string`
# in variables.tf (with no default, so every caller must supply a value), but the underlying
# aws_cloudwatch_metric_alarm resource requires `set(string)` for all three. Because the
# module variable itself is typed `string`, any value supplied at the call site -- including
# a single-element list, which OpenTofu unifies down to the variable's declared scalar type
# -- is coerced to a plain string before it ever reaches the resource block, so it can never
# satisfy the resource's `set of string` requirement. There is currently no valid input that
# lets this module plan successfully, so the `run` blocks below are commented out (per the
# blank-scaffolding convention in modules/module_template/tests/) rather than committed in a
# permanently-failing state.
#
# This module also has no `validation {}` blocks and no `count`/`for_each` conditional
# branches in main.tf, and outputs.tf is empty, so once issue #386 is fixed the two run
# blocks below (uncommented, with `alarm_actions`/`ok_actions`/`insufficient_data_actions`
# switched from list values back to whatever type the fix lands on) are expected to provide
# full coverage for this module -- no additional validation/conditional/output run blocks
# should be needed.
#
# mock_provider "aws" {}
#
# run "valid_baseline_plans_successfully" {
#   command = plan
#
#   variables {
#     alarm_name                = "test-alarm"
#     alarm_description         = "Test alarm"
#     comparison_operator       = "GreaterThanThreshold"
#     evaluation_periods        = 1
#     metric_name               = "CPUUtilization"
#     namespace                 = "AWS/EC2"
#     period                    = 300
#     statistic                 = "Average"
#     alarm_actions             = ["arn:aws:sns:us-east-1:123456789012:test-topic"]
#     ok_actions                = ["arn:aws:sns:us-east-1:123456789012:test-topic"]
#     insufficient_data_actions = ["arn:aws:sns:us-east-1:123456789012:test-topic"]
#     dimensions = {
#       InstanceId = "i-1234567890abcdef0"
#     }
#     datapoints_to_alarm = 1
#     treat_missing_data  = "missing"
#     unit                = "Percent"
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.alarm_name == "test-alarm"
#     error_message = "alarm_name should pass through unchanged."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.comparison_operator == "GreaterThanThreshold"
#     error_message = "comparison_operator should pass through unchanged."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.metric_name == "CPUUtilization"
#     error_message = "metric_name should pass through unchanged."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.namespace == "AWS/EC2"
#     error_message = "namespace should pass through unchanged."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.dimensions["InstanceId"] == "i-1234567890abcdef0"
#     error_message = "dimensions should pass through unchanged."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.actions_enabled == true
#     error_message = "actions_enabled should default to true."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.threshold == 1
#     error_message = "threshold should default to 1.0."
#   }
# }
#
# run "field_overrides_are_honored" {
#   command = plan
#
#   variables {
#     actions_enabled           = false
#     alarm_name                = "test-alarm"
#     alarm_description         = "Custom alarm description"
#     comparison_operator       = "LessThanThreshold"
#     evaluation_periods        = 3
#     metric_name               = "CPUUtilization"
#     namespace                 = "AWS/EC2"
#     period                    = 60
#     statistic                 = "Maximum"
#     alarm_actions             = ["arn:aws:sns:us-east-1:123456789012:test-topic"]
#     ok_actions                = ["arn:aws:sns:us-east-1:123456789012:test-topic"]
#     insufficient_data_actions = ["arn:aws:sns:us-east-1:123456789012:test-topic"]
#     dimensions = {
#       InstanceId = "i-1234567890abcdef0"
#     }
#     datapoints_to_alarm = 2
#     treat_missing_data  = "breaching"
#     unit                = "Count"
#     threshold           = 90
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.actions_enabled == false
#     error_message = "actions_enabled override should be honored."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.comparison_operator == "LessThanThreshold"
#     error_message = "comparison_operator override should be honored."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.evaluation_periods == 3
#     error_message = "evaluation_periods override should be honored."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.period == 60
#     error_message = "period override should be honored."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.statistic == "Maximum"
#     error_message = "statistic override should be honored."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.datapoints_to_alarm == 2
#     error_message = "datapoints_to_alarm override should be honored."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.treat_missing_data == "breaching"
#     error_message = "treat_missing_data override should be honored."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.unit == "Count"
#     error_message = "unit override should be honored."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.threshold == 90
#     error_message = "threshold override should be honored."
#   }
#
#   assert {
#     condition     = aws_cloudwatch_metric_alarm.alarm.alarm_description == "Custom alarm description"
#     error_message = "alarm_description override should be honored."
#   }
# }
