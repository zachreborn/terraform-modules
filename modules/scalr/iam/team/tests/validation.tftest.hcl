mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    teams = {
      dev = {
        description = "Developers"
      }
    }
  }

  assert {
    condition     = length(scalr_iam_team.this) == 1
    error_message = "Expected exactly one team to be planned."
  }
}

run "rejects_null_entry" {
  command = plan

  variables {
    teams = {
      dev = null
    }
  }

  expect_failures = [var.teams]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
