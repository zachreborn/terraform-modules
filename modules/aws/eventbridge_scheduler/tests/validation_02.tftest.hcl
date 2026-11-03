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