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