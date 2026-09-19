mock_provider "scalr" {
  mock_resource "scalr_service_account" {
    defaults = {
      id    = "sa-abcd1234"
      email = "sa-abcd1234@scalr-service-accounts.io"
      created_by = [
        {
          email     = "creator@example.com"
          full_name = "Creator Name"
          username  = "creator"
        }
      ]
    }
  }

  mock_resource "scalr_service_account_token" {
    defaults = {
      id = "sat-abcd1234"
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      token = "mock-token-value"
    }
  }

  mock_resource "scalr_assume_service_account_policy" {
    defaults = {
      id = "asap-abcd1234"
    }
  }
}

run "plan_succeeds_with_no_service_accounts" {
  command = plan

  variables {
    service_accounts = {}
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "An empty service_accounts map should plan with zero service account resources."
  }

  assert {
    condition     = length(output.token_ids) == 0
    error_message = "No tokens should be planned when var.tokens is empty."
  }

  assert {
    condition     = length(output.assume_policy_ids) == 0
    error_message = "No assume policies should be planned when var.assume_policies is empty."
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    account_id = "acc-xxxxxxxxxx"
    service_accounts = {
      ci = {
        description = "CI/CD pipeline"
      }
    }
  }

  assert {
    condition     = output.ids["ci"] != null
    error_message = "Expected the ci service account to be planned and expose an id output."
  }

  assert {
    condition     = output.emails["ci"] != null
    error_message = "Expected the mocked email attribute to be surfaced via the emails output."
  }

  assert {
    condition     = output.created_by["ci"][0].username == "creator"
    error_message = "Expected the mocked created_by attribute to be surfaced via the created_by output."
  }

  assert {
    condition     = scalr_service_account.this["ci"].name == "ci"
    error_message = "An entry with no explicit name should default to its map key."
  }

  assert {
    condition     = scalr_service_account.this["ci"].status == "Active"
    error_message = "status should default to Active."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
