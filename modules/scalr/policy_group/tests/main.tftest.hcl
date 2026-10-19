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

###########################################################
# evaluate_on (provider v3.20.0)
###########################################################

run "evaluate_on_pre_plan_is_wired_through" {
  command = plan

  variables {
    policy_groups = {
      early_checks = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "pre-plan"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
  }

  assert {
    condition     = scalr_policy_group.this["early_checks"].evaluate_on == "pre-plan"
    error_message = "evaluate_on = \"pre-plan\" should be forwarded to the resource."
  }

  assert {
    condition     = output.evaluate_on["early_checks"] == "pre-plan"
    error_message = "The evaluate_on output should surface the effective value (pre-plan)."
  }
}

run "evaluate_on_post_plan_is_wired_through" {
  command = plan

  variables {
    policy_groups = {
      late_checks = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "post-plan"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
  }

  assert {
    condition     = scalr_policy_group.this["late_checks"].evaluate_on == "post-plan"
    error_message = "evaluate_on = \"post-plan\" should be forwarded to the resource."
  }

  assert {
    condition     = output.evaluate_on["late_checks"] == "post-plan"
    error_message = "The evaluate_on output should surface the effective value (post-plan)."
  }
}

run "evaluate_on_can_differ_per_policy_group" {
  command = plan

  variables {
    policy_groups = {
      early_checks = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "pre-plan"
        vcs_repo = {
          identifier = "my-org/policies"
          path       = "policies/early"
        }
      }
      late_checks = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "post-plan"
        vcs_repo = {
          identifier = "my-org/policies"
          path       = "policies/late"
        }
      }
    }
  }

  assert {
    condition     = length(output.evaluate_on) == 2
    error_message = "The evaluate_on output should contain one element per policy group."
  }

  assert {
    condition = (
      scalr_policy_group.this["early_checks"].evaluate_on == "pre-plan"
      && scalr_policy_group.this["late_checks"].evaluate_on == "post-plan"
    )
    error_message = "Each policy group should keep its own evaluate_on value."
  }
}

run "evaluate_on_with_linkage_composition_plans_successfully" {
  command = plan

  variables {
    policy_groups = {
      early_checks = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "pre-plan"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
    policy_group_linkages = {
      early_checks_prod = {
        policy_group_key = "early_checks"
        environment_id   = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(output.linkage_ids) == 1 && scalr_policy_group.this["early_checks"].evaluate_on == "pre-plan"
    error_message = "evaluate_on should not interfere with composing the linkage submodule."
  }
}

run "empty_policy_groups_map_plans_no_evaluate_on_output" {
  command = plan

  assert {
    condition     = length(scalr_policy_group.this) == 0 && length(output.evaluate_on) == 0
    error_message = "An empty policy_groups map should plan no policy groups and an empty evaluate_on output."
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
