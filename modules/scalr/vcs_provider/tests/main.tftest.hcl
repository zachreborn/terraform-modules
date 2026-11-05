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

run "comment_control_flags_are_wired_through" {
  command = plan

  variables {
    vcs_providers = {
      github_comments = {
        account_id                = "acc-xxxxxxxxxx"
        comments_enabled          = true
        pr_merge_comments_enabled = true
      }
    }
    vcs_provider_tokens = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      github_comments = "my-github-token"
    }
  }

  # comments_enabled and pr_merge_comments_enabled both default to null (unset), so setting them to
  # true is a distinct, non-default value that proves each is wired to the correct resource argument.
  assert {
    condition     = scalr_vcs_provider.this["github_comments"].comments_enabled == true
    error_message = "Expected comments_enabled to be wired through to the scalr_vcs_provider resource."
  }

  assert {
    condition     = scalr_vcs_provider.this["github_comments"].pr_merge_comments_enabled == true
    error_message = "Expected pr_merge_comments_enabled to be wired through to the scalr_vcs_provider resource."
  }
}

###########################################################
# azure_dev_ops_services (provider v3.20.0 vcs_type value)
###########################################################

run "azure_dev_ops_services_entry_without_username_plans_successfully" {
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

  assert {
    condition     = length(scalr_vcs_provider.this) == 1
    error_message = "Expected exactly one Azure DevOps VCS provider to be planned."
  }

  assert {
    condition     = scalr_vcs_provider.this["azure_devops"].vcs_type == "azure_dev_ops_services"
    error_message = "Expected vcs_type azure_dev_ops_services to be passed through to the resource."
  }

  assert {
    condition     = scalr_vcs_provider.this["azure_devops"].username == null
    error_message = "username is only required for organization-scoped tokens, so it must stay null when omitted."
  }

  # url is Optional+Computed in the provider schema, so under mock_provider an unset value is a generated
  # string and cannot be asserted null. That the plan succeeds with url omitted is what proves the module
  # does not demand a url for Azure DevOps Services (the hosted offering, unlike the self-hosted types).
  assert {
    condition     = length(scalr_vcs_provider.this) == 1 && scalr_vcs_provider.this["azure_devops"].agent_pool_id == null
    error_message = "An azure_dev_ops_services entry should plan without url or agent_pool_id, and the module must not invent an agent pool."
  }

  assert {
    condition     = scalr_vcs_provider.this["azure_devops"].name == "azure_devops"
    error_message = "Expected name to default to the entry's map key."
  }

  assert {
    # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
    condition     = scalr_vcs_provider.this["azure_devops"].token == "my-azure-devops-token"
    error_message = "Expected the Azure DevOps token to be resolved from vcs_provider_tokens."
  }

  assert {
    condition     = output.ids["azure_devops"] != null
    error_message = "Expected the ids output to contain the azure_devops provider."
  }
}

run "azure_dev_ops_services_organization_scoped_token_username_is_wired_through" {
  command = plan

  variables {
    vcs_providers = {
      azure_devops_org = {
        account_id   = "acc-xxxxxxxxxx"
        name         = "azure-devops-my-organization"
        vcs_type     = "azure_dev_ops_services"
        username     = "my-organization"
        environments = ["env-xxxxxxxxxx"]
      }
    }
    vcs_provider_tokens = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      azure_devops_org = "my-azure-devops-token"
    }
  }

  assert {
    condition     = scalr_vcs_provider.this["azure_devops_org"].username == "my-organization"
    error_message = "Expected the Azure DevOps organization name (username) to be passed through for organization-scoped tokens."
  }

  assert {
    condition     = scalr_vcs_provider.this["azure_devops_org"].name == "azure-devops-my-organization"
    error_message = "Expected the explicit name to be used instead of the map key."
  }

  assert {
    condition     = scalr_vcs_provider.this["azure_devops_org"].environments == toset(["env-xxxxxxxxxx"])
    error_message = "Expected environments scoping to work the same for azure_dev_ops_services as for other VCS types."
  }
}

run "azure_dev_ops_services_can_be_mixed_with_other_vcs_types_in_one_call" {
  command = plan

  variables {
    account_id = "acc-moduledefault0"
    vcs_providers = {
      github_main = {}
      azure_devops = {
        vcs_type = "azure_dev_ops_services"
      }
      bitbucket_main = {
        vcs_type = "bitbucket_enterprise"
        url      = "https://bitbucket.example.com"
        username = "svc-account"
      }
    }
    vcs_provider_tokens = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      github_main    = "my-github-token"
      azure_devops   = "my-azure-devops-token"
      bitbucket_main = "my-bitbucket-token"
    }
  }

  assert {
    condition     = length(scalr_vcs_provider.this) == 3
    error_message = "Expected one VCS provider per entry, including the Azure DevOps one."
  }

  assert {
    condition     = scalr_vcs_provider.this["azure_devops"].account_id == "acc-moduledefault0"
    error_message = "Expected the module-wide account_id fallback to apply to an azure_dev_ops_services entry."
  }

  assert {
    condition = (
      scalr_vcs_provider.this["github_main"].vcs_type == "github"
      && scalr_vcs_provider.this["azure_devops"].vcs_type == "azure_dev_ops_services"
      && scalr_vcs_provider.this["bitbucket_main"].vcs_type == "bitbucket_enterprise"
    )
    error_message = "Each entry should keep its own vcs_type when mixed in a single module call."
  }
}
