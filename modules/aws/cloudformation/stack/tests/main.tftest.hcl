# Runs in this file either supply policy_body/template_body as concrete config
# values (so the mock must NOT try to default them -- overriding a configured
# value is rejected by OpenTofu) or do not exercise the body attributes at all.
# The complementary URL-precedence cases -- where the module nulls the
# Optional+Computed body attributes and we assert they resolve to null -- live in
# precedence.tftest.hcl, which mocks those attributes to null.
mock_provider "aws" {
  mock_resource "aws_cloudformation_stack" {
    defaults = {
      id      = "arn:aws:cloudformation:us-east-1:123456789012:stack/test-stack/abcd1234-abcd-1234-abcd-1234567890ab"
      outputs = { ExampleOutput = "example-value" }
    }
  }
}

###########################
# Valid baseline
###########################
run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    name          = "test-stack"
    template_body = "{\"Resources\":{}}"
  }

  assert {
    condition     = output.name == "test-stack"
    error_message = "name output should echo back var.name."
  }

  assert {
    condition     = output.id == "arn:aws:cloudformation:us-east-1:123456789012:stack/test-stack/abcd1234-abcd-1234-abcd-1234567890ab"
    error_message = "id output should expose the stack's id."
  }

  assert {
    condition     = output.outputs["ExampleOutput"] == "example-value"
    error_message = "outputs output should expose the stack's outputs map with the exact key/value returned by the stack."
  }

  assert {
    condition     = length(output.outputs) == 1
    error_message = "outputs output should contain exactly the one key returned by the mocked stack."
  }

  assert {
    condition     = aws_cloudformation_stack.this.timeout_in_minutes == 60
    error_message = "timeout_in_minutes should default to 60."
  }

  assert {
    condition     = aws_cloudformation_stack.this.on_failure == "ROLLBACK"
    error_message = "on_failure should default to ROLLBACK when disable_rollback is left at its default (false)."
  }

  assert {
    condition     = aws_cloudformation_stack.this.disable_rollback == false
    error_message = "disable_rollback should default to false."
  }
}

###########################
# policy_body used when policy_url absent (issue #377 fix)
###########################
run "only_policy_body_sends_body_and_nulls_url" {
  command = plan

  variables {
    name        = "test-stack"
    policy_body = "{\"Statement\":[]}"
  }

  assert {
    condition     = aws_cloudformation_stack.this.policy_body == "{\"Statement\":[]}"
    error_message = "policy_body should pass through when policy_url is not set."
  }

  assert {
    condition     = aws_cloudformation_stack.this.policy_url == null
    error_message = "policy_url should remain null when only policy_body is provided."
  }
}

###########################
# template_body used when template_url absent (issue #377 fix)
###########################
run "only_template_body_sends_body_and_nulls_url" {
  command = plan

  variables {
    name          = "test-stack"
    template_body = "{\"Resources\":{}}"
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_body == "{\"Resources\":{}}"
    error_message = "template_body should pass through when template_url is not set."
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_url == null
    error_message = "template_url should remain null when only template_body is provided."
  }
}

###########################
# disable_rollback / on_failure branches (existing conditional coverage)
###########################
run "disable_rollback_true_nulls_on_failure" {
  command = plan

  variables {
    name             = "test-stack"
    disable_rollback = true
    on_failure       = null
  }

  assert {
    condition     = aws_cloudformation_stack.this.disable_rollback == true
    error_message = "disable_rollback should be honored (true) when on_failure is null."
  }

  assert {
    condition     = aws_cloudformation_stack.this.on_failure == null
    error_message = "on_failure should be null when disable_rollback is true."
  }
}

run "on_failure_set_keeps_disable_rollback_false" {
  command = plan

  variables {
    name       = "test-stack"
    on_failure = "DELETE"
  }

  assert {
    condition     = aws_cloudformation_stack.this.on_failure == "DELETE"
    error_message = "on_failure override should be honored when disable_rollback is left at its default."
  }

  assert {
    condition     = aws_cloudformation_stack.this.disable_rollback == false
    error_message = "disable_rollback should stay false (its default) when on_failure is set."
  }
}

###########################
# Remaining pass-through attributes
###########################
run "capabilities_and_other_fields_pass_through" {
  command = plan

  variables {
    name               = "test-stack"
    capabilities       = ["CAPABILITY_IAM", "CAPABILITY_AUTO_EXPAND"]
    iam_role_arn       = "arn:aws:iam::123456789012:role/cfn-role"
    notification_arns  = ["arn:aws:sns:us-east-1:123456789012:cfn-notifications"]
    parameters         = { Environment = "prod" }
    timeout_in_minutes = 30
    tags               = { team = "platform" }
  }

  assert {
    condition     = aws_cloudformation_stack.this.capabilities == toset(["CAPABILITY_IAM", "CAPABILITY_AUTO_EXPAND"])
    error_message = "capabilities should pass through unchanged."
  }

  assert {
    condition     = aws_cloudformation_stack.this.iam_role_arn == "arn:aws:iam::123456789012:role/cfn-role"
    error_message = "iam_role_arn should pass through unchanged."
  }

  assert {
    condition     = aws_cloudformation_stack.this.notification_arns == toset(["arn:aws:sns:us-east-1:123456789012:cfn-notifications"])
    error_message = "notification_arns should pass through unchanged."
  }

  assert {
    condition     = aws_cloudformation_stack.this.parameters["Environment"] == "prod"
    error_message = "parameters should pass through unchanged."
  }

  assert {
    condition     = aws_cloudformation_stack.this.timeout_in_minutes == 30
    error_message = "timeout_in_minutes override should be honored."
  }

  assert {
    condition     = aws_cloudformation_stack.this.tags["team"] == "platform"
    error_message = "tags should pass through unchanged."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the module code has a bug and fix the root cause in main.tf / variables.tf /
# outputs.tf, then re-run `tofu test` until it passes for the right reason.
