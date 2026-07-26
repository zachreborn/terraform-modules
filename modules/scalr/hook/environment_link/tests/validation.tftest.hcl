# Native OpenTofu tests for modules/scalr/hook/environment_link (variable validation)
#
# Run offline with:
#   tofu -chdir=modules/scalr/hook/environment_link init -backend=false
#   tofu -chdir=modules/scalr/hook/environment_link test

mock_provider "scalr" {
  mock_resource "scalr_environment_hook" {
    defaults = {
      id = "hkenv-xxxxxxxxxx"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    environment_hooks = {
      notify_prod = {
        hook_id        = "hook-xxxxxxxxxx"
        environment_id = "env-xxxxxxxxxx"
        events         = ["pre-apply", "post-apply"]
      }
    }
  }

  assert {
    condition     = length(scalr_environment_hook.this) == 1
    error_message = "Expected exactly one environment hook link to be planned."
  }
}

run "valid_baseline_wildcard_events_does_not_fail" {
  command = plan

  variables {
    environment_hooks = {
      notify_prod = {
        hook_id        = "hook-xxxxxxxxxx"
        environment_id = "env-xxxxxxxxxx"
        events         = ["*"]
      }
    }
  }

  assert {
    condition     = output.ids["notify_prod"] != null
    error_message = "ids output should contain the 'notify_prod' key for a wildcard-events entry."
  }
}

run "rejects_entry_with_empty_events" {
  command = plan

  variables {
    environment_hooks = {
      notify_prod = {
        hook_id        = "hook-xxxxxxxxxx"
        environment_id = "env-xxxxxxxxxx"
        events         = []
      }
    }
  }

  expect_failures = [var.environment_hooks]
}

run "rejects_entry_with_invalid_event" {
  command = plan

  variables {
    environment_hooks = {
      notify_prod = {
        hook_id        = "hook-xxxxxxxxxx"
        environment_id = "env-xxxxxxxxxx"
        events         = ["pre-apply", "not-a-real-event"]
      }
    }
  }

  expect_failures = [var.environment_hooks]
}

run "rejects_entry_mixing_wildcard_with_other_events" {
  command = plan

  variables {
    environment_hooks = {
      notify_prod = {
        hook_id        = "hook-xxxxxxxxxx"
        environment_id = "env-xxxxxxxxxx"
        events         = ["*", "pre-apply"]
      }
    }
  }

  expect_failures = [var.environment_hooks]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong — find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
