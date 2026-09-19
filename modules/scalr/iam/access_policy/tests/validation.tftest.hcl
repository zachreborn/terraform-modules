mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    access_policies = {
      team_read_all_on_acc_scope = {
        role_ids = ["role-abcd1234"]
        subject = {
          type = "team"
          id   = "team-xxxxxxxxxx"
        }
        scope = {
          type = "account"
          id   = "acc-xxxxxxxxxx"
        }
      }
    }
  }

  assert {
    condition     = length(scalr_access_policy.this) == 1
    error_message = "Expected exactly one access policy to be planned."
  }
}

run "rejects_null_entry" {
  command = plan

  variables {
    access_policies = {
      broken = null
    }
  }

  expect_failures = [var.access_policies]
}

run "rejects_entry_with_empty_role_ids" {
  command = plan

  variables {
    access_policies = {
      broken = {
        role_ids = []
        subject = {
          type = "team"
          id   = "team-xxxxxxxxxx"
        }
        scope = {
          type = "account"
          id   = "acc-xxxxxxxxxx"
        }
      }
    }
  }

  expect_failures = [var.access_policies]
}

run "rejects_invalid_subject_type" {
  command = plan

  variables {
    access_policies = {
      broken = {
        role_ids = ["role-abcd1234"]
        subject = {
          type = "group"
          id   = "team-xxxxxxxxxx"
        }
        scope = {
          type = "account"
          id   = "acc-xxxxxxxxxx"
        }
      }
    }
  }

  expect_failures = [var.access_policies]
}

run "rejects_invalid_scope_type" {
  command = plan

  variables {
    access_policies = {
      broken = {
        role_ids = ["role-abcd1234"]
        subject = {
          type = "team"
          id   = "team-xxxxxxxxxx"
        }
        scope = {
          type = "organization"
          id   = "acc-xxxxxxxxxx"
        }
      }
    }
  }

  expect_failures = [var.access_policies]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
