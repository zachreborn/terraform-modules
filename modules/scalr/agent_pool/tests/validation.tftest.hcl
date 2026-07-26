mock_provider "scalr" {
  mock_resource "scalr_agent_pool" {
    defaults = {
      id = "apool-abcd1234"
    }
  }
  mock_resource "scalr_agent_pool_token" {
    defaults = {
      id    = "apt-abcd1234"
      token = "mock-secret-token-value"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    agent_pools = {
      default = {
        environments = ["*"]
        vcs_enabled  = true
      }
    }
  }

  assert {
    condition     = length(scalr_agent_pool.this) == 1
    error_message = "Expected exactly one agent pool to be planned."
  }
}

run "rejects_token_with_both_agent_pool_id_and_agent_pool_key" {
  command = plan

  variables {
    agent_pool_tokens = {
      default_token = {
        agent_pool_id  = "apool-zzzzzzzzzz"
        agent_pool_key = "default"
      }
    }
  }

  expect_failures = [var.agent_pool_tokens]
}

run "rejects_token_with_neither_agent_pool_id_nor_agent_pool_key" {
  command = plan

  variables {
    agent_pool_tokens = {
      default_token = {
        description = "no scope set"
      }
    }
  }

  expect_failures = [var.agent_pool_tokens]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
