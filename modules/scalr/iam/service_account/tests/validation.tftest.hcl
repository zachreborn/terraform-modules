mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    account_id = "acc-xxxxxxxxxx"
    service_accounts = {
      ci = {
        status = "Inactive"
      }
    }
  }

  assert {
    condition     = length(scalr_service_account.this) == 1
    error_message = "Expected exactly one service account to be planned."
  }
}

run "rejects_null_entry" {
  command = plan

  variables {
    service_accounts = {
      ci = null
    }
  }

  expect_failures = [var.service_accounts]
}

run "rejects_entry_with_invalid_status" {
  command = plan

  variables {
    account_id = "acc-xxxxxxxxxx"
    service_accounts = {
      ci = {
        status = "Suspended"
      }
    }
  }

  expect_failures = [var.service_accounts]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
