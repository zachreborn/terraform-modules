# Native OpenTofu tests for modules/scalr/integrations/checkov
#
# Run offline with:
#   tofu -chdir=modules/scalr/integrations/checkov init -backend=false
#   tofu -chdir=modules/scalr/integrations/checkov test

mock_provider "scalr" {
  mock_resource "scalr_checkov_integration" {
    defaults = {
      id = "in-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_plans" {
  command = plan

  variables {
    checkov_integrations = {
      default = {
        name         = "my-checkov-integration"
        environments = ["*"]
        cli_args     = "--quiet"
      }
    }
  }

  assert {
    condition     = length(scalr_checkov_integration.this) == 1
    error_message = "Expected exactly one Checkov integration to be planned."
  }

  assert {
    condition     = output.ids["default"] != null
    error_message = "ids output should contain the 'default' key."
  }

  assert {
    condition     = scalr_checkov_integration.this["default"].external_checks_enabled == false
    error_message = "external_checks_enabled should default to false."
  }
}

###########################################################
# Conditional branch coverage: external_checks_enabled true/false
###########################################################

run "plan_succeeds_with_external_checks_enabled" {
  command = plan

  variables {
    checkov_integrations = {
      custom_checks = {
        name                    = "custom-checks"
        external_checks_enabled = true
        vcs_provider_id         = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/my-checkov-checks"
          branch     = "main"
        }
      }
    }
  }

  assert {
    condition     = scalr_checkov_integration.this["custom_checks"].vcs_repo[0].identifier == "my-org/my-checkov-checks"
    error_message = "vcs_repo.identifier should be passed through from the input object."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_external_checks_enabled_without_vcs_provider_id" {
  command = plan

  variables {
    checkov_integrations = {
      custom_checks = {
        name                    = "custom-checks"
        external_checks_enabled = true
        vcs_repo = {
          identifier = "my-org/my-checkov-checks"
        }
      }
    }
  }

  expect_failures = [var.checkov_integrations]
}

run "rejects_external_checks_enabled_without_vcs_repo" {
  command = plan

  variables {
    checkov_integrations = {
      custom_checks = {
        name                    = "custom-checks"
        external_checks_enabled = true
        vcs_provider_id         = "vcs-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.checkov_integrations]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_integrations" {
  command = plan

  assert {
    condition     = length(scalr_checkov_integration.this) == 0
    error_message = "An empty checkov_integrations map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no integrations are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
