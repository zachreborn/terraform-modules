mock_provider "scalr" {
  mock_resource "scalr_service_account_token" {
    defaults = {
      id = "sat-abcd1234"
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      token = "mock-token-value"
    }
  }
}

run "plan_succeeds_with_no_tokens" {
  command = plan

  variables {
    tokens = {}
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "An empty tokens map should plan with zero token resources."
  }
}

run "plan_succeeds_with_literal_service_account_id" {
  command = plan

  variables {
    tokens = {
      default = {
        service_account_id = "sa-xxxxxxxxxx"
        description        = "Some description"
      }
    }
  }

  assert {
    condition     = output.ids["default"] != null
    error_message = "Expected the default token to be planned and expose an id output."
  }

  assert {
    condition     = output.tokens["default"] == "mock-token-value"
    error_message = "Expected the mocked sensitive token value to be surfaced via the tokens output."
  }

  assert {
    condition     = scalr_service_account_token.this["default"].service_account_id == "sa-xxxxxxxxxx"
    error_message = "A literal service_account_id should pass through unresolved."
  }
}

run "plan_succeeds_with_service_account_key_resolution" {
  command = plan

  variables {
    tokens = {
      default = {
        service_account_key = "ci"
        expires_in          = 60
        name                = "ci-token"
      }
    }
    service_account_ids = {
      ci = "sa-yyyyyyyyyy"
    }
  }

  assert {
    condition     = scalr_service_account_token.this["default"].service_account_id == "sa-yyyyyyyyyy"
    error_message = "service_account_key should resolve against var.service_account_ids."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
