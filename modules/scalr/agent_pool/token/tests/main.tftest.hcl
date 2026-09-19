mock_provider "scalr" {
  mock_resource "scalr_agent_pool_token" {
    defaults = {
      id = "apt-abcd1234"
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      token = "mock-secret-token-value"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    agent_pool_tokens = {
      ci_runner = {
        agent_pool_id = "apool-xxxxxxxxxx"
        description   = "Token for the CI runner fleet"
      }
    }
  }

  assert {
    condition     = length(scalr_agent_pool_token.this) == 1
    error_message = "Expected exactly one agent pool token to be planned."
  }

  assert {
    condition     = scalr_agent_pool_token.this["ci_runner"].agent_pool_id == "apool-xxxxxxxxxx"
    error_message = "agent_pool_id should be passed through from var.agent_pool_tokens."
  }

  assert {
    condition     = output.ids["ci_runner"] != null
    error_message = "output.ids should expose the mocked token resource ID."
  }

  assert {
    condition     = output.tokens["ci_runner"] == "mock-secret-token-value"
    error_message = "output.tokens should expose the mocked token secret value."
  }
}

run "empty_map_plans_with_no_tokens" {
  command = plan

  assert {
    condition     = length(scalr_agent_pool_token.this) == 0
    error_message = "An unset (default empty) agent_pool_tokens should plan zero tokens."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
