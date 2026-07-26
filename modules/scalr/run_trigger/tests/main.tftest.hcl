# Native OpenTofu tests for modules/scalr/run_trigger
#
# Run offline with:
#   tofu -chdir=modules/scalr/run_trigger init -backend=false
#   tofu -chdir=modules/scalr/run_trigger test

mock_provider "scalr" {
  mock_resource "scalr_run_trigger" {
    defaults = {
      id = "rt-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_plans" {
  command = plan

  variables {
    run_triggers = {
      promote_to_staging = {
        downstream_id = "ws-downstream0"
        upstream_id   = "ws-upstream000"
      }
    }
  }

  assert {
    condition     = length(scalr_run_trigger.this) == 1
    error_message = "Expected exactly one run trigger to be planned."
  }

  assert {
    condition     = output.ids["promote_to_staging"] != null
    error_message = "ids output should contain the 'promote_to_staging' key."
  }

  assert {
    condition     = output.run_triggers["promote_to_staging"].downstream_id == "ws-downstream0"
    error_message = "run_triggers output should expose the downstream_id attribute."
  }
}

run "rejects_entry_with_matching_downstream_and_upstream" {
  command = plan

  variables {
    run_triggers = {
      self_trigger = {
        downstream_id = "ws-samesamesa"
        upstream_id   = "ws-samesamesa"
      }
    }
  }

  expect_failures = [var.run_triggers]
}

run "empty_map_creates_no_run_triggers" {
  command = plan

  assert {
    condition     = length(scalr_run_trigger.this) == 0
    error_message = "An empty run_triggers map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no run triggers are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
