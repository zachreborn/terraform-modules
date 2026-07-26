# Native OpenTofu tests for modules/scalr/account_allowed_ips
#
# Run offline with:
#   tofu -chdir=modules/scalr/account_allowed_ips init -backend=false
#   tofu -chdir=modules/scalr/account_allowed_ips test

mock_provider "scalr" {
  mock_resource "scalr_account_allowed_ips" {
    defaults = {
      id = "acc-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_plans" {
  command = plan

  variables {
    account_allowed_ips = {
      default = {
        account_id  = "acc-xxxxxxxxxx"
        allowed_ips = ["caller-ip-placeholder", "office-network-cidr-placeholder"]
      }
    }
  }

  assert {
    condition     = length(scalr_account_allowed_ips.this) == 1
    error_message = "Expected exactly one account allowed-IP list to be planned."
  }

  assert {
    condition     = output.ids["default"] != null
    error_message = "ids output should contain the 'default' key."
  }

  assert {
    condition     = length(output.account_allowed_ips["default"].allowed_ips) == 2
    error_message = "account_allowed_ips output should expose both configured entries."
  }
}

###########################################################
# account_id fallback
###########################################################

run "account_id_falls_back_to_module_default" {
  command = plan

  variables {
    account_id = "acc-default000"
    account_allowed_ips = {
      default = {
        allowed_ips = ["caller-ip-placeholder"]
      }
    }
  }

  assert {
    condition     = scalr_account_allowed_ips.this["default"].account_id == "acc-default000"
    error_message = "account_id should fall back to var.account_id when the entry omits its own."
  }
}

run "account_id_entry_override_wins" {
  command = plan

  variables {
    account_id = "acc-default000"
    account_allowed_ips = {
      default = {
        account_id  = "acc-override00"
        allowed_ips = ["caller-ip-placeholder"]
      }
    }
  }

  assert {
    condition     = scalr_account_allowed_ips.this["default"].account_id == "acc-override00"
    error_message = "An entry's own account_id should take precedence over var.account_id."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_entry_with_empty_allowed_ips" {
  command = plan

  variables {
    account_allowed_ips = {
      default = {
        account_id  = "acc-xxxxxxxxxx"
        allowed_ips = []
      }
    }
  }

  expect_failures = [var.account_allowed_ips]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_instances" {
  command = plan

  assert {
    condition     = length(scalr_account_allowed_ips.this) == 0
    error_message = "An empty account_allowed_ips map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no entries are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
