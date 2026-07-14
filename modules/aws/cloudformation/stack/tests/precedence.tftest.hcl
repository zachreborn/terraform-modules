# These runs exercise the issue #377 fix: when a URL form is supplied, the module
# nulls the corresponding *_body attribute. policy_body and template_body are
# Optional+Computed in the AWS provider schema (policy_url and template_url are
# not), so a config-level null would otherwise be replaced by a provider-computed
# value. Defaulting them to null in the mock lets the assertions read a
# deterministic null. Every run here drives the resource's body attribute to null
# (never a concrete config value), so the mock defaults never override a
# configured value.
mock_provider "aws" {
  mock_resource "aws_cloudformation_stack" {
    defaults = {
      id            = "arn:aws:cloudformation:us-east-1:123456789012:stack/test-stack/abcd1234-abcd-1234-abcd-1234567890ab"
      outputs       = { ExampleOutput = "example-value" }
      policy_body   = null
      template_body = null
    }
  }
}

###########################
# policy_url used when policy_body absent (issue #377 fix)
###########################
run "only_policy_url_sends_url_and_nulls_body" {
  command = plan

  variables {
    name       = "test-stack"
    policy_url = "https://example.org/policy.json"
  }

  assert {
    condition     = aws_cloudformation_stack.this.policy_url == "https://example.org/policy.json"
    error_message = "policy_url should pass through when policy_body is not set."
  }

  assert {
    condition     = aws_cloudformation_stack.this.policy_body == null
    error_message = "policy_body should be null when only policy_url is provided."
  }
}

# The bug fixed by issue #377: supplying BOTH members of the pair used to null out
# both attributes. After the fix the URL form deterministically wins and the body
# is nulled -- never both-null.
run "policy_url_takes_precedence_over_policy_body" {
  command = plan

  variables {
    name        = "test-stack"
    policy_body = "{\"Statement\":[]}"
    policy_url  = "https://example.org/policy.json"
  }

  assert {
    condition     = aws_cloudformation_stack.this.policy_url == "https://example.org/policy.json"
    error_message = "policy_url should win when both policy_body and policy_url are supplied."
  }

  assert {
    condition     = aws_cloudformation_stack.this.policy_body == null
    error_message = "policy_body must be nulled (never both-null) when policy_url is also supplied."
  }
}

###########################
# template_url used when template_body absent (issue #377 fix)
###########################
run "only_template_url_sends_url_and_nulls_body" {
  command = plan

  variables {
    name         = "test-stack"
    template_url = "https://example.org/template.json"
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_url == "https://example.org/template.json"
    error_message = "template_url should pass through when template_body is not set."
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_body == null
    error_message = "template_body should be null when only template_url is provided."
  }
}

run "template_url_takes_precedence_over_template_body" {
  command = plan

  variables {
    name          = "test-stack"
    template_body = "{\"Resources\":{}}"
    template_url  = "https://example.org/template.json"
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_url == "https://example.org/template.json"
    error_message = "template_url should win when both template_body and template_url are supplied."
  }

  assert {
    condition     = aws_cloudformation_stack.this.template_body == null
    error_message = "template_body must be nulled (never both-null) when template_url is also supplied."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the module code has a bug and fix the root cause in main.tf, then re-run
# `tofu test` until it passes for the right reason.
