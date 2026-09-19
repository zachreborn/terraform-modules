mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    assume_policies = {
      ga_scalr_staging = {
        service_account_id = "sa-xxxxxxxxxx"
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
    condition     = length(scalr_assume_service_account_policy.this) == 1
    error_message = "Expected exactly one assume policy to be planned."
  }
}

run "rejects_null_entry" {
  command = plan

  variables {
    assume_policies = {
      ga_scalr_staging = null
    }
  }

  expect_failures = [var.assume_policies]
}

run "rejects_entry_with_both_service_account_id_and_service_account_key" {
  command = plan

  variables {
    assume_policies = {
      ga_scalr_staging = {
        service_account_id  = "sa-xxxxxxxxxx"
        service_account_key = "staging"
        provider_id         = "wip-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.assume_policies]
}

run "rejects_entry_with_neither_service_account_id_nor_service_account_key" {
  command = plan

  variables {
    assume_policies = {
      ga_scalr_staging = {
        provider_id = "wip-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.assume_policies]
}

run "rejects_entry_with_invalid_claim_condition_operator" {
  command = plan

  variables {
    assume_policies = {
      ga_scalr_staging = {
        service_account_id = "sa-xxxxxxxxxx"
        provider_id        = "wip-xxxxxxxxxx"
        claim_conditions = [
          {
            claim    = "sub"
            value    = "repo:GithubOrganization/repository"
            operator = "matches"
          }
        ]
      }
    }
  }

  expect_failures = [var.assume_policies]
}

run "rejects_entry_with_empty_claim_conditions" {
  command = plan

  variables {
    assume_policies = {
      ga_scalr_staging = {
        service_account_id = "sa-xxxxxxxxxx"
        provider_id        = "wip-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.assume_policies]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
