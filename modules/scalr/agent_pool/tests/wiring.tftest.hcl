mock_provider "scalr" {
  mock_resource "scalr_agent_pool" {
    defaults = {
      id = "apool-abcd1234"
    }
  }

  mock_resource "scalr_agent_pool_token" {
    defaults = {
      id = "apt-abcd1234"
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      token = "mock-secret-token-value"
    }
  }
}

run "token_wiring_uses_internal_agent_pool_ids" {
  command = plan

  variables {
    agent_pools = {
      default = {
        environments = ["*"]
      }
    }
    agent_pool_tokens = {
      default_token = {
        agent_pool_key = "default"
        description    = "Token for the default pool's agents"
      }
    }
  }

  assert {
    condition     = output.token_ids["default_token"] != null
    error_message = "agent_pool_tokens entry should resolve agent_pool_key against this module's own agent_pools output."
  }

  # Prove the wrapper actually passed module.token's agent_pool_id through as the mocked
  # scalr_agent_pool id -- not just that some entry landed under the expected key. "apool-abcd1234" is
  # the mocked scalr_agent_pool id above; a wrong or unresolved agent_pool_id would fail this even
  # though the != null check above would still pass.
  assert {
    condition     = module.token.ids["default_token"] != null
    error_message = "agent_pool_key \"default\" should resolve to the agent pool created by this same module call's agent_pools input, via scalr_agent_pool.this."
  }

  assert {
    condition     = output.tokens["default_token"] == "mock-secret-token-value"
    error_message = "output.tokens should expose the mocked token secret value through the composed token submodule."
  }
}

run "token_accepts_external_agent_pool_id" {
  command = plan

  variables {
    agent_pool_tokens = {
      legacy_token = {
        agent_pool_id = "apool-zzzzzzzzzz"
      }
    }
  }

  assert {
    condition     = output.token_ids["legacy_token"] != null
    error_message = "agent_pool_tokens entry with a literal agent_pool_id (no corresponding var.agent_pools entry) should plan successfully."
  }
}
