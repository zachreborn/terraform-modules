# Native OpenTofu tests for modules/scalr/integrations/slack
#
# Run offline with:
#   tofu -chdir=modules/scalr/integrations/slack init -backend=false
#   tofu -chdir=modules/scalr/integrations/slack test

mock_provider "scalr" {
  mock_resource "scalr_slack_integration" {
    defaults = {
      id = "in-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_plans" {
  command = plan

  variables {
    account_id = "acc-test0000"
    slack_integrations = {
      run_notifications = {
        name         = "my-channel"
        channel_id   = "C0000000000"
        events       = ["run_approval_required", "run_success", "run_errored", "drift_detected"]
        environments = ["env-xxxxxxxxxx"]
      }
    }
  }

  assert {
    condition     = length(scalr_slack_integration.this) == 1
    error_message = "Expected exactly one Slack integration to be planned."
  }

  assert {
    condition     = output.ids["run_notifications"] != null
    error_message = "ids output should contain the 'run_notifications' key."
  }
}

###########################################################
# Conditional branch coverage: run_mode / workspaces / account_id
###########################################################

run "plan_succeeds_with_run_mode_and_workspaces" {
  command = plan

  variables {
    account_id = "acc-test0000"
    slack_integrations = {
      run_notifications = {
        name         = "my-channel"
        channel_id   = "C0000000000"
        events       = ["run_success"]
        environments = ["env-xxxxxxxxxx"]
        workspaces   = ["ws-xxxxxxxxxx", "ws-yyyyyyyyyy"]
        run_mode     = "apply"
      }
    }
  }

  assert {
    condition     = scalr_slack_integration.this["run_notifications"].run_mode == "apply"
    error_message = "run_mode should be passed through as 'apply'."
  }
}

run "account_id_falls_back_to_module_default" {
  command = plan

  variables {
    account_id = "acc-default000"
    slack_integrations = {
      run_notifications = {
        name         = "my-channel"
        channel_id   = "C0000000000"
        events       = ["run_success"]
        environments = ["env-xxxxxxxxxx"]
      }
    }
  }

  assert {
    condition     = scalr_slack_integration.this["run_notifications"].account_id == "acc-default000"
    error_message = "account_id should fall back to var.account_id when the entry omits its own."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_entry_with_invalid_event" {
  command = plan

  variables {
    account_id = "acc-test0000"
    slack_integrations = {
      run_notifications = {
        name         = "my-channel"
        channel_id   = "C0000000000"
        events       = ["not_a_real_event"]
        environments = ["env-xxxxxxxxxx"]
      }
    }
  }

  expect_failures = [var.slack_integrations]
}

run "rejects_entry_with_empty_events" {
  command = plan

  variables {
    account_id = "acc-test0000"
    slack_integrations = {
      run_notifications = {
        name         = "my-channel"
        channel_id   = "C0000000000"
        events       = []
        environments = ["env-xxxxxxxxxx"]
      }
    }
  }

  expect_failures = [var.slack_integrations]
}

run "rejects_entry_with_invalid_run_mode" {
  command = plan

  variables {
    account_id = "acc-test0000"
    slack_integrations = {
      run_notifications = {
        name         = "my-channel"
        channel_id   = "C0000000000"
        events       = ["run_success"]
        environments = ["env-xxxxxxxxxx"]
        run_mode     = "sometimes"
      }
    }
  }

  expect_failures = [var.slack_integrations]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_integrations" {
  command = plan

  assert {
    condition     = length(scalr_slack_integration.this) == 0
    error_message = "An empty slack_integrations map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no integrations are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
