mock_provider "aws" {}

run "valid_nested_parent_does_not_fail" {
  command = plan

  variables {
    name       = "example-api"
    stage_name = "prod"

    resources = {
      v1 = {
        path_part = "v1"
      }
      leads = {
        path_part           = "leads"
        parent_resource_key = "v1"
      }
    }
  }

  assert {
    condition     = length(aws_api_gateway_resource.this) == 1 && length(aws_api_gateway_resource.nested) == 1
    error_message = "Expected nested resources to plan successfully."
  }
}

run "rejects_unknown_parent_resource_key" {
  command = plan

  variables {
    name       = "example-api"
    stage_name = "prod"

    resources = {
      leads = {
        path_part           = "leads"
        parent_resource_key = "missing"
      }
    }
  }

  expect_failures = [var.resources]
}

run "rejects_self_parent_resource_key" {
  command = plan

  variables {
    name       = "example-api"
    stage_name = "prod"

    resources = {
      leads = {
        path_part           = "leads"
        parent_resource_key = "leads"
      }
    }
  }

  expect_failures = [var.resources]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
