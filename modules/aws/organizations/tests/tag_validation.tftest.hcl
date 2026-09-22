mock_provider "aws" {
  mock_resource "aws_organizations_organizational_unit" {
    defaults = {
      id = "ou-abcd-11111111"
    }
  }

  mock_resource "aws_organizations_account" {
    defaults = {
      id = "222222222222"
    }
  }
}

# These wrapper-level cases prove the composed module duplicates the account submodule's tag
# validation on its own `accounts` variable, rather than relying on the submodule alone -- the
# submodule's own validation is not a checkable object these tests could reference with
# expect_failures (see modules/aws/organizations/tests/wiring.tftest.hcl (54-57) for the same
# reasoning applied to the ou submodule).
run "rejects_account_entry_tag_value_with_disallowed_character" {
  command = plan

  variables {
    organizational_units = {
      workloads = { parent_id = "r-abcd1234" }
    }
    accounts = {
      company_ventures = {
        email      = "jdoe@example.com"
        parent_key = "workloads"
        tags = {
          purpose = "Public-facing personal static websites (S3 + CloudFront)."
        }
      }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_account_entry_tag_key_with_disallowed_character" {
  command = plan

  variables {
    organizational_units = {
      workloads = { parent_id = "r-abcd1234" }
    }
    accounts = {
      company_ventures = {
        email      = "jdoe@example.com"
        parent_key = "workloads"
        tags = {
          "purpose(1)" = "web"
        }
      }
    }
  }

  expect_failures = [var.accounts]
}

run "rejects_wrapper_tag_value_with_disallowed_character" {
  command = plan

  variables {
    tags = {
      purpose = "Public-facing personal static websites (S3 + CloudFront)."
    }
    organizational_units = {
      workloads = { parent_id = "r-abcd1234" }
    }
  }

  expect_failures = [var.tags]
}

run "rejects_wrapper_tag_key_with_disallowed_character" {
  command = plan

  variables {
    tags = {
      "purpose(1)" = "web"
    }
    organizational_units = {
      workloads = { parent_id = "r-abcd1234" }
    }
  }

  expect_failures = [var.tags]
}

# Wiring case: proves the shared var.tags still reaches both the account and ou submodules with the
# new validations in place, and that valid per-entry accounts[key].tags continue to plan successfully.
run "valid_tags_plan_successfully_through_the_wrapper" {
  command = plan

  variables {
    tags = {
      terraform = "true"
      team      = "platform"
    }
    organizational_units = {
      workloads = { parent_id = "r-abcd1234" }
    }
    accounts = {
      company_ventures = {
        email      = "jdoe@example.com"
        parent_key = "workloads"
        tags = {
          purpose = "Public facing website"
        }
      }
    }
  }

  assert {
    condition     = output.account_ids["company_ventures"] != null
    error_message = "Account should plan successfully with valid module-level and per-entry tags."
  }

  assert {
    condition     = output.organizational_unit_ids["workloads"] != null
    error_message = "OU should plan successfully with valid module-level tags."
  }
}
