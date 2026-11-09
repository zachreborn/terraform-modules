mock_provider "aws" {}

variables {
  central_account_id = "222222222222"
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
