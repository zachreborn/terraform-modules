mock_provider "scalr" {
  mock_resource "scalr_environment" {
    defaults = {
      id            = "env-mock00000000"
      status        = "Active"
      policy_groups = []
      created_by = [
        {
          email     = "creator@example.com"
          full_name = "Creator Name"
          username  = "creator"
        }
      ]
    }
  }
}

run "plan_succeeds_with_no_environments" {
  command = plan

  variables {
    environments = {}
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "An empty environments map should plan with zero environment resources."
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    environments = {
      production = {
        account_id                      = "acc-xxxxxxxxxx"
        default_provider_configurations = ["pcfg-xxxxxxxxxx"]
      }
      staging = {
        name       = "staging-env"
        account_id = "acc-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(output.ids) == 2
    error_message = "Expected exactly two environments to be planned."
  }

  assert {
    condition     = contains(keys(output.ids), "production") && contains(keys(output.ids), "staging")
    error_message = "Expected the ids output to be keyed by 'production' and 'staging'."
  }

  assert {
    condition     = scalr_environment.this["production"].name == "production"
    error_message = "An entry with no explicit name should default to its map key."
  }

  assert {
    condition     = scalr_environment.this["staging"].name == "staging-env"
    error_message = "An entry with an explicit name should use that name rather than its map key."
  }

  assert {
    condition     = scalr_environment.this["production"].mask_sensitive_output == true
    error_message = "mask_sensitive_output should default to true."
  }

  assert {
    condition     = scalr_environment.this["production"].remote_backend == true
    error_message = "remote_backend should default to true."
  }

  assert {
    condition     = scalr_environment.this["production"].remote_backend_overridable == false
    error_message = "remote_backend_overridable should default to false."
  }

  assert {
    condition     = output.status["production"] == "Active"
    error_message = "Expected the mocked status attribute to be surfaced via the status output."
  }

  assert {
    condition     = output.created_by["production"][0].username == "creator"
    error_message = "Expected the mocked created_by attribute to be surfaced via the created_by output."
  }

  assert {
    condition     = length(output.policy_groups["production"]) == 0
    error_message = "Expected the policy_groups output to surface the mocked empty list exactly."
  }
}

run "plan_succeeds_with_module_level_account_id_fallback" {
  command = plan

  variables {
    account_id = "acc-yyyyyyyyyy"
    environments = {
      shared = {}
    }
  }

  assert {
    condition     = scalr_environment.this["shared"].account_id == "acc-yyyyyyyyyy"
    error_message = "An entry with no explicit account_id should fall back to var.account_id."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
