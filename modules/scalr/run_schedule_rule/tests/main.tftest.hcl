# Native OpenTofu tests for modules/scalr/run_schedule_rule
#
# Run offline with:
#   tofu -chdir=modules/scalr/run_schedule_rule init -backend=false
#   tofu -chdir=modules/scalr/run_schedule_rule test

mock_provider "scalr" {
  mock_resource "scalr_run_schedule_rule" {
    defaults = {
      id = "sr-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_plans" {
  command = plan

  variables {
    run_schedule_rules = {
      nightly_apply = {
        schedule      = "0 4 * * *"
        schedule_mode = "apply"
        workspace_id  = "ws-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_run_schedule_rule.this) == 1
    error_message = "Expected exactly one run schedule rule to be planned."
  }

  assert {
    condition     = output.ids["nightly_apply"] != null
    error_message = "ids output should contain the 'nightly_apply' key."
  }
}

###########################################################
# Conditional branch coverage: each schedule_mode
###########################################################

run "plan_succeeds_with_destroy_mode" {
  command = plan

  variables {
    run_schedule_rules = {
      weekend_teardown = {
        schedule      = "0 20 * * 5"
        schedule_mode = "destroy"
        workspace_id  = "ws-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = scalr_run_schedule_rule.this["weekend_teardown"].schedule_mode == "destroy"
    error_message = "schedule_mode should be passed through as 'destroy'."
  }
}

run "plan_succeeds_with_refresh_mode" {
  command = plan

  variables {
    run_schedule_rules = {
      hourly_refresh = {
        schedule      = "0 * * * *"
        schedule_mode = "refresh"
        workspace_id  = "ws-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = scalr_run_schedule_rule.this["hourly_refresh"].schedule_mode == "refresh"
    error_message = "schedule_mode should be passed through as 'refresh'."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_invalid_schedule_mode" {
  command = plan

  variables {
    run_schedule_rules = {
      nightly_apply = {
        schedule      = "0 4 * * *"
        schedule_mode = "plan"
        workspace_id  = "ws-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.run_schedule_rules]
}

run "rejects_malformed_schedule" {
  command = plan

  variables {
    run_schedule_rules = {
      nightly_apply = {
        schedule      = "not-a-cron-expression"
        schedule_mode = "apply"
        workspace_id  = "ws-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.run_schedule_rules]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_rules" {
  command = plan

  assert {
    condition     = length(scalr_run_schedule_rule.this) == 0
    error_message = "An empty run_schedule_rules map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no rules are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
