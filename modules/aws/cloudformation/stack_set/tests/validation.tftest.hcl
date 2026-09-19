mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name                    = "test-stack-set"
    template_body           = jsonencode({ Resources = {} })
    call_as                 = "SELF"
    capabilities            = ["CAPABILITY_IAM"]
    permission_model        = "SERVICE_MANAGED"
    region_concurrency_type = "SEQUENTIAL"
    organizational_unit_ids = ["ou-abcd-11111111"]
  }

  assert {
    condition     = aws_cloudformation_stack_set.this.name == "test-stack-set"
    error_message = "Expected the stack set to plan successfully with valid inputs."
  }
}

run "rejects_invalid_call_as" {
  command = plan

  variables {
    name          = "test-stack-set"
    template_body = jsonencode({ Resources = {} })
    call_as       = "NOT_A_REAL_VALUE"
  }

  expect_failures = [var.call_as]
}

run "rejects_invalid_capability" {
  command = plan

  variables {
    name          = "test-stack-set"
    template_body = jsonencode({ Resources = {} })
    capabilities  = ["CAPABILITY_NOT_REAL"]
  }

  expect_failures = [var.capabilities]
}

run "rejects_both_template_body_and_template_url" {
  command = plan

  variables {
    name          = "test-stack-set"
    template_body = jsonencode({ Resources = {} })
    template_url  = "https://example.org/template.json"
  }

  expect_failures = [var.template_body]
}

run "rejects_invalid_template_url" {
  command = plan

  variables {
    name         = "test-stack-set"
    template_url = "s3://not-https-bucket/template.json"
  }

  expect_failures = [var.template_url]
}

run "rejects_invalid_permission_model" {
  command = plan

  variables {
    name             = "test-stack-set"
    template_body    = jsonencode({ Resources = {} })
    permission_model = "NOT_A_REAL_MODEL"
  }

  expect_failures = [var.permission_model]
}

run "rejects_invalid_region_concurrency_type" {
  command = plan

  variables {
    name                    = "test-stack-set"
    template_body           = jsonencode({ Resources = {} })
    region_concurrency_type = "NOT_A_REAL_TYPE"
  }

  expect_failures = [var.region_concurrency_type]
}

run "rejects_invalid_account_filter_type" {
  command = plan

  variables {
    name                = "test-stack-set"
    template_body       = jsonencode({ Resources = {} })
    account_filter_type = "NOT_A_REAL_FILTER"
  }

  expect_failures = [var.account_filter_type]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
