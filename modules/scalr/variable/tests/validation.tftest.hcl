mock_provider "scalr" {
  mock_resource "scalr_variable" {
    defaults = {
      id = "var-abcd1234"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    variables = {
      aws_region = {
        key          = "AWS_REGION"
        category     = "shell"
        workspace_id = "ws-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_variable.this) == 1
    error_message = "Expected exactly one variable to be planned."
  }
}

run "rejects_entry_with_invalid_category" {
  command = plan

  variables {
    variables = {
      aws_region = {
        key          = "AWS_REGION"
        category     = "invalid"
        workspace_id = "ws-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.variables]
}

run "rejects_entry_with_two_scopes_set" {
  command = plan

  variables {
    variables = {
      aws_region = {
        key            = "AWS_REGION"
        category       = "shell"
        workspace_id   = "ws-xxxxxxxxxx"
        environment_id = "env-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.variables]
}

run "rejects_entry_with_no_scope_set" {
  command = plan

  variables {
    variables = {
      aws_region = {
        key      = "AWS_REGION"
        category = "shell"
      }
    }
  }

  expect_failures = [var.variables]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
