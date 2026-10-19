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

run "accepts_evaluate_on_pre_plan_and_post_plan" {
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
      late_checks = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "post-plan"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
      unset = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
  }

  assert {
    condition     = length(scalr_policy_group.this) == 3
    error_message = "pre-plan, post-plan, and unset (null) evaluate_on values should all be accepted."
  }
}

run "rejects_evaluate_on_with_unknown_stage" {
  command = plan

  variables {
    policy_groups = {
      broken = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "during-plan"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
  }

  expect_failures = [var.policy_groups]
}

run "rejects_evaluate_on_with_underscore_instead_of_hyphen" {
  command = plan

  variables {
    policy_groups = {
      broken = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "pre_plan"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
  }

  expect_failures = [var.policy_groups]
}

run "rejects_evaluate_on_with_wrong_case" {
  command = plan

  variables {
    policy_groups = {
      broken = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "Post-Plan"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
  }

  expect_failures = [var.policy_groups]
}

run "rejects_empty_evaluate_on" {
  command = plan

  variables {
    policy_groups = {
      broken = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = ""
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
    }
  }

  expect_failures = [var.policy_groups]
}

run "rejects_invalid_evaluate_on_when_other_entries_are_valid" {
  command = plan

  variables {
    policy_groups = {
      fine = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "pre-plan"
        vcs_repo = {
          identifier = "my-org/policies"
        }
      }
      broken = {
        account_id      = "acc-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        evaluate_on     = "never"
        vcs_repo = {
          identifier = "my-org/policies"
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
