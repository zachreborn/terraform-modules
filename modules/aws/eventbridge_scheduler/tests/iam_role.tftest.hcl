mock_provider "aws" {
  mock_resource "aws_scheduler_schedule" {
    defaults = {
      arn = "arn:aws:scheduler:us-east-1:123456789012:schedule/default/example-schedule"
      id  = "default/example-schedule"
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

run "created_role_arn_is_wired_into_the_schedule_target" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  assert {
    condition     = aws_scheduler_schedule.this.target[0].role_arn == "arn:aws:iam::123456789012:role/mock-scheduler-role"
    error_message = "The schedule target's role_arn should be wired from the created invoke role's ARN."
  }

  assert {
    condition     = output.target_role_arn == "arn:aws:iam::123456789012:role/mock-scheduler-role"
    error_message = "target_role_arn output should equal the created role's ARN."
  }

  assert {
    condition     = output.target_role_created == true
    error_message = "target_role_created should be true when the module creates the invoke role."
  }

  assert {
    condition     = output.target_role_name != null
    error_message = "target_role_name should be non-null when the module creates the invoke role."
  }

  assert {
    condition     = output.target_invoke_policy_arn == "arn:aws:iam::123456789012:policy/mock-invoke-policy"
    error_message = "target_invoke_policy_arn should equal the created invoke policy's ARN."
  }
}

run "supplied_role_arn_skips_role_creation" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_role_arn     = "arn:aws:iam::123456789012:role/external-role"
  }

  assert {
    condition     = aws_scheduler_schedule.this.target[0].role_arn == "arn:aws:iam::123456789012:role/external-role"
    error_message = "The schedule target's role_arn should equal the supplied target_role_arn."
  }

  assert {
    condition     = output.target_role_created == false
    error_message = "target_role_created should be false when the caller supplies target_role_arn."
  }

  assert {
    condition     = output.target_role_name == null
    error_message = "target_role_name should be null when the caller supplies target_role_arn."
  }

  assert {
    condition     = output.target_invoke_policy_arn == null
    error_message = "target_invoke_policy_arn should be null when the caller supplies target_role_arn."
  }

  assert {
    condition     = output.target_assume_role_policy_json == null
    error_message = "target_assume_role_policy_json should be null when the caller supplies target_role_arn."
  }

  assert {
    condition     = output.target_invoke_policy_json == null
    error_message = "target_invoke_policy_json should be null when the caller supplies target_role_arn."
  }
}

run "derived_invoke_policy_scopes_lambda_action_to_target_arn" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  assert {
    condition     = jsondecode(output.target_invoke_policy_json).Statement[0].Action == ["lambda:InvokeFunction"]
    error_message = "The derived invoke policy should scope a Lambda target to lambda:InvokeFunction."
  }

  assert {
    condition     = jsondecode(output.target_invoke_policy_json).Statement[0].Resource == ["arn:aws:lambda:us-east-1:123456789012:function:example"]
    error_message = "The derived invoke policy should be scoped to target_arn, not a wildcard."
  }
}

run "derived_invoke_policy_scopes_sqs_action_to_target_arn" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:sqs:us-east-1:123456789012:example-queue"
  }

  assert {
    condition     = jsondecode(output.target_invoke_policy_json).Statement[0].Action == ["sqs:SendMessage"]
    error_message = "The derivation map should be keyed on the ARN's service namespace, not hard-coded to Lambda."
  }
}

run "explicit_policy_actions_and_resources_override_derivation" {
  command = plan

  variables {
    name                         = "example-schedule"
    schedule_expression          = "rate(1 day)"
    target_arn                   = "arn:aws:ecs:us-east-1:123456789012:cluster/example-cluster"
    target_role_policy_actions   = ["ecs:RunTask", "iam:PassRole"]
    target_role_policy_resources = ["arn:aws:ecs:us-east-1:123456789012:task-definition/example:1"]
  }

  assert {
    condition     = jsondecode(output.target_invoke_policy_json).Statement[0].Action == ["ecs:RunTask", "iam:PassRole"]
    error_message = "Explicit target_role_policy_actions should override the derived action set verbatim."
  }

  assert {
    condition     = jsondecode(output.target_invoke_policy_json).Statement[0].Resource == ["arn:aws:ecs:us-east-1:123456789012:task-definition/example:1"]
    error_message = "Explicit target_role_policy_resources should override the [target_arn] default verbatim."
  }
}

run "dead_letter_queue_adds_send_message_statement" {
  command = plan

  variables {
    name                   = "example-schedule"
    schedule_expression    = "rate(1 day)"
    target_arn             = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_dead_letter_arn = "arn:aws:sqs:us-east-1:123456789012:example-dlq"
  }

  assert {
    condition     = length(jsondecode(output.target_invoke_policy_json).Statement) == 2
    error_message = "The invoke policy should gain a second statement when target_dead_letter_arn is set."
  }

  assert {
    condition     = jsondecode(output.target_invoke_policy_json).Statement[1].Action == "sqs:SendMessage"
    error_message = "The second statement should allow sqs:SendMessage on the dead-letter queue."
  }

  assert {
    condition     = jsondecode(output.target_invoke_policy_json).Statement[1].Resource == "arn:aws:sqs:us-east-1:123456789012:example-dlq"
    error_message = "The second statement should be scoped to target_dead_letter_arn."
  }
}

run "additional_policy_arns_are_attached_alongside_generated_policy" {
  command = plan

  variables {
    name                               = "example-schedule"
    schedule_expression                = "rate(1 day)"
    target_arn                         = "arn:aws:lambda:us-east-1:123456789012:function:example"
    target_role_additional_policy_arns = ["arn:aws:iam::aws:policy/SecretsManagerReadWrite"]
  }

  assert {
    condition     = output.target_role_created == true
    error_message = "The invoke role should still be created when additional policy ARNs are supplied."
  }

  assert {
    condition     = output.target_invoke_policy_arn == "arn:aws:iam::123456789012:policy/mock-invoke-policy"
    error_message = "The generated invoke policy ARN should remain present alongside the additional policy ARNs (concat should not replace it)."
  }
}

run "assume_role_policy_pins_service_and_source_account" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  assert {
    condition     = jsondecode(output.target_assume_role_policy_json).Statement[0].Principal.Service == "scheduler.amazonaws.com"
    error_message = "The trust policy should allow scheduler.amazonaws.com to assume the role."
  }

  assert {
    condition     = jsondecode(output.target_assume_role_policy_json).Statement[0].Action == "sts:AssumeRole"
    error_message = "The trust policy's action should be sts:AssumeRole."
  }

  assert {
    condition     = jsondecode(output.target_assume_role_policy_json).Statement[0].Condition.StringEquals["aws:SourceAccount"] == "123456789012"
    error_message = "The trust policy should pin aws:SourceAccount to the mocked caller identity account id."
  }
}

run "assume_role_policy_pins_source_arn_when_name_is_set" {
  command = plan

  variables {
    name                = "example-schedule"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  assert {
    condition     = jsondecode(output.target_assume_role_policy_json).Statement[0].Condition.ArnEquals["aws:SourceArn"] == "arn:aws:scheduler:us-east-1:123456789012:schedule/default/example-schedule"
    error_message = "The trust policy should pin aws:SourceArn to the schedule's constructed ARN when name is set."
  }
}

run "assume_role_policy_omits_source_arn_under_name_prefix" {
  command = plan

  variables {
    name_prefix         = "example-"
    schedule_expression = "rate(1 day)"
    target_arn          = "arn:aws:lambda:us-east-1:123456789012:function:example"
  }

  assert {
    condition     = !contains(keys(jsondecode(output.target_assume_role_policy_json).Statement[0].Condition), "ArnEquals")
    error_message = "The trust policy should omit the aws:SourceArn condition when the final name is unknown at plan time (name_prefix)."
  }

  assert {
    condition     = contains(keys(jsondecode(output.target_assume_role_policy_json).Statement[0].Condition), "StringEquals")
    error_message = "The trust policy should still pin aws:SourceAccount when name_prefix is used."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
