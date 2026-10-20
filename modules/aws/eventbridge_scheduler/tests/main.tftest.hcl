mock_provider "aws" {
  mock_resource "aws_scheduler_schedule" {
    defaults = {
      arn = "arn:aws:scheduler:us-east-1:123456789012:schedule/default/example"
      id  = "default/example"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::123456789012:role/mock-scheduler-role"
      name = "mock-scheduler-role"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-invoke-policy"
      id  = "arn:aws:iam::123456789012:policy/mock-invoke-policy"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
}

run "plan_succeeds_with_valid_baseline" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  assert {
    condition     = aws_scheduler_schedule.this.flexible_time_window[0].mode == "OFF"
    error_message = "flexible_time_window.mode should default to OFF."
  }

  assert {
    condition     = aws_scheduler_schedule.this.flexible_time_window[0].maximum_window_in_minutes == null
    error_message = "maximum_window_in_minutes should default to null when mode is OFF."
  }

  assert {
    condition     = aws_scheduler_schedule.this.schedule_expression_timezone == "UTC"
    error_message = "schedule_expression_timezone should default to UTC."
  }

  assert {
    condition     = aws_scheduler_schedule.this.state == "ENABLED"
    error_message = "state should default to ENABLED."
  }

  # action_after_completion is Optional+Computed on the real provider schema (AWS
  # decides the effective value server-side when omitted), so an unset value plans
  # as an unknown-at-plan-time placeholder under mocking rather than null. The
  # "set" branch is covered by action_after_completion_delete_is_applied below.

  assert {
    condition     = length(aws_scheduler_schedule.this.target) == 1
    error_message = "Exactly one target block should be created."
  }
}

run "outputs_expose_schedule_attributes" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  assert {
    condition     = output.arn == "arn:aws:scheduler:us-east-1:123456789012:schedule/default/example"
    error_message = "arn output should expose the mocked schedule ARN."
  }

  assert {
    condition     = output.id == "default/example"
    error_message = "id output should expose the mocked schedule id."
  }

  assert {
    condition     = output.name == aws_scheduler_schedule.this.name
    error_message = "name output should equal the resource's name attribute."
  }

  assert {
    condition     = output.group_name == aws_scheduler_schedule.this.group_name
    error_message = "group_name output should equal the resource's group_name attribute."
  }

  assert {
    condition     = output.state == aws_scheduler_schedule.this.state
    error_message = "state output should equal the resource's state attribute."
  }

  assert {
    condition     = output.schedule_expression == aws_scheduler_schedule.this.schedule_expression
    error_message = "schedule_expression output should equal the resource's schedule_expression attribute."
  }

  assert {
    condition     = output.schedule_expression_timezone == aws_scheduler_schedule.this.schedule_expression_timezone
    error_message = "schedule_expression_timezone output should equal the resource's schedule_expression_timezone attribute."
  }

  assert {
    condition     = output.target_arn == aws_scheduler_schedule.this.target[0].arn
    error_message = "target_arn output should equal the resource's target[0].arn attribute."
  }
}

run "name_prefix_branch_omits_name" {
  command = plan

  variables {
    name_prefix         = "example-"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  # name is Optional+Computed on the real provider schema (AWS assigns a random
  # unique name when omitted), so it plans as an unknown-at-plan-time placeholder
  # under mocking rather than null; only name_prefix's pass-through is assertable.
  assert {
    condition     = aws_scheduler_schedule.this.name_prefix == "example-"
    error_message = "name_prefix should be passed through to the resource."
  }
}

run "group_name_is_passed_through" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    group_name          = "my-schedule-group"
  }

  assert {
    condition     = aws_scheduler_schedule.this.group_name == "my-schedule-group"
    error_message = "group_name should be passed through to the resource."
  }

  assert {
    condition     = output.group_name == "my-schedule-group"
    error_message = "group_name output should reflect the supplied group_name."
  }
}

run "flexible_time_window_flexible_branch" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    flexible_time_window = {
      mode                      = "FLEXIBLE"
      maximum_window_in_minutes = 15
    }
  }

  assert {
    condition     = aws_scheduler_schedule.this.flexible_time_window[0].mode == "FLEXIBLE"
    error_message = "flexible_time_window.mode should be FLEXIBLE."
  }

  assert {
    condition     = aws_scheduler_schedule.this.flexible_time_window[0].maximum_window_in_minutes == 15
    error_message = "flexible_time_window.maximum_window_in_minutes should be passed through."
  }
}

run "non_utc_timezone_is_applied" {
  command = plan

  variables {
    name                         = "example-schedule"
    schedule_expression          = "rate(1 day)"
    target_arn                   = "arn:aws:lambda:us-east-1:123456789012:function:example"
    schedule_expression_timezone = "America/Denver"
  }

  assert {
    condition     = aws_scheduler_schedule.this.schedule_expression_timezone == "America/Denver"
    error_message = "schedule_expression_timezone should accept a non-UTC IANA timezone."
  }
}

run "state_disabled_is_applied" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    state               = "DISABLED"
  }

  assert {
    condition     = aws_scheduler_schedule.this.state == "DISABLED"
    error_message = "state should be passed through as DISABLED."
  }
}

run "start_and_end_date_are_applied" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    start_date          = "2030-01-01T00:00:00Z"
    end_date            = "2030-06-01T00:00:00Z"
  }

  assert {
    condition     = aws_scheduler_schedule.this.start_date == "2030-01-01T00:00:00Z"
    error_message = "start_date should be passed through."
  }

  assert {
    condition     = aws_scheduler_schedule.this.end_date == "2030-06-01T00:00:00Z"
    error_message = "end_date should be passed through."
  }
}

run "action_after_completion_delete_is_applied" {
  command = plan

  variables {
    name                    = "example-schedule"
    schedule_expression     = "at(2030-01-01T00:00:00)"
    target_arn              = "arn:aws:lambda:us-east-1:123456789012:function:example"
    action_after_completion = "DELETE"
  }

  assert {
    condition     = aws_scheduler_schedule.this.action_after_completion == "DELETE"
    error_message = "action_after_completion should be passed through as DELETE."
  }
}

run "kms_key_arn_is_applied" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    kms_key_arn         = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
  }

  assert {
    condition     = aws_scheduler_schedule.this.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
    error_message = "kms_key_arn should be passed through."
  }
}

run "region_override_is_honored" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    region              = "us-west-2"
  }

  assert {
    condition     = aws_scheduler_schedule.this.region == "us-west-2"
    error_message = "region override should be passed through to aws_scheduler_schedule.this."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
