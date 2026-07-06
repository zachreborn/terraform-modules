mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    organizational_units = {
      workloads = {
        parent_id = "r-abcd1234"
      }
    }
  }

  assert {
    condition     = length(aws_organizations_organizational_unit.level_0) == 1
    error_message = "Expected exactly one level_0 OU to be planned."
  }
}

run "rejects_entry_with_both_parent_id_and_parent_key" {
  command = plan

  variables {
    organizational_units = {
      workloads = {
        parent_id  = "r-abcd1234"
        parent_key = "other"
      }
    }
  }

  expect_failures = [var.organizational_units]
}

run "rejects_entry_with_neither_parent_id_nor_parent_key" {
  command = plan

  variables {
    organizational_units = {
      workloads = {}
    }
  }

  expect_failures = [var.organizational_units]
}

run "rejects_null_entry" {
  command = plan

  variables {
    organizational_units = {
      workloads = null
    }
  }

  expect_failures = [var.organizational_units]
}

run "rejects_parent_key_referencing_missing_key" {
  command = plan

  variables {
    organizational_units = {
      workloads = {
        parent_key = "does_not_exist"
      }
    }
  }

  expect_failures = [var.organizational_units]
}

run "rejects_self_referencing_parent_key" {
  command = plan

  variables {
    organizational_units = {
      workloads = {
        parent_key = "workloads"
      }
    }
  }

  expect_failures = [var.organizational_units]
}
