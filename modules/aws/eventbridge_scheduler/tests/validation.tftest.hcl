mock_provider "aws" {
  # aws_scheduler_schedule.this.target[0].role_arn is fed from the created invoke
  # role's arn (module.target_role[0].arn) whenever target_role_arn is omitted, which
  # is true for nearly every case in this file. Without explicit ARN-shaped defaults
  # here, the auto-generated mock values are opaque strings that fail the provider's
  # own ARN-format validation on role_arn/policy_arn before a run block's intended
  # validation/precondition failure is ever reached.
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
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  assert {
    condition     = aws_scheduler_schedule.this.schedule_expression == "rate(1 day)"
    error_message = "The valid baseline should plan successfully with the supplied schedule_expression."
  }
}

run "rejects_name_with_invalid_characters" {
  command = plan

  variables {
    name                = "example schedule!"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  expect_failures = [var.name]
}

run "rejects_name_longer_than_64_characters" {
  command = plan

  variables {
    name                = join("", [for i in range(65) : "a"])
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  expect_failures = [var.name]
}

run "rejects_name_prefix_with_invalid_characters" {
  command = plan

  variables {
    name_prefix         = "example schedule!"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  expect_failures = [var.name_prefix]
}

run "rejects_group_name_with_invalid_characters" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    group_name          = "example group!"
  }

  expect_failures = [var.group_name]
}

run "rejects_description_longer_than_512_characters" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    description         = join("", [for i in range(513) : "a"])
  }

  expect_failures = [var.description]
}

run "rejects_schedule_expression_without_at_rate_or_cron" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "every day"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  expect_failures = [var.schedule_expression]
}

run "rejects_empty_schedule_expression_timezone" {
  command = plan

  variables {
    name                         = "example-schedule"
    schedule_expression          = "rate(1 day)"
    target_arn                   = "arn:aws:lambda:us-east-1:123456789012:function:example"
    schedule_expression_timezone = ""
  }

  expect_failures = [var.schedule_expression_timezone]
}

run "rejects_start_date_that_is_not_rfc3339_utc" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    start_date          = "2030-01-01"
  }

  expect_failures = [var.start_date]
}

run "rejects_end_date_that_is_not_rfc3339_utc" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    end_date            = "2030-01-01"
  }

  expect_failures = [var.end_date]
}

run "rejects_invalid_state" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    state               = "PAUSED"
  }

  expect_failures = [var.state]
}

run "rejects_invalid_action_after_completion" {
  command = plan

  variables {
    name                    = "example-schedule"
    schedule_expression     = "rate(1 day)"
    target_arn              = "arn:aws:lambda:us-east-1:123456789012:function:example"
    action_after_completion = "ARCHIVE"
  }

  expect_failures = [var.action_after_completion]
}

run "rejects_kms_key_arn_that_is_not_an_arn" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    kms_key_arn         = "not-an-arn"
  }

  expect_failures = [var.kms_key_arn]
}

run "rejects_invalid_flexible_time_window_mode" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    flexible_time_window = {
      mode = "SOMETIMES"
    }
  }

  expect_failures = [var.flexible_time_window]
}

run "rejects_flexible_mode_without_maximum_window_in_minutes" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    flexible_time_window = {
      mode = "FLEXIBLE"
    }
  }

  expect_failures = [var.flexible_time_window]
}

run "rejects_maximum_window_in_minutes_above_1440" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    flexible_time_window = {
      mode                      = "FLEXIBLE"
      maximum_window_in_minutes = 1441
    }
  }

  expect_failures = [var.flexible_time_window]
}

run "rejects_maximum_window_in_minutes_when_mode_is_off" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    flexible_time_window = {
      mode                      = "OFF"
      maximum_window_in_minutes = 15
    }
  }

  expect_failures = [var.flexible_time_window]
}

run "rejects_target_arn_that_is_not_an_arn" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "not-an-arn"
  }

  expect_failures = [var.target_arn]
}

run "rejects_target_role_arn_that_is_not_an_arn" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_role_arn     = "not-an-arn"
  }

  expect_failures = [var.target_role_arn]
}

run "rejects_target_dead_letter_arn_that_is_not_an_arn" {
  command = plan

  variables {
    name                   = "example-schedule"
    schedule_expression    = "rate(1 day)"
    target_arn             = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_dead_letter_arn = "not-an-arn"
  }

  expect_failures = [var.target_dead_letter_arn]
}

run "rejects_maximum_event_age_below_60" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_retry_policy = {
      maximum_event_age_in_seconds = 30
    }
  }

  expect_failures = [var.target_retry_policy]
}

run "rejects_maximum_retry_attempts_above_185" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_retry_policy = {
      maximum_retry_attempts = 186
    }
  }

  expect_failures = [var.target_retry_policy]
}

run "rejects_invalid_ecs_launch_type" {
  command = plan

  variables {
    name                       = "example-schedule"
    schedule_expression        = "rate(1 day)"
    target_arn                 = "arn:aws:ecs:us-east-1:123456789012:cluster/example-cluster"
    target_role_policy_actions = ["ecs:RunTask"]
    target_ecs_parameters = {
      task_definition_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/example:1"
      launch_type         = "SERVERLESS"
    }
  }

  expect_failures = [var.target_ecs_parameters]
}

run "rejects_ecs_task_count_above_10" {
  command = plan

  variables {
    name                       = "example-schedule"
    schedule_expression        = "rate(1 day)"
    target_arn                 = "arn:aws:ecs:us-east-1:123456789012:cluster/example-cluster"
    target_role_policy_actions = ["ecs:RunTask"]
    target_ecs_parameters = {
      task_definition_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/example:1"
      task_count          = 11
    }
  }

  expect_failures = [var.target_ecs_parameters]
}

run "rejects_more_than_six_capacity_provider_strategies" {
  command = plan

  variables {
    name                       = "example-schedule"
    schedule_expression        = "rate(1 day)"
    target_arn                 = "arn:aws:ecs:us-east-1:123456789012:cluster/example-cluster"
    target_role_policy_actions = ["ecs:RunTask"]
    target_ecs_parameters = {
      task_definition_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/example:1"
      capacity_provider_strategy = [
        for i in range(7) : { capacity_provider = "FARGATE" }
      ]
    }
  }

  expect_failures = [var.target_ecs_parameters]
}

run "rejects_more_than_ten_placement_constraints" {
  command = plan

  variables {
    name                       = "example-schedule"
    schedule_expression        = "rate(1 day)"
    target_arn                 = "arn:aws:ecs:us-east-1:123456789012:cluster/example-cluster"
    target_role_policy_actions = ["ecs:RunTask"]
    target_ecs_parameters = {
      task_definition_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/example:1"
      placement_constraints = [
        for i in range(11) : { type = "memberOf", expression = "attribute:ecs.availability-zone == us-east-1a" }
      ]
    }
  }

  expect_failures = [var.target_ecs_parameters]
}

run "rejects_more_than_five_placement_strategies" {
  command = plan

  variables {
    name                       = "example-schedule"
    schedule_expression        = "rate(1 day)"
    target_arn                 = "arn:aws:ecs:us-east-1:123456789012:cluster/example-cluster"
    target_role_policy_actions = ["ecs:RunTask"]
    target_ecs_parameters = {
      task_definition_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/example:1"
      placement_strategy = [
        for i in range(6) : { type = "spread" }
      ]
    }
  }

  expect_failures = [var.target_ecs_parameters]
}

run "rejects_detail_type_longer_than_128_characters" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:events:us-east-1:123456789012:event-bus/example-bus"
    target_eventbridge_parameters = {
      detail_type = join("", [for i in range(129) : "a"])
      source      = "example.source"
    }
  }

  expect_failures = [var.target_eventbridge_parameters]
}

run "rejects_empty_kinesis_partition_key" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:kinesis:us-east-1:123456789012:stream/example-stream"
    target_kinesis_parameters = {
      partition_key = ""
    }
  }

  expect_failures = [var.target_kinesis_parameters]
}

run "rejects_more_than_200_pipeline_parameters" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:sagemaker:us-east-1:123456789012:pipeline/example-pipeline"
    target_sagemaker_pipeline_parameters = {
      pipeline_parameter = [
        for i in range(201) : { name = "param-${i}", value = "value-${i}" }
      ]
    }
  }

  expect_failures = [var.target_sagemaker_pipeline_parameters]
}

run "rejects_empty_target_role_policy_actions" {
  command = plan

  variables {
    name                       = "example-schedule"
    schedule_expression        = "rate(1 day)"
    target_arn                 = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_role_policy_actions = []
  }

  expect_failures = [var.target_role_policy_actions]
}

run "rejects_target_role_policy_resources_that_are_not_arns" {
  command = plan

  variables {
    name                         = "example-schedule"
    schedule_expression          = "rate(1 day)"
    target_arn                   = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_role_policy_resources = ["not-an-arn"]
  }

  expect_failures = [var.target_role_policy_resources]
}

run "rejects_additional_policy_arn_that_is_not_an_arn" {
  command = plan

  variables {
    name                               = "example-schedule"
    schedule_expression                = "rate(1 day)"
    target_arn                         = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_role_additional_policy_arns = ["not-an-arn"]
  }

  expect_failures = [var.target_role_additional_policy_arns]
}

run "rejects_target_role_max_session_duration_below_3600" {
  command = plan

  variables {
    name                             = "example-schedule"
    schedule_expression              = "rate(1 day)"
    target_arn                       = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_role_max_session_duration = 100
  }

  expect_failures = [var.target_role_max_session_duration]
}

run "rejects_both_name_and_name_prefix" {
  command = plan

  variables {
    name                = "example-schedule"
    name_prefix         = "example-"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  expect_failures = [aws_scheduler_schedule.this]
}

run "rejects_neither_name_nor_name_prefix" {
  command = plan

  variables {
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  expect_failures = [aws_scheduler_schedule.this]
}

run "rejects_two_templated_parameter_blocks" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:sqs:us-east-1:123456789012:example-queue"
    target_sqs_parameters = {
      message_group_id = "example-group"
    }
    target_kinesis_parameters = {
      partition_key = "example-partition-key"
    }
  }

  expect_failures = [aws_scheduler_schedule.this]
}

run "rejects_ecs_target_without_explicit_policy_actions" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:ecs:us-east-1:123456789012:cluster/example-cluster"
  }

  expect_failures = [aws_scheduler_schedule.this]
}

run "rejects_universal_target_without_explicit_policy_actions" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:scheduler:::aws-sdk:sqs:sendMessage"
  }

  expect_failures = [aws_scheduler_schedule.this]
}

run "rejects_end_date_before_start_date" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    start_date          = "2030-06-01T00:00:00Z"
    end_date            = "2030-01-01T00:00:00Z"
  }

  expect_failures = [aws_scheduler_schedule.this]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}`/`precondition {}` block in main.tf/variables.tf has a bug or the test's
# inputs are wrong -- find and fix the root cause, then re-run `tofu test` until it passes
# for the right reason.
