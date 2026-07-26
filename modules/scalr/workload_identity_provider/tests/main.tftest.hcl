# Native OpenTofu tests for modules/scalr/workload_identity_provider
#
# Run offline with:
#   tofu -chdir=modules/scalr/workload_identity_provider init -backend=false
#   tofu -chdir=modules/scalr/workload_identity_provider test

mock_provider "scalr" {
  mock_resource "scalr_workload_identity_provider" {
    defaults = {
      id = "wip-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_plans" {
  command = plan

  variables {
    workload_identity_providers = {
      github_actions = {
        name              = "github-actions"
        url               = "https://token.actions.githubusercontent.com"
        allowed_audiences = ["scalr-github-actions"]
      }
    }
  }

  assert {
    condition     = length(scalr_workload_identity_provider.this) == 1
    error_message = "Expected exactly one workload identity provider to be planned."
  }

  assert {
    condition     = output.ids["github_actions"] != null
    error_message = "ids output should contain the 'github_actions' key."
  }
}

run "plan_succeeds_with_max_audiences" {
  command = plan

  variables {
    workload_identity_providers = {
      many_audiences = {
        name              = "many-audiences"
        url               = "https://example.com"
        allowed_audiences = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10"]
      }
    }
  }

  assert {
    condition     = length(scalr_workload_identity_provider.this["many_audiences"].allowed_audiences) == 10
    error_message = "Exactly 10 allowed_audiences should be accepted (the upper bound)."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_entry_with_zero_audiences" {
  command = plan

  variables {
    workload_identity_providers = {
      github_actions = {
        name              = "github-actions"
        url               = "https://token.actions.githubusercontent.com"
        allowed_audiences = []
      }
    }
  }

  expect_failures = [var.workload_identity_providers]
}

run "rejects_entry_with_more_than_ten_audiences" {
  command = plan

  variables {
    workload_identity_providers = {
      too_many = {
        name              = "too-many"
        url               = "https://example.com"
        allowed_audiences = ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", "a11"]
      }
    }
  }

  expect_failures = [var.workload_identity_providers]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_providers" {
  command = plan

  assert {
    condition     = length(scalr_workload_identity_provider.this) == 0
    error_message = "An empty workload_identity_providers map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no providers are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
