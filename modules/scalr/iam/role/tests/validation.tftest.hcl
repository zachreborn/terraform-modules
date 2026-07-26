mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    roles = {
      writer = {
        permissions = ["*:update"]
      }
    }
  }

  assert {
    condition     = length(scalr_role.this) == 1
    error_message = "Expected exactly one role to be planned."
  }
}

run "rejects_null_entry" {
  command = plan

  variables {
    roles = {
      writer = null
    }
  }

  expect_failures = [var.roles]
}

run "rejects_entry_with_empty_permissions" {
  command = plan

  variables {
    roles = {
      writer = {
        permissions = []
      }
    }
  }

  expect_failures = [var.roles]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
