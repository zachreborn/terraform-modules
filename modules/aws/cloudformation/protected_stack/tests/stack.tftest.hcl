mock_provider "aws" {
  mock_resource "aws_cloudformation_stack" {
    defaults = {
      id       = "arn:aws:cloudformation:us-west-2:123456789012:stack/test-stack/test-id"
      outputs  = { RoleARN = "arn:aws:iam::123456789012:role/rubrik" }
      tags_all = { Name = "test-stack", environment = "test" }
    }
  }
}

variables {
  name          = "test-stack"
  template_body = "{\"Resources\":{}}"
}

run "baseline" {
  command = plan

  assert {
    condition     = output.name == "test-stack"
    error_message = "The name output must match the input."
  }

  assert {
    condition     = aws_cloudformation_stack.this.on_failure == "ROLLBACK" && aws_cloudformation_stack.this.disable_rollback != true
    error_message = "The baseline must enable rollback without disabling it."
  }

  assert {
    condition     = aws_cloudformation_stack.this.tags["Name"] == "test-stack"
    error_message = "A Name tag must be generated."
  }
}

run "complete_wiring" {
  command = plan

  variables {
    region            = "us-west-2"
    capabilities      = ["CAPABILITY_IAM"]
    iam_role_arn      = "arn:aws:iam::123456789012:role/cloudformation"
    notification_arns = ["arn:aws:sns:us-west-2:123456789012:operations"]
    parameters        = { Account = "example" }
    policy_body       = "{\"Statement\":[]}"
    tags              = { environment = "test", Name = "ignored" }
    timeouts          = { create = "90m", update = "120m", delete = "100m" }
  }

  assert {
    condition = (
      aws_cloudformation_stack.this.region == "us-west-2" &&
      aws_cloudformation_stack.this.capabilities == toset(["CAPABILITY_IAM"]) &&
      aws_cloudformation_stack.this.iam_role_arn == var.iam_role_arn &&
      aws_cloudformation_stack.this.notification_arns == toset(var.notification_arns) &&
      aws_cloudformation_stack.this.parameters == tomap(var.parameters) &&
      aws_cloudformation_stack.this.policy_body == var.policy_body &&
      aws_cloudformation_stack.this.template_body == var.template_body &&
      aws_cloudformation_stack.this.timeout_in_minutes == 60
    )
    error_message = "All stack arguments must reach the provider resource."
  }

  assert {
    condition = (
      aws_cloudformation_stack.this.timeouts.create == "90m" &&
      aws_cloudformation_stack.this.timeouts.update == "120m" &&
      aws_cloudformation_stack.this.timeouts.delete == "100m"
    )
    error_message = "Operation timeouts must be independently configurable."
  }

  assert {
    condition     = aws_cloudformation_stack.this.tags == tomap({ environment = "test", Name = "test-stack" })
    error_message = "The Name tag must not be overridden by caller tags."
  }
}

run "disable_rollback_omits_on_failure" {
  command = plan

  variables {
    disable_rollback = true
  }

  assert {
    condition     = aws_cloudformation_stack.this.disable_rollback == true && aws_cloudformation_stack.this.on_failure == null
    error_message = "Disabling rollback must omit the conflicting on_failure argument."
  }
}

run "null_failure_behavior" {
  command = plan

  variables {
    on_failure = null
  }

  assert {
    condition     = aws_cloudformation_stack.this.on_failure == null && aws_cloudformation_stack.this.disable_rollback != true
    error_message = "Null failure behavior must leave the AWS rollback defaults enabled."
  }
}

run "url_inputs" {
  command = plan

  variables {
    template_body = null
    template_url  = "https://example.s3.us-west-2.amazonaws.com/template.json"
    policy_url    = "https://example.s3.us-west-2.amazonaws.com/policy.json"
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_url == var.template_url && aws_cloudformation_stack.this.policy_url == var.policy_url
    error_message = "URL inputs must be passed through."
  }
}

run "reject_capability" {
  command = plan
  variables {
    capabilities = ["INVALID"]
  }
  expect_failures = [var.capabilities]
}

run "reject_name_characters" {
  command = plan
  variables {
    name = "bad_name"
  }
  expect_failures = [var.name]
}

run "reject_name_length" {
  command = plan
  variables {
    name = join("", [for index in range(129) : "a"])
  }
  expect_failures = [var.name]
}

run "reject_name_start" {
  command = plan
  variables {
    name = "1-invalid"
  }
  expect_failures = [var.name]
}

run "reject_topic_arn" {
  command = plan
  variables {
    notification_arns = ["not-an-arn"]
  }
  expect_failures = [var.notification_arns]
}

run "reject_fifo_topic" {
  command = plan
  variables {
    notification_arns = ["arn:aws:sns:us-west-2:123456789012:operations.fifo"]
  }
  expect_failures = [var.notification_arns]
}

run "reject_too_many_topics" {
  command = plan
  variables {
    notification_arns = [for index in range(6) : "arn:aws:sns:us-west-2:123456789012:operations-${index}"]
  }
  expect_failures = [var.notification_arns]
}

run "reject_failure_behavior" {
  command = plan
  variables {
    on_failure = "INVALID"
  }
  expect_failures = [var.on_failure]
}

run "reject_policy_json" {
  command = plan
  variables {
    policy_body = "not-json"
  }
  expect_failures = [var.policy_body]
}

run "reject_zero_timeout" {
  command = plan
  variables {
    timeout_in_minutes = 0
  }
  expect_failures = [var.timeout_in_minutes]
}

run "reject_negative_timeout" {
  command = plan
  variables {
    timeout_in_minutes = -1
  }
  expect_failures = [var.timeout_in_minutes]
}

run "reject_fractional_timeout" {
  command = plan
  variables {
    timeout_in_minutes = 1.5
  }
  expect_failures = [var.timeout_in_minutes]
}

run "reject_missing_template" {
  command = plan
  variables {
    template_body = null
  }
  expect_failures = [aws_cloudformation_stack.this]
}

run "reject_two_templates" {
  command = plan
  variables {
    template_url = "https://example.s3.us-west-2.amazonaws.com/template.json"
  }
  expect_failures = [aws_cloudformation_stack.this]
}

run "reject_two_policies" {
  command = plan
  variables {
    policy_body = "{\"Statement\":[]}"
    policy_url  = "https://example.s3.us-west-2.amazonaws.com/policy.json"
  }
  expect_failures = [aws_cloudformation_stack.this]
}
