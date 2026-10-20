mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name = "example_database"
  }

  assert {
    condition     = aws_glue_catalog_database.this.name == "example_database"
    error_message = "Expected the database to be planned with the given name."
  }
}

run "rejects_name_with_uppercase_characters" {
  command = plan

  variables {
    name = "Example_Database"
  }

  expect_failures = [var.name]
}

run "rejects_name_with_hyphen" {
  command = plan

  variables {
    name = "example-database"
  }

  expect_failures = [var.name]
}

run "rejects_empty_name" {
  command = plan

  variables {
    name = ""
  }

  expect_failures = [var.name]
}

run "accepts_name_with_numbers_and_underscores" {
  command = plan

  variables {
    name = "example_database_2"
  }

  assert {
    condition     = aws_glue_catalog_database.this.name == "example_database_2"
    error_message = "A name containing lowercase letters, numbers, and underscores should be accepted."
  }
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
