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