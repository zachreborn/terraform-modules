mock_provider "scalr" {
  mock_resource "scalr_policy_group_linkage" {
    defaults = {
      id = "pgrp-xxxxxxxxxxxxxxx/env-yyyyyyyyyyyyyyy"
    }
  }
}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    linkages = {
      instance_types_prod = {
        policy_group_id = "pgrp-xxxxxxxxxx"
        environment_id  = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_policy_group_linkage.this) == 1
    error_message = "Expected exactly one policy group linkage to be planned."
  }

  assert {
    condition     = output.ids["instance_types_prod"] != null
    error_message = "Expected the ids output to contain the instance_types_prod linkage."
  }
}

run "empty_map_plans_with_no_linkages" {
  command = plan

  variables {
    linkages = {}
  }

  assert {
    condition     = length(scalr_policy_group_linkage.this) == 0
    error_message = "Expected zero policy group linkages to be planned when linkages is empty."
  }
}

run "multiple_linkages_all_plan" {
  command = plan

  variables {
    linkages = {
      a = {
        policy_group_id = "pgrp-aaaaaaaaaa"
        environment_id  = "env-aaaaaaaaaa"
      }
      b = {
        policy_group_id = "pgrp-bbbbbbbbbb"
        environment_id  = "env-bbbbbbbbbb"
      }
    }
  }

  assert {
    condition     = length(output.ids) == 2
    error_message = "Expected two linkages in the ids output."
  }
}
