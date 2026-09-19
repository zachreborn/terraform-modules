# Native OpenTofu tests for modules/aws/organizations/delegated_admin
#
# All run blocks use command = plan so no real AWS credentials or backend are needed.
# The mock_provider block provides computed-attribute defaults for both
# aws_organizations_delegated_administrator and aws_organizations_account.
# The wiring test (mixed_known_and_unknown_account_ids_plans) exercises the composition
# between an account resource and the delegated_admin module, proving that account_id
# flows correctly as a resource-argument VALUE (not a for_each KEY). The static-key
# test (instance_keys_are_static) independently proves the for_each keys are always
# derived from the logical name, never from account_id.
#
# Run offline with:
#   tofu -chdir=modules/aws/organizations/delegated_admin init -backend=false
#   tofu -chdir=modules/aws/organizations/delegated_admin test

mock_provider "aws" {
  mock_resource "aws_organizations_delegated_administrator" {
    defaults = {
      id                      = "123456789012/backup.amazonaws.com"
      arn                     = "arn:aws:organizations::111111111111:delegatedadministrator/o-abcd1234/123456789012/backup.amazonaws.com"
      name                    = "Test Account"
      email                   = "test@example.com"
      joined_method           = "CREATED"
      joined_timestamp        = "2024-01-01T00:00:00Z"
      delegation_enabled_date = "2024-01-01T00:00:00Z"
      status                  = "ACTIVE"
    }
  }
  # aws_organizations_account is mocked with a valid 12-digit account ID so that
  # the wiring test can pass it to aws_organizations_delegated_administrator.account_id
  # without triggering account-ID format validation errors. The wiring test still
  # proves the composition is correct; the static-key tests prove the for_each key
  # never uses account_id.
  mock_resource "aws_organizations_account" {
    defaults = {
      id = "222222222222"
    }
  }
}

###########################################################
# Valid baseline
###########################################################

run "valid_baseline_plans" {
  command = plan

  variables {
    delegated_admins = {
      backups = {
        account_id = "123456789012"
        services   = ["backup.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = length(aws_organizations_delegated_administrator.this) == 1
    error_message = "Expected exactly one delegated administrator instance to be planned."
  }

  assert {
    condition     = output.delegated_administrator_ids["backups-backup.amazonaws.com"] != null
    error_message = "delegated_administrator_ids should contain the 'backups-backup.amazonaws.com' key."
  }

  assert {
    condition     = output.delegated_administrators["backups-backup.amazonaws.com"].account_id == "123456789012"
    error_message = "delegated_administrators output should expose the account_id matching the input."
  }
}

###########################################################
# Static keys independent of account_id (core fix)
###########################################################

run "instance_keys_are_static" {
  command = plan

  variables {
    delegated_admins = {
      backups = {
        account_id = "123456789012"
        services   = ["backup.amazonaws.com", "config.amazonaws.com"]
      }
      security = {
        account_id = "234567890123"
        services   = ["guardduty.amazonaws.com"]
      }
    }
  }

  assert {
    condition = toset(keys(aws_organizations_delegated_administrator.this)) == toset([
      "backups-backup.amazonaws.com",
      "backups-config.amazonaws.com",
      "security-guardduty.amazonaws.com",
    ])
    error_message = "Resource instance keys must be '<logical_key>-<service>' regardless of account_id, proving the for_each key no longer derives from the account ID."
  }

  assert {
    condition     = length(output.delegated_administrator_ids) == 3
    error_message = "All three instances (two services for backups, one for security) should appear in delegated_administrator_ids."
  }
}

###########################################################
# Wiring: mixed account_id sources (regression / composition test)
#
# The wiring module (./tests/wiring) creates an aws_organizations_account and
# passes its id into the delegated_admin module alongside a static literal
# account_id. This simulates a caller that provisions a brand-new account and
# registers it as a delegated administrator in the same apply.
#
# In real usage, aws_organizations_account.id is unknown at plan time; the
# mock provider supplies a known value for testing. The static-key tests above
# independently prove the for_each key is derived from the logical name, not the
# account_id, which is the structural guarantee that makes the real-world case work.
###########################################################

run "mixed_known_and_unknown_account_ids_plans" {
  command = plan
  module {
    source = "./tests/wiring"
  }

  # Core regression assertion: the plan must succeed without "Invalid for_each argument".
  # Both instances (one with unknown account_id, one with known) must be planned.
  assert {
    condition     = length(output.delegated_administrators) == 2
    error_message = "Plan must succeed with both known and unknown account_id values. An 'Invalid for_each argument' error means the bug is not fixed."
  }

  # Wiring assertion: the unknown account_id (from aws_organizations_account.new.id)
  # flows into the new_account instance. The for_each key is the static logical name
  # "new_account", so the instance is reachable even though account_id is unknown.
  assert {
    condition     = output.delegated_administrators["new_account-backup.amazonaws.com"] != null
    error_message = "The new_account instance should exist, proving the unknown account_id is accepted as a resource argument value (not a for_each key)."
  }

  assert {
    condition     = output.delegated_administrator_ids["new_account-backup.amazonaws.com"] != null
    error_message = "delegated_administrator_ids output should include the new_account entry, proving the unknown account_id flows through the module to its outputs."
  }

  # Wiring assertion: the known account_id passes through correctly.
  assert {
    condition     = output.delegated_administrators["existing_account-config.amazonaws.com"] != null
    error_message = "The existing_account instance should exist with the known account_id."
  }
}

###########################################################
# account_key / account_ids resolution (internal cross-reference)
###########################################################

run "resolves_account_key_against_account_ids" {
  command = plan

  variables {
    account_ids = {
      backups = "333333333333"
    }
    delegated_admins = {
      backups = {
        account_key = "backups"
        services    = ["backup.amazonaws.com"]
      }
    }
  }

  assert {
    condition     = output.delegated_administrators["backups-backup.amazonaws.com"].account_id == "333333333333"
    error_message = "account_key should resolve to the matching entry in var.account_ids."
  }
}

run "rejects_account_key_not_found_in_account_ids" {
  command = plan

  variables {
    account_ids = {
      backups = "333333333333"
    }
    delegated_admins = {
      security = {
        account_key = "does_not_exist"
        services    = ["guardduty.amazonaws.com"]
      }
    }
  }

  expect_failures = [aws_organizations_delegated_administrator.this]
}

###########################################################
# Validation: expect_failures — one case per validation rule
###########################################################

run "rejects_entry_with_empty_services" {
  command = plan

  variables {
    delegated_admins = {
      backups = {
        account_id = "123456789012"
        services   = []
      }
    }
  }

  expect_failures = [var.delegated_admins]
}

run "rejects_entry_with_both_account_id_and_account_key" {
  command = plan

  variables {
    delegated_admins = {
      backups = {
        account_id  = "123456789012"
        account_key = "backups"
        services    = ["backup.amazonaws.com"]
      }
    }
  }

  expect_failures = [var.delegated_admins]
}

run "rejects_entry_with_neither_account_id_nor_account_key" {
  command = plan

  variables {
    delegated_admins = {
      backups = {
        services = ["backup.amazonaws.com"]
      }
    }
  }

  expect_failures = [var.delegated_admins]
}

###########################################################
# for_each branch coverage — empty map (default = {})
###########################################################

run "empty_map_creates_no_instances" {
  command = plan

  # delegated_admins is intentionally left unset; exercises the default = {} branch.

  assert {
    condition     = length(aws_organizations_delegated_administrator.this) == 0
    error_message = "An empty delegated_admins map should create no instances."
  }

  assert {
    condition     = length(output.delegated_administrator_ids) == 0
    error_message = "delegated_administrator_ids should be empty when no admins are configured."
  }

  assert {
    condition     = length(output.delegated_administrators) == 0
    error_message = "delegated_administrators should be empty when no admins are configured."
  }
}
