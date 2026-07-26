# Native OpenTofu tests for modules/scalr/integrations/infracost
#
# Run offline with:
#   tofu -chdir=modules/scalr/integrations/infracost init -backend=false
#   tofu -chdir=modules/scalr/integrations/infracost test

mock_provider "scalr" {
  mock_resource "scalr_integration_infracost" {
    defaults = {
      id = "in-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_plans" {
  command = plan

  variables {
    infracost_integrations = {
      default = {
        name         = "infracost"
        environments = ["*"]
      }
    }
    infracost_api_keys = {
      default = "ico-super-secret-key"
    }
  }

  assert {
    condition     = length(scalr_integration_infracost.this) == 1
    error_message = "Expected exactly one Infracost integration to be planned."
  }

  assert {
    condition     = output.ids["default"] != null
    error_message = "ids output should contain the 'default' key."
  }

  assert {
    condition     = output.infracost_integrations["default"].name == "infracost"
    error_message = "infracost_integrations output should expose the name attribute."
  }
}

run "api_key_flows_from_dedicated_variable" {
  command = plan

  variables {
    infracost_integrations = {
      default = {
        name = "infracost"
      }
    }
    infracost_api_keys = {
      default = "ico-super-secret-key"
    }
  }

  assert {
    condition     = scalr_integration_infracost.this["default"].api_key == "ico-super-secret-key"
    error_message = "api_key should resolve from var.infracost_api_keys via the matching logical name."
  }
}

###########################################################
# Precondition: expect_failures on the resource itself
###########################################################

run "rejects_entry_missing_from_api_keys" {
  command = plan

  variables {
    infracost_integrations = {
      default = {
        name = "infracost"
      }
    }
    # infracost_api_keys is intentionally left unset/empty -- no matching key for "default".
  }

  expect_failures = [scalr_integration_infracost.this]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_integrations" {
  command = plan

  assert {
    condition     = length(scalr_integration_infracost.this) == 0
    error_message = "An empty infracost_integrations map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no integrations are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
