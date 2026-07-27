mock_provider "scalr" {
  mock_resource "scalr_vcs_provider" {
    defaults = {
      id = "vcs-mock00000000"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    vcs_providers = {
      github_main = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "github"
      }
    }
    vcs_provider_tokens = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      github_main = "my-github-token"
    }
  }

  assert {
    condition     = length(scalr_vcs_provider.this) == 1
    error_message = "Expected exactly one VCS provider to be planned."
  }
}

run "rejects_entry_with_invalid_vcs_type" {
  command = plan

  variables {
    vcs_providers = {
      broken = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "not_a_real_type"
      }
    }
    vcs_provider_tokens = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      broken = "my-token"
    }
  }

  expect_failures = [var.vcs_providers]
}
