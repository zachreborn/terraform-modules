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

run "rejects_provider_without_matching_token" {
  command = plan

  variables {
    vcs_providers = {
      github_main = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "github"
      }
    }
    # Intentionally omit the token for "github_main" so the resource precondition fires with a clear,
    # actionable message instead of a cryptic "Invalid index" error.
    vcs_provider_tokens = {}
  }

  expect_failures = [scalr_vcs_provider.this]
}
