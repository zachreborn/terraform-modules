mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
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
}

run "rejects_policy_groups_entry_with_empty_resolved_name" {
  command = plan

  variables {
    policy_groups = {
      "" = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
  }

  expect_failures = [var.policy_groups]
}

run "rejects_policy_groups_entry_with_empty_vcs_repo_identifier" {
  command = plan

  variables {
    policy_groups = {
      instance_types = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = ""
        }
      }
    }
  }

  expect_failures = [var.policy_groups]
}

run "rejects_policy_group_linkages_entry_with_both_key_and_id" {
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
        policy_group_id  = "pgrp-xxxxxxxxxx"
        environment_id   = "env-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.policy_group_linkages]
}

run "rejects_policy_group_linkages_entry_with_neither_key_nor_id" {
  command = plan

  variables {
    policy_group_linkages = {
      instance_types_prod = {
        environment_id = "env-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.policy_group_linkages]
}

run "rejects_policy_group_linkages_entry_with_unknown_key" {
  command = plan

  variables {
    policy_group_linkages = {
      instance_types_prod = {
        policy_group_key = "does_not_exist"
        environment_id   = "env-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.policy_group_linkages]
}
