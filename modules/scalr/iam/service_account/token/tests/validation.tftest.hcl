mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    tokens = {
      default = {
        service_account_id = "sa-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_service_account_token.this) == 1
    error_message = "Expected exactly one token to be planned."
  }
}

run "rejects_null_entry" {
  command = plan

  variables {
    tokens = {
      default = null
    }
  }

  expect_failures = [var.tokens]
}

run "rejects_entry_with_both_service_account_id_and_service_account_key" {
  command = plan

  variables {
    tokens = {
      default = {
        service_account_id  = "sa-xxxxxxxxxx"
        service_account_key = "ci"
      }
    }
  }

  expect_failures = [var.tokens]
}

run "rejects_entry_with_neither_service_account_id_nor_service_account_key" {
  command = plan

  variables {
    tokens = {
      default = {
        description = "no target service account"
      }
    }
  }

  expect_failures = [var.tokens]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
