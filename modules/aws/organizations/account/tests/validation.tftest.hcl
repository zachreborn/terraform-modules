mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email     = "jdoe@example.com"
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = length(aws_organizations_account.this) == 1
    error_message = "Expected exactly one account to be planned."
  }
}

run "rejects_entry_with_both_parent_id_and_parent_key" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email      = "jdoe@example.com"
        parent_id  = "r-abcd1234"
        parent_key = "workloads"
      }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_entry_with_neither_parent_id_nor_parent_key" {
  command = plan

  variables {
    accounts = {
      company_ventures = {
        email = "jdoe@example.com"
      }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_null_entry" {
  command = plan

  variables {
    accounts = {
      company_ventures = null
    }
  }

  expect_failures = [var.accounts]
}
