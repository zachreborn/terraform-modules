mock_provider "aws" {
  mock_resource "aws_cloudformation_stack_set" {
    defaults = {
      id  = "test-stack-set"
      arn = "arn:aws:cloudformation:us-east-1:123456789012:stackset/test-stack-set:abcd1234-abcd-1234-abcd-1234567890ab"
    }
  }
}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    name                    = "test-stack-set"
    template_body           = jsonencode({ Resources = {} })
    organizational_unit_ids = ["ou-abcd-11111111"]
  }

  assert {
    condition     = output.arn == "arn:aws:cloudformation:us-east-1:123456789012:stackset/test-stack-set:abcd1234-abcd-1234-abcd-1234567890ab"
    error_message = "arn output should expose the stack set's arn."
  }

  assert {
    condition     = output.name == "test-stack-set"
    error_message = "name output should expose the stack set's name."
  }

  assert {
    condition     = output.id == "test-stack-set"
    error_message = "id output should expose the stack set's id."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.call_as == "SELF"
    error_message = "call_as should default to SELF."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.permission_model == "SERVICE_MANAGED"
    error_message = "permission_model should default to SERVICE_MANAGED."
  }

  assert {
    condition     = length(aws_cloudformation_stack_set.this.auto_deployment) == 1
    error_message = "auto_deployment block should be present by default (enable_auto_deployment defaults to true)."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.auto_deployment[0].enabled == true
    error_message = "auto_deployment.enabled should be true when the block is present."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.auto_deployment[0].retain_stacks_on_account_removal == false
    error_message = "retain_stacks_on_account_removal should default to false."
  }

  assert {
    condition     = length(aws_cloudformation_stack_set.this.managed_execution) == 0
    error_message = "managed_execution block should be absent by default (enable_managed_execution defaults to false)."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.operation_preferences[0].failure_tolerance_count == 0
    error_message = "failure_tolerance_count should default to 0 when failure_tolerance_percentage is null."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.operation_preferences[0].max_concurrent_count == 1
    error_message = "max_concurrent_count should default to 1 when max_concurrent_percentage is null."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.operation_preferences[0].region_concurrency_type == "SEQUENTIAL"
    error_message = "region_concurrency_type should default to SEQUENTIAL."
  }

  assert {
    condition     = aws_cloudformation_stack_set_instance.this.call_as == "SELF"
    error_message = "stack_set_instance call_as should default to SELF."
  }

  assert {
    condition     = aws_cloudformation_stack_set_instance.this.stack_set_name == "test-stack-set"
    error_message = "stack_set_instance should reference the stack set's name."
  }

  assert {
    condition     = aws_cloudformation_stack_set_instance.this.deployment_targets[0].organizational_unit_ids == toset(["ou-abcd-11111111"])
    error_message = "deployment_targets.organizational_unit_ids should pass through unchanged."
  }
}

# NOTE: main.tf's template_body/template_url ternaries have the same mutual-nulling defect
# as modules/aws/cloudformation/stack (tracked separately as issue #400, related to #377):
# each ternary checks the *other* variable independently, so supplying both nulls out both
# instead of one taking precedence. template_body is Optional+Computed in the AWS provider
# schema (template_url is not), so an explicit config-level null on template_body defers to
# the provider and is filled with an arbitrary mock value here rather than surfacing as a
# literal null -- hence we assert it no longer equals the caller-supplied literal, instead
# of asserting an exact null.
run "template_url_is_used_when_template_body_is_absent" {
  command = plan

  variables {
    name                    = "test-stack-set"
    template_url            = "https://example.org/template.json"
    organizational_unit_ids = ["ou-abcd-11111111"]
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.template_url == "https://example.org/template.json"
    error_message = "template_url should pass through when template_body is not set."
  }
}

run "providing_both_template_body_and_template_url_nulls_out_both" {
  command = plan

  variables {
    name                    = "test-stack-set"
    template_body           = jsonencode({ Resources = {} })
    template_url            = "https://example.org/template.json"
    organizational_unit_ids = ["ou-abcd-11111111"]
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.template_url == null
    error_message = "Current (buggy) behavior: template_url is nulled out when template_body is also non-null (tracked in issue #400)."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.template_body != jsonencode({ Resources = {} })
    error_message = "Current (buggy) behavior: the caller-supplied template_body literal is discarded when template_url is also non-null (tracked in issue #400)."
  }
}

run "disabling_auto_deployment_removes_the_block" {
  command = plan

  variables {
    name                    = "test-stack-set"
    template_body           = jsonencode({ Resources = {} })
    enable_auto_deployment  = false
    permission_model        = "SELF_MANAGED"
    administration_role_arn = "arn:aws:iam::123456789012:role/AdminRole"
    execution_role_name     = "AWSCloudFormationStackSetExecutionRole"
    organizational_unit_ids = ["ou-abcd-11111111"]
  }

  assert {
    condition     = length(aws_cloudformation_stack_set.this.auto_deployment) == 0
    error_message = "auto_deployment block should be absent when enable_auto_deployment is false."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.administration_role_arn == "arn:aws:iam::123456789012:role/AdminRole"
    error_message = "administration_role_arn should pass through unchanged."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.execution_role_name == "AWSCloudFormationStackSetExecutionRole"
    error_message = "execution_role_name should pass through unchanged."
  }
}

run "enabling_managed_execution_adds_the_block" {
  command = plan

  variables {
    name                     = "test-stack-set"
    template_body            = jsonencode({ Resources = {} })
    enable_managed_execution = true
    organizational_unit_ids  = ["ou-abcd-11111111"]
  }

  assert {
    condition     = length(aws_cloudformation_stack_set.this.managed_execution) == 1
    error_message = "managed_execution block should be present when enable_managed_execution is true."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.managed_execution[0].active == true
    error_message = "managed_execution.active should be true when the block is present."
  }
}

run "failure_tolerance_percentage_forces_count_to_null" {
  command = plan

  variables {
    name                         = "test-stack-set"
    template_body                = jsonencode({ Resources = {} })
    failure_tolerance_count      = 3
    failure_tolerance_percentage = 50
    organizational_unit_ids      = ["ou-abcd-11111111"]
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.operation_preferences[0].failure_tolerance_count == null
    error_message = "failure_tolerance_count should be forced to null when failure_tolerance_percentage is set, avoiding a real ConflictsWith error."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.operation_preferences[0].failure_tolerance_percentage == 50
    error_message = "failure_tolerance_percentage override should be honored."
  }
}

run "max_concurrent_percentage_forces_count_to_null" {
  command = plan

  variables {
    name                      = "test-stack-set"
    template_body             = jsonencode({ Resources = {} })
    max_concurrent_count      = 5
    max_concurrent_percentage = 75
    organizational_unit_ids   = ["ou-abcd-11111111"]
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.operation_preferences[0].max_concurrent_count == null
    error_message = "max_concurrent_count should be forced to null when max_concurrent_percentage is set, avoiding a real ConflictsWith error."
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.operation_preferences[0].max_concurrent_percentage == 75
    error_message = "max_concurrent_percentage override should be honored."
  }
}

run "stack_set_instance_deployment_targets_pass_through" {
  command = plan

  variables {
    name                      = "test-stack-set"
    template_body             = jsonencode({ Resources = {} })
    stack_set_instance_region = "us-west-2"
    accounts                  = ["111111111111", "222222222222"]
    account_filter_type       = "INTERSECTION"
    organizational_unit_ids   = ["ou-abcd-11111111"]
  }

  assert {
    condition     = aws_cloudformation_stack_set_instance.this.stack_set_instance_region == "us-west-2"
    error_message = "stack_set_instance_region should pass through unchanged."
  }

  assert {
    condition     = aws_cloudformation_stack_set_instance.this.deployment_targets[0].accounts == toset(["111111111111", "222222222222"])
    error_message = "deployment_targets.accounts should pass through unchanged."
  }

  assert {
    condition     = aws_cloudformation_stack_set_instance.this.deployment_targets[0].account_filter_type == "INTERSECTION"
    error_message = "deployment_targets.account_filter_type should pass through unchanged."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the module code has a bug and fix the root cause in main.tf / variables.tf /
# outputs.tf, then re-run `tofu test` until it passes for the right reason.
