mock_provider "aws" {}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    name                = "test-rule"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.name == "test-rule"
    error_message = "name should pass through unchanged."
  }

  assert {
    condition     = aws_cloudwatch_event_target.event_target.arn == "arn:aws:sns:us-east-1:123456789012:test-topic"
    error_message = "event_target_arn should pass through unchanged to the target's arn."
  }

  assert {
    condition     = aws_cloudwatch_event_target.event_target.rule == "test-rule"
    error_message = "The target should reference the rule's name."
  }
}

run "field_defaults_are_applied" {
  command = plan

  variables {
    name                = "test-rule"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.state == "ENABLED"
    error_message = "state should default to ENABLED."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.description == null
    error_message = "description has no module-level default -- it must stay null when unset."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.tags["terraform"] == "true"
    error_message = "Default tags should include terraform = true."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.tags["Name"] == "test-rule"
    error_message = "Name tag should default to coalesce(var.name, var.name_prefix, \"cloudwatch-event\")."
  }
}

run "field_overrides_are_honored" {
  command = plan

  variables {
    name                = "test-rule"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
    description         = "Test rule description"
    state               = "DISABLED"
    role_arn            = "arn:aws:iam::123456789012:role/event-role"
    event_bus_name      = "custom-bus"
    target_id           = "test-target-id"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.description == "Test rule description"
    error_message = "description override should be honored."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.state == "DISABLED"
    error_message = "state override should be honored."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.role_arn == "arn:aws:iam::123456789012:role/event-role"
    error_message = "role_arn override should be honored."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.event_bus_name == "custom-bus"
    error_message = "event_bus_name override should be honored."
  }

  assert {
    condition     = aws_cloudwatch_event_target.event_target.target_id == "test-target-id"
    error_message = "target_id override should be honored."
  }
}

run "name_prefix_branch_is_used_instead_of_name" {
  command = plan

  variables {
    name_prefix         = "test-rule-"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.name_prefix == "test-rule-"
    error_message = "name_prefix should pass through unchanged when used instead of name."
  }
}

run "event_pattern_branch_is_used_instead_of_schedule_expression" {
  command = plan

  variables {
    name             = "test-rule"
    event_pattern    = jsonencode({ source = ["aws.ec2"] })
    event_target_arn = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  assert {
    condition     = aws_cloudwatch_event_rule.event_rule.event_pattern == jsonencode({ source = ["aws.ec2"] })
    error_message = "event_pattern should pass through unchanged when used instead of schedule_expression."
  }
}

run "input_transformer_absent_by_default" {
  command = plan

  variables {
    name                = "test-rule"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.event_target.input_transformer) == 0
    error_message = "input_transformer block should not be present when var.input_transformer is null."
  }
}

run "input_transformer_present_when_set" {
  command = plan

  variables {
    name                = "test-rule"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
    input_transformer = {
      input_paths    = { instance = "$.detail.instance-id" }
      input_template = "\"Instance <instance> state changed.\""
    }
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.event_target.input_transformer) == 1
    error_message = "input_transformer block should be present when var.input_transformer is set."
  }

  assert {
    condition     = aws_cloudwatch_event_target.event_target.input_transformer[0].input_template == "\"Instance <instance> state changed.\""
    error_message = "input_transformer.input_template should pass through unchanged."
  }
}

run "outputs_expose_resource_attributes" {
  command = plan

  variables {
    name                = "test-rule"
    schedule_expression = "rate(5 minutes)"
    event_target_arn    = "arn:aws:sns:us-east-1:123456789012:test-topic"
  }

  assert {
    condition     = output.arn != null
    error_message = "arn output should be populated."
  }

  assert {
    condition     = output.rule_name == "test-rule"
    error_message = "rule_name output should match the configured name."
  }

  assert {
    condition     = output.target_arn == "arn:aws:sns:us-east-1:123456789012:test-topic"
    error_message = "target_arn output should match the configured event_target_arn."
  }
}
