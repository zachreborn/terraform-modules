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

run "accepts_every_supported_vcs_type" {
  command = plan

  variables {
    vcs_providers = {
      github_main = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "github"
      }
      github_ent = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "github_enterprise"
        url        = "https://github.example.com"
      }
      gitlab_main = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "gitlab"
      }
      gitlab_ent = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "gitlab_enterprise"
        url        = "https://gitlab.example.com"
      }
      bitbucket_ent = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "bitbucket_enterprise"
        url        = "https://bitbucket.example.com"
        username   = "svc-account"
      }
      azure_devops = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "azure_dev_ops_services"
      }
    }
    vcs_provider_tokens = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      github_main   = "my-token"
      github_ent    = "my-token"
      gitlab_main   = "my-token"
      gitlab_ent    = "my-token"
      bitbucket_ent = "my-token"
      azure_devops  = "my-token"
    }
  }

  assert {
    condition     = length(scalr_vcs_provider.this) == 6
    error_message = "Every documented vcs_type, including azure_dev_ops_services, should be accepted."
  }
}

run "accepts_azure_dev_ops_services_without_url_username_or_agent_pool" {
  command = plan

  variables {
    vcs_providers = {
      azure_devops = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "azure_dev_ops_services"
      }
    }
    vcs_provider_tokens = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      azure_devops = "my-azure-devops-token"
    }
  }

  # No module-level validation should demand url, username, or agent_pool_id for Azure DevOps Services:
  # it is SaaS-hosted, and username is only needed for organization-scoped tokens.
  assert {
    condition     = length(scalr_vcs_provider.this) == 1
    error_message = "An azure_dev_ops_services entry with only a token must be accepted."
  }
}

run "rejects_azure_dev_ops_services_misspelled_vcs_type" {
  command = plan

  variables {
    vcs_providers = {
      broken = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "azure_devops"
      }
    }
    vcs_provider_tokens = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      broken = "my-token"
    }
  }

  expect_failures = [var.vcs_providers]
}

run "rejects_azure_dev_ops_services_without_matching_token" {
  command = plan

  variables {
    vcs_providers = {
      azure_devops = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "azure_dev_ops_services"
      }
    }
    # The token requirement applies to Azure DevOps too: the precondition must still fire.
    vcs_provider_tokens = {}
  }

  expect_failures = [scalr_vcs_provider.this]
}

run "rejects_azure_dev_ops_services_with_null_token" {
  command = plan

  variables {
    vcs_providers = {
      azure_devops = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "azure_dev_ops_services"
      }
    }
    vcs_provider_tokens = {
      azure_devops = null
    }
  }

  expect_failures = [scalr_vcs_provider.this]
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

run "rejects_provider_with_null_token" {
  command = plan

  variables {
    vcs_providers = {
      github_main = {
        account_id = "acc-xxxxxxxxxx"
        vcs_type   = "github"
      }
    }
    # A present-but-null token (as the composing root can produce when no token is configured) must
    # also fail the precondition, not merely an absent key.
    vcs_provider_tokens = {
      github_main = null
    }
  }

  expect_failures = [scalr_vcs_provider.this]
}
