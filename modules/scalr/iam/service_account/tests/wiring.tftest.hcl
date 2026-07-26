mock_provider "scalr" {
  mock_resource "scalr_service_account" {
    defaults = {
      id    = "sa-abcd1234"
      email = "sa-abcd1234@scalr-service-accounts.io"
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

# Note: the "rejects entry with both/neither service_account_id and service_account_key" failure
# cases are exercised by modules/scalr/iam/service_account/token/tests/validation.tftest.hcl and
# modules/scalr/iam/service_account/assume_policy/tests/validation.tftest.hcl. They aren't
# re-tested here since that failure happens inside the nested submodules' own variable validation,
# following the same precedent as modules/aws/organizations/tests/wiring.tftest.hcl.
run "token_wiring_uses_internal_service_account_ids" {
  command = plan

  variables {
    account_id = "acc-xxxxxxxxxx"
    service_accounts = {
      ci = {
        description = "CI/CD pipeline"
      }
    }
    tokens = {
      default = {
        service_account_key = "ci"
        description         = "Some description"
      }
    }
  }

  assert {
    condition     = output.token_ids["default"] != null
    error_message = "tokens entry should resolve service_account_key against this module's own service_accounts output."
  }

  # Prove the wrapper actually passed scalr_service_account.this["ci"].id through as
  # service_account_ids -- not just that some entry landed under the expected key. "sa-abcd1234" is
  # the mocked scalr_service_account id above; a wrong or unresolved service_account_id would fail
  # this even though the != null check above would still pass.
  assert {
    condition     = output.token_service_account_ids["default"] == "sa-abcd1234"
    error_message = "service_account_key \"ci\" should resolve to the service account created by this same module call's service_accounts input, via scalr_service_account.this."
  }
}

run "token_accepts_external_service_account_id" {
  command = plan

  variables {
    tokens = {
      external = {
        service_account_id = "sa-external0000"
      }
    }
  }

  assert {
    condition     = output.token_ids["external"] != null
    error_message = "A tokens entry with a literal service_account_id (no corresponding var.service_accounts entry) should plan successfully."
  }
}

run "assume_policy_wiring_uses_internal_service_account_ids" {
  command = plan

  variables {
    account_id = "acc-xxxxxxxxxx"
    service_accounts = {
      staging = {
        description = "Staging service account"
      }
    }
    assume_policies = {
      ga_scalr_staging = {
        name                = "ga-scalr-staging"
        service_account_key = "staging"
        provider_id         = "wip-xxxxxxxxxx"
        claim_conditions = [
          {
            claim = "sub"
            value = "repo:GithubOrganization/repository:environment:staging"
          }
        ]
      }
    }
  }

  assert {
    condition     = output.assume_policy_ids["ga_scalr_staging"] != null
    error_message = "assume_policies entry should resolve service_account_key against this module's own service_accounts output."
  }

  # Prove the wrapper actually passed scalr_service_account.this["staging"].id through as
  # service_account_ids -- not just that some entry landed under the expected key.
  assert {
    condition     = output.assume_policy_service_account_ids["ga_scalr_staging"] == "sa-abcd1234"
    error_message = "service_account_key \"staging\" should resolve to the service account created by this same module call's service_accounts input, via scalr_service_account.this."
  }
}

run "assume_policy_accepts_external_service_account_id" {
  command = plan

  variables {
    assume_policies = {
      external = {
        service_account_id = "sa-external0000"
        provider_id        = "wip-xxxxxxxxxx"
        claim_conditions = [
          {
            claim = "sub"
            value = "repo:GithubOrganization/repository"
          }
        ]
      }
    }
  }

  assert {
    condition     = output.assume_policy_ids["external"] != null
    error_message = "An assume_policies entry with a literal service_account_id (no corresponding var.service_accounts entry) should plan successfully."
  }
}

run "full_kitchen_sink_example_plans_successfully" {
  command = plan

  variables {
    account_id = "acc-xxxxxxxxxx"
    service_accounts = {
      ci = {
        description = "CI/CD pipeline"
        status      = "Active"
      }
      staging = {
        description = "Staging deployments"
      }
    }
    tokens = {
      ci_token = {
        service_account_key = "ci"
        expires_in          = 1440
      }
    }
    assume_policies = {
      ga_scalr_staging = {
        service_account_key = "staging"
        provider_id         = "wip-xxxxxxxxxx"
        claim_conditions = [
          {
            claim    = "sub"
            value    = "repo:GithubOrganization/repository:environment:staging"
            operator = "startswith"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(output.ids) == 2
    error_message = "Expected 2 service accounts to be planned."
  }

  assert {
    condition     = length(output.token_ids) == 1
    error_message = "Expected 1 token to be planned."
  }

  assert {
    condition     = length(output.assume_policy_ids) == 1
    error_message = "Expected 1 assume policy to be planned."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
