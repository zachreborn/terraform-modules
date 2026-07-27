mock_provider "scalr" {
  mock_resource "scalr_vcs_provider" {
    defaults = {
      id = "vcs-mock00000000"
    }
  }
}

run "github_entry_plans_successfully" {
  command = plan

  variables {
    vcs_providers = {
      github_main = {
        account_id = "acc-xxxxxxxxxx"
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

  assert {
    condition     = scalr_vcs_provider.this["github_main"].name == "github_main"
    error_message = "Expected name to default to the entry's map key."
  }

  assert {
    condition     = scalr_vcs_provider.this["github_main"].vcs_type == "github"
    error_message = "Expected vcs_type to default to \"github\"."
  }

  assert {
    condition     = scalr_vcs_provider.this["github_main"].environments == toset(["*"])
    error_message = "Expected environments to default to [\"*\"]."
  }

  assert {
    condition     = scalr_vcs_provider.this["github_main"].draft_pr_runs_enabled == false
    error_message = "Expected draft_pr_runs_enabled to default to false."
  }

  assert {
    # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
    condition     = scalr_vcs_provider.this["github_main"].token == "my-github-token"
    error_message = "Expected the token to be resolved from vcs_provider_tokens."
  }

  assert {
    condition     = output.ids["github_main"] != null
    error_message = "Expected the ids output to contain the github_main provider."
  }
}

run "account_id_falls_back_to_module_wide_default" {
  command = plan

  variables {
    account_id = "acc-moduledefault0"
    vcs_providers = {
      gitlab_self_hosted = {
        name          = "gitlab-self-hosted"
        vcs_type      = "gitlab_enterprise"
        url           = "https://gitlab.example.com"
        agent_pool_id = "apool-xxxxxxxxxx"
      }
    }
    vcs_provider_tokens = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      gitlab_self_hosted = "my-gitlab-token"
    }
  }

  assert {
    condition     = scalr_vcs_provider.this["gitlab_self_hosted"].account_id == "acc-moduledefault0"
    error_message = "Expected account_id to fall back to var.account_id when the entry omits it."
  }

  assert {
    condition     = scalr_vcs_provider.this["gitlab_self_hosted"].name == "gitlab-self-hosted"
    error_message = "Expected the explicit name to be used instead of the map key."
  }

  assert {
    condition     = scalr_vcs_provider.this["gitlab_self_hosted"].url == "https://gitlab.example.com"
    error_message = "Expected url to be passed through for a self-hosted provider."
  }
}

run "entry_level_account_id_overrides_module_wide_default" {
  command = plan

  variables {
    account_id = "acc-moduledefault0"
    vcs_providers = {
      bitbucket_main = {
        account_id = "acc-entryoverride0"
        vcs_type   = "bitbucket_enterprise"
        url        = "https://bitbucket.example.com"
        username   = "svc-account"
      }
    }
    vcs_provider_tokens = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      bitbucket_main = "my-bitbucket-token"
    }
  }

  assert {
    condition     = scalr_vcs_provider.this["bitbucket_main"].account_id == "acc-entryoverride0"
    error_message = "Expected the entry's own account_id to take precedence over var.account_id."
  }

  assert {
    condition     = scalr_vcs_provider.this["bitbucket_main"].username == "svc-account"
    error_message = "Expected username to be passed through for a bitbucket_enterprise provider."
  }
}

run "no_providers_when_map_is_empty" {
  command = plan

  assert {
    condition     = length(output.ids) == 0
    error_message = "Expected no VCS providers to be planned when vcs_providers is empty."
  }
}
