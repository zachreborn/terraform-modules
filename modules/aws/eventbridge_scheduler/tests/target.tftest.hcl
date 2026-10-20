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

run "static_target_input_is_passed_through" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_input        = jsonencode({ apply = false })
  }

  assert {
    condition     = jsondecode(aws_scheduler_schedule.this.target[0].input) == jsondecode(jsonencode({ apply = false }))
    error_message = "target_input should be passed through as a literal payload, with no input_transformer workaround needed."
  }
}

run "dead_letter_config_branch_creates_block" {
  command = plan

  variables {
    name                   = "example-schedule"
    schedule_expression    = "rate(1 day)"
    target_arn             = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_dead_letter_arn = "arn:aws:sqs:us-east-1:123456789012:example-dlq"
  }

  assert {
    condition     = length(aws_scheduler_schedule.this.target[0].dead_letter_config) == 1
    error_message = "A dead_letter_config block should be created when target_dead_letter_arn is set."
  }

  assert {
    condition     = aws_scheduler_schedule.this.target[0].dead_letter_config[0].arn == "arn:aws:sqs:us-east-1:123456789012:example-dlq"
    error_message = "dead_letter_config.arn should equal target_dead_letter_arn."
  }
}

run "retry_policy_branch_creates_block" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_retry_policy = {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 5
    }
  }

  assert {
    condition     = length(aws_scheduler_schedule.this.target[0].retry_policy) == 1
    error_message = "A retry_policy block should be created when target_retry_policy is set."
  }

  assert {
    condition     = aws_scheduler_schedule.this.target[0].retry_policy[0].maximum_event_age_in_seconds == 3600
    error_message = "retry_policy.maximum_event_age_in_seconds should be passed through."
  }

  assert {
    condition     = aws_scheduler_schedule.this.target[0].retry_policy[0].maximum_retry_attempts == 5
    error_message = "retry_policy.maximum_retry_attempts should be passed through."
  }
}

run "ecs_parameters_branch_creates_block" {
  command = plan

  variables {
    name                         = "example-schedule"
    schedule_expression          = "rate(1 day)"
    target_arn                   = "arn:aws:ecs:us-east-1:123456789012:cluster/example-cluster"
    target_role_policy_actions   = ["ecs:RunTask", "iam:PassRole"]
    target_role_policy_resources = ["arn:aws:ecs:us-east-1:123456789012:task-definition/example:1"]
    target_ecs_parameters = {
      task_definition_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/example:1"
      launch_type         = "FARGATE"
      task_count          = 1
      capacity_provider_strategy = [
        { capacity_provider = "FARGATE", base = 1, weight = 1 },
      ]
      network_configuration = {
        assign_public_ip = false
        subnets          = ["subnet-0123456789abcdef0"]
      }
      placement_constraints = [
        { type = "memberOf", expression = "attribute:ecs.availability-zone == us-east-1a" },
      ]
      placement_strategy = [
        { type = "spread", field = "attribute:ecs.availability-zone" },
      ]
    }
  }

  assert {
    condition     = length(aws_scheduler_schedule.this.target[0].ecs_parameters) == 1
    error_message = "An ecs_parameters block should be created when target_ecs_parameters is set."
  }

  assert {
    condition     = length(aws_scheduler_schedule.this.target[0].ecs_parameters[0].capacity_provider_strategy) == 1
    error_message = "The nested capacity_provider_strategy dynamic block should produce one element."
  }

  assert {
    condition     = length(aws_scheduler_schedule.this.target[0].ecs_parameters[0].network_configuration) == 1
    error_message = "The nested network_configuration dynamic block should produce one element."
  }

  assert {
    condition     = length(aws_scheduler_schedule.this.target[0].ecs_parameters[0].placement_constraints) == 1
    error_message = "The nested placement_constraints dynamic block should produce one element."
  }

  assert {
    condition     = length(aws_scheduler_schedule.this.target[0].ecs_parameters[0].placement_strategy) == 1
    error_message = "The nested placement_strategy dynamic block should produce one element."
  }
}

run "eventbridge_parameters_branch_creates_block" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:events:us-east-1:123456789012:event-bus/example-bus"
    target_eventbridge_parameters = {
      detail_type = "example-detail-type"
      source      = "example.source"
    }
  }

  assert {
    condition     = aws_scheduler_schedule.this.target[0].eventbridge_parameters[0].detail_type == "example-detail-type"
    error_message = "eventbridge_parameters.detail_type should be passed through."
  }

  assert {
    condition     = aws_scheduler_schedule.this.target[0].eventbridge_parameters[0].source == "example.source"
    error_message = "eventbridge_parameters.source should be passed through."
  }
}

run "kinesis_parameters_branch_creates_block" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:kinesis:us-east-1:123456789012:stream/example-stream"
    target_kinesis_parameters = {
      partition_key = "example-partition-key"
    }
  }

  assert {
    condition     = aws_scheduler_schedule.this.target[0].kinesis_parameters[0].partition_key == "example-partition-key"
    error_message = "kinesis_parameters.partition_key should be passed through."
  }
}

run "sagemaker_pipeline_parameters_branch_creates_block" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:sagemaker:us-east-1:123456789012:pipeline/example-pipeline"
    target_sagemaker_pipeline_parameters = {
      pipeline_parameter = [
        { name = "first", value = "one" },
        { name = "second", value = "two" },
      ]
    }
  }

  assert {
    condition     = length(aws_scheduler_schedule.this.target[0].sagemaker_pipeline_parameters[0].pipeline_parameter) == 2
    error_message = "The nested pipeline_parameter dynamic block should produce one element per list entry."
  }
}

run "sqs_parameters_branch_creates_block" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:sqs:us-east-1:123456789012:example-queue.fifo"
    target_sqs_parameters = {
      message_group_id = "example-group"
    }
  }

  assert {
    condition     = aws_scheduler_schedule.this.target[0].sqs_parameters[0].message_group_id == "example-group"
    error_message = "sqs_parameters.message_group_id should be passed through."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
