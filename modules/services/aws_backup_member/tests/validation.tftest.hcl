mock_provider "aws" {}

variables {
  central_account_id = "222222222222"
}

run "valid_baseline_does_not_fail" {
  command = plan

  assert {
    condition     = aws_backup_vault.staging.name == "backup-staging"
    error_message = "Expected the staging vault to plan with default inputs."
  }
}

run "rejects_non_12_digit_central_account_id" {
  command = plan

  variables {
    central_account_id = "12345"
  }

  expect_failures = [var.central_account_id]
}

run "rejects_non_numeric_central_account_id" {
  command = plan

  variables {
    central_account_id = "abcdefghijkl"
  }

  expect_failures = [var.central_account_id]
}

run "rejects_staging_retention_days_below_1" {
  command = plan

  variables {
    staging_retention_days = 0
  }

  expect_failures = [var.staging_retention_days]
}

run "rejects_unknown_vault_lock_mode" {
  command = plan

  variables {
    vault_lock_mode = "strict"
  }

  expect_failures = [var.vault_lock_mode]
}

run "rejects_changeable_for_days_below_3" {
  command = plan

  variables {
    changeable_for_days = 2
  }

  expect_failures = [var.changeable_for_days]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong — find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
