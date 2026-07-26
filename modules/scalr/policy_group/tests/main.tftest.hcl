mock_provider "scalr" {
  mock_resource "scalr_policy_group" {
    defaults = {
      id            = "pgrp-xxxxxxxxxx"
      status        = "active"
      error_message = null
      policies = [
        {
          name           = "example-policy"
          enabled        = true
          enforced_level = "hard-mandatory"
        }
      ]
    }
  }

  mock_resource "scalr_policy_group_linkage" {
    defaults = {
      id = "pgrp-xxxxxxxxxxxxxxx/env-yyyyyyyyyyyyyyy"
    }
  }
}

run "valid_baseline_plans_a_single_policy_group" {
  command = plan

  variables {
    policy_groups = {
      instance_types = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
  }

  assert {
    condition     = length(scalr_policy_group.this) == 1
    error_message = "Expected exactly one policy group to be planned."
  }

  assert {
    condition     = output.ids["instance_types"] != null
    error_message = "Expected the ids output to contain the instance_types policy group."
  }

  assert {
    condition     = output.statuses["instance_types"] == "active"
    error_message = "Expected the statuses output to reflect the mocked status."
  }

  assert {
    condition     = length(output.policies["instance_types"]) == 1
    error_message = "Expected the policies output to reflect the mocked policies list."
  }

  assert {
    condition     = length(output.linkage_ids) == 0
    error_message = "Expected no linkages when policy_group_linkages is not set."
  }
}

run "full_kitchen_sink_entry_plans_successfully" {
  command = plan

  variables {
    policy_groups = {
      instance_types = {
        name                    = "custom-name"
        account_id              = "acc-xxxxxxxxxx"
        vcs_provider_id         = "vcs-xxxxxxxxxx"
        opa_version             = "0.29.4"
        common_functions_folder = "policies/common"
        environments            = ["*"]
        vcs_repo = {
          identifier = "my-org/policies"
          branch     = "main"
          path       = "policies/instance"
        }
      }
    }
  }

  assert {
    condition     = scalr_policy_group.this["instance_types"].name == "custom-name"
    error_message = "Expected the explicit name to override the map key."
  }
}

run "policy_group_linkages_conditional_branch_creates_linkage" {
  command = plan

  variables {
    policy_groups = {
      instance_types = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
    policy_group_linkages = {
      instance_types_prod = {
        policy_group_key = "instance_types"
        environment_id   = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(output.linkage_ids) == 1
    error_message = "Expected one linkage to be planned when policy_group_linkages has one entry."
  }
}
