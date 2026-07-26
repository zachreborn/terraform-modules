# Native OpenTofu tests for modules/scalr/workspace_run_schedule
#
# Run offline with:
#   tofu -chdir=modules/scalr/workspace_run_schedule init -backend=false
#   tofu -chdir=modules/scalr/workspace_run_schedule test

mock_provider "scalr" {
  mock_resource "scalr_workspace_run_schedule" {
    defaults = {
      id = "ws-xxxxxxxxxx"
    }
  }
}

###########################################################
# Valid baseline: both schedules set
###########################################################

run "valid_baseline_plans_with_both_schedules" {
  command = plan

  variables {
    workspace_run_schedules = {
      nightly_refresh = {
        workspace_id     = "ws-xxxxxxxxxx"
        apply_schedule   = "30 3 5 3-5 2"
        destroy_schedule = "30 4 5 3-5 2"
      }
    }
  }

  assert {
    condition     = length(scalr_workspace_run_schedule.this) == 1
    error_message = "Expected exactly one workspace run schedule to be planned."
  }

  assert {
    condition     = output.ids["nightly_refresh"] != null
    error_message = "ids output should contain the 'nightly_refresh' key."
  }
}

###########################################################
# Conditional branch coverage: apply-only, destroy-only
###########################################################

run "plan_succeeds_with_apply_schedule_only" {
  command = plan

  variables {
    workspace_run_schedules = {
      weekday_morning_plan = {
        workspace_id   = "ws-xxxxxxxxxx"
        apply_schedule = "0 8 * * 1-5"
      }
    }
  }

  assert {
    condition     = scalr_workspace_run_schedule.this["weekday_morning_plan"].destroy_schedule == null
    error_message = "destroy_schedule should remain null when omitted from input."
  }
}

run "plan_succeeds_with_destroy_schedule_only" {
  command = plan

  variables {
    workspace_run_schedules = {
      weekend_teardown = {
        workspace_id     = "ws-xxxxxxxxxx"
        destroy_schedule = "0 20 * * 5"
      }
    }
  }

  assert {
    condition     = scalr_workspace_run_schedule.this["weekend_teardown"].apply_schedule == null
    error_message = "apply_schedule should remain null when omitted from input."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_entry_with_neither_schedule" {
  command = plan

  variables {
    workspace_run_schedules = {
      nightly_refresh = {
        workspace_id = "ws-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.workspace_run_schedules]
}

run "rejects_entry_with_malformed_apply_schedule" {
  command = plan

  variables {
    workspace_run_schedules = {
      nightly_refresh = {
        workspace_id   = "ws-xxxxxxxxxx"
        apply_schedule = "not-a-cron-expression"
      }
    }
  }

  expect_failures = [var.workspace_run_schedules]
}

run "rejects_entry_with_malformed_destroy_schedule" {
  command = plan

  variables {
    workspace_run_schedules = {
      nightly_refresh = {
        workspace_id     = "ws-xxxxxxxxxx"
        destroy_schedule = "also-not-a-cron"
      }
    }
  }

  expect_failures = [var.workspace_run_schedules]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_schedules" {
  command = plan

  assert {
    condition     = length(scalr_workspace_run_schedule.this) == 0
    error_message = "An empty workspace_run_schedules map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no schedules are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
