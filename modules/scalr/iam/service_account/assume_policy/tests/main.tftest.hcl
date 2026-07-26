mock_provider "scalr" {
  mock_resource "scalr_assume_service_account_policy" {
    defaults = {
      id = "asap-abcd1234"
    }
  }
}

run "plan_succeeds_with_no_assume_policies" {
  command = plan

  variables {
    assume_policies = {}
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "An empty assume_policies map should plan with zero policy resources."
  }
}

run "plan_succeeds_with_literal_service_account_id_and_single_claim_condition" {
  command = plan

  variables {
    assume_policies = {
      ga_scalr_staging = {
        service_account_id       = "sa-xxxxxxxxxx"
        provider_id              = "wip-xxxxxxxxxx"
        maximum_session_duration = 7200
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
    condition     = output.ids["ga_scalr_staging"] != null
    error_message = "Expected the policy to be planned and expose an id output."
  }

  assert {
    condition     = scalr_assume_service_account_policy.this["ga_scalr_staging"].name == "ga_scalr_staging"
    error_message = "An entry with no explicit name should default to its map key."
  }

  assert {
    condition     = length(scalr_assume_service_account_policy.this["ga_scalr_staging"].claim_condition) == 1
    error_message = "Expected exactly one claim_condition block to be planned."
  }
}

run "plan_succeeds_with_service_account_key_resolution_and_claim_conditions" {
  command = plan

  variables {
    assume_policies = {
      ga_scalr_staging = {
        name                = "ga-scalr-staging"
        service_account_key = "staging"
        provider_id         = "wip-xxxxxxxxxx"
        claim_conditions = [
          {
            claim    = "sub"
            value    = "repo:GithubOrganization/repository:environment:staging"
            operator = "startswith"
          },
          {
            claim = "repository"
            value = "GithubOrganization/repository"
          }
        ]
      }
    }
    service_account_ids = {
      staging = "sa-yyyyyyyyyy"
    }
  }

  assert {
    condition     = scalr_assume_service_account_policy.this["ga_scalr_staging"].service_account_id == "sa-yyyyyyyyyy"
    error_message = "service_account_key should resolve against var.service_account_ids."
  }

  assert {
    condition     = length(scalr_assume_service_account_policy.this["ga_scalr_staging"].claim_condition) == 2
    error_message = "Expected both claim_condition blocks to be planned."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
