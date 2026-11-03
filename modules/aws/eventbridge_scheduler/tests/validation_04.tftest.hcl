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
