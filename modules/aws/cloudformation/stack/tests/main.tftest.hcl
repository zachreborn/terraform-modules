mock_provider "aws" {
  mock_resource "aws_cloudformation_stack" {
    defaults = {
      id      = "arn:aws:cloudformation:us-east-1:123456789012:stack/test-stack/abcd1234-abcd-1234-abcd-1234567890ab"
      outputs = { ExampleOutput = "example-value" }
    }
  }
}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    name = "test-stack"
  }

  assert {
    condition     = output.id == "arn:aws:cloudformation:us-east-1:123456789012:stack/test-stack/abcd1234-abcd-1234-abcd-1234567890ab"
    error_message = "id output should expose the stack's id."
  }

  assert {
    condition     = output.name == "test-stack"
    error_message = "name output should echo back var.name."
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

# NOTE: same root-cause pattern as the policy_body/policy_url and template_body/template_url
# mutual-nulling bugs tracked in issue #377 (broadened via a comment on that issue to cover
# this pair too): the disable_rollback/on_failure ternaries each check the *original* var
# independently (`disable_rollback = var.on_failure == null ? var.disable_rollback : false`
# and `on_failure = var.disable_rollback ? null : var.on_failure`), so when a caller
# supplies BOTH disable_rollback = true and a non-null on_failure, disable_rollback is
# forced back to false (discarding the caller's true) AND on_failure is nulled out
# (discarding the caller's requested value) -- neither input survives. This test documents
# the actual current plan-time behavior rather than the likely-intended one.
run "providing_both_disable_rollback_true_and_on_failure_nulls_out_both" {
  command = plan

  variables {
    name             = "test-stack"
    disable_rollback = true
    on_failure       = "DELETE"
  }

  assert {
    condition     = aws_cloudformation_stack.this.on_failure == null
    error_message = "Current (buggy) behavior: on_failure is nulled out when disable_rollback is true."
  }

  assert {
    condition     = aws_cloudformation_stack.this.disable_rollback == false
    error_message = "Current (buggy) behavior: disable_rollback is forced back to false (discarding the caller's true) because on_failure is also non-null."
  }
}

run "on_failure_set_forces_disable_rollback_to_false" {
  command = plan

  variables {
    name             = "test-stack"
    disable_rollback = false
    on_failure       = "DO_NOTHING"
  }

  assert {
    condition     = aws_cloudformation_stack.this.disable_rollback == false
    error_message = "disable_rollback should stay false when on_failure is set and disable_rollback was not requested."
  }

  assert {
    condition     = aws_cloudformation_stack.this.on_failure == "DO_NOTHING"
    error_message = "on_failure override should be honored when disable_rollback is false."
  }
}

# NOTE: main.tf's mutual-exclusion ternaries for policy_body/policy_url each check the
# *original* var against nullness independently (`policy_body = var.policy_url == null ?
# var.policy_body : null` and `policy_url = var.policy_body == null ? var.policy_url :
# null`), rather than one deterministically winning. When BOTH are supplied, this results
# in BOTH being nulled out at the config level -- so on a real (non-mocked) apply, NEITHER
# StackPolicyBody nor StackPolicyURL would be sent to the CloudFormation API, silently
# dropping the caller's intended policy -- rather than one taking precedence as the
# variable descriptions ("Conflicts with 'policy_url'/'policy_body' parameter") imply.
# TODO(https://github.com/zachreborn/terraform-modules/issues/377): this is a tracked
# module bug -- this test documents the actual current plan-time behavior rather than the
# likely-intended one. Note policy_body
# is Optional+Computed in the AWS provider schema (policy_url is not), so an explicit
# config-level null on policy_body defers to the provider and is filled with an arbitrary
# mock value here rather than surfacing as a literal null -- hence we assert it no longer
# equals the caller-supplied literal, instead of asserting an exact null.
run "providing_both_policy_body_and_policy_url_nulls_out_both" {
  command = plan

  variables {
    name        = "test-stack"
    policy_body = "{\"Statement\":[]}"
    policy_url  = "https://example.org/policy.json"
  }

  assert {
    condition     = aws_cloudformation_stack.this.policy_url == null
    error_message = "Current (buggy) behavior: policy_url is nulled out when policy_body is also non-null."
  }

  assert {
    condition     = aws_cloudformation_stack.this.policy_body != "{\"Statement\":[]}"
    error_message = "Current (buggy) behavior: the caller-supplied policy_body literal is discarded when policy_url is also non-null."
  }
}

run "policy_body_is_used_when_policy_url_is_absent" {
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
    error_message = "policy_url should remain null when not provided."
  }
}

run "policy_url_is_used_when_policy_body_is_absent" {
  command = plan

  variables {
    name       = "test-stack"
    policy_url = "https://example.org/policy.json"
  }

  assert {
    condition     = aws_cloudformation_stack.this.policy_url == "https://example.org/policy.json"
    error_message = "policy_url should pass through when policy_body is not set."
  }
}

# NOTE: same mutual-nulling behavior as policy_body/policy_url above -- see comment there.
# Also tracked by https://github.com/zachreborn/terraform-modules/issues/377.
# template_body is also Optional+Computed in the AWS provider schema (template_url is not).
run "providing_both_template_body_and_template_url_nulls_out_both" {
  command = plan

  variables {
    name          = "test-stack"
    template_body = "{\"Resources\":{}}"
    template_url  = "https://example.org/template.json"
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_url == null
    error_message = "Current (buggy) behavior: template_url is nulled out when template_body is also non-null."
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_body != "{\"Resources\":{}}"
    error_message = "Current (buggy) behavior: the caller-supplied template_body literal is discarded when template_url is also non-null."
  }
}

run "template_body_is_used_when_template_url_is_absent" {
  command = plan

  variables {
    name          = "test-stack"
    template_body = "{\"Resources\":{}}"
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_body == "{\"Resources\":{}}"
    error_message = "template_body should pass through when template_url is not set."
  }
}

run "template_url_is_used_when_template_body_is_absent" {
  command = plan

  variables {
    name         = "test-stack"
    template_url = "https://example.org/template.json"
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_url == "https://example.org/template.json"
    error_message = "template_url should pass through when template_body is not set."
  }
}

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
