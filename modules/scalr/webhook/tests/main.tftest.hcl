# Native OpenTofu tests for modules/scalr/webhook
#
# Run offline with:
#   tofu -chdir=modules/scalr/webhook init -backend=false
#   tofu -chdir=modules/scalr/webhook test

mock_provider "scalr" {
  mock_resource "scalr_webhook" {
    defaults = {
      id                = "wh-xxxxxxxxxx"
      last_triggered_at = "2024-01-01T00:00:00Z"
    }
  }
}

###########################################################
# Valid baseline
###########################################################

run "valid_baseline_plans" {
  command = plan

  variables {
    account_id = "acc-test0000"
    webhooks = {
      run_notifications = {
        name         = "run-notifications"
        url          = "https://my-endpoint.example.com"
        events       = ["run:completed", "run:errored"]
        environments = ["env-xxxxxxxxxx"]
      }
    }
  }

  assert {
    condition     = length(scalr_webhook.this) == 1
    error_message = "Expected exactly one webhook to be planned."
  }

  assert {
    condition     = output.ids["run_notifications"] != null
    error_message = "ids output should contain the 'run_notifications' key."
  }

  assert {
    condition     = output.webhooks["run_notifications"].url == "https://my-endpoint.example.com"
    error_message = "webhooks output should expose the url attribute."
  }
}

###########################################################
# Conditional branch coverage: header block set
###########################################################

run "plan_succeeds_with_headers" {
  command = plan

  variables {
    account_id = "acc-test0000"
    webhooks = {
      run_notifications = {
        name   = "run-notifications"
        url    = "https://my-endpoint.example.com"
        events = ["run:completed"]
        header = [
          { name = "X-Source", value = "scalr" },
          { name = "X-Env", value = "prod" },
        ]
      }
    }
  }

  assert {
    condition     = length(scalr_webhook.this["run_notifications"].header) == 2
    error_message = "Both header blocks should be passed through."
  }
}

run "plan_succeeds_without_headers" {
  command = plan

  variables {
    account_id = "acc-test0000"
    webhooks = {
      run_notifications = {
        name   = "run-notifications"
        url    = "https://my-endpoint.example.com"
        events = ["run:completed"]
      }
    }
  }

  assert {
    condition     = length(scalr_webhook.this["run_notifications"].header) == 0
    error_message = "No header blocks should be set when omitted from input."
  }
}

###########################################################
# secret_key wiring: from webhook_secret_keys, not webhooks
###########################################################

run "secret_key_flows_from_dedicated_variable" {
  command = plan

  variables {
    account_id = "acc-test0000"
    webhooks = {
      run_notifications = {
        name   = "run-notifications"
        url    = "https://my-endpoint.example.com"
        events = ["run:completed"]
      }
    }
    webhook_secret_keys = {
      run_notifications = "super-secret-value"
    }
  }

  assert {
    condition     = scalr_webhook.this["run_notifications"].secret_key == "super-secret-value"
    error_message = "secret_key should resolve from var.webhook_secret_keys via the matching logical name."
  }
}

###########################################################
# account_id fallback
###########################################################

run "account_id_falls_back_to_module_default" {
  command = plan

  variables {
    account_id = "acc-default000"
    webhooks = {
      run_notifications = {
        name   = "run-notifications"
        url    = "https://my-endpoint.example.com"
        events = ["run:completed"]
      }
    }
  }

  assert {
    condition     = scalr_webhook.this["run_notifications"].account_id == "acc-default000"
    error_message = "account_id should fall back to var.account_id when the entry omits its own."
  }
}

run "account_id_entry_override_wins" {
  command = plan

  variables {
    account_id = "acc-default000"
    webhooks = {
      run_notifications = {
        name       = "run-notifications"
        url        = "https://my-endpoint.example.com"
        events     = ["run:completed"]
        account_id = "acc-override00"
      }
    }
  }

  assert {
    condition     = scalr_webhook.this["run_notifications"].account_id == "acc-override00"
    error_message = "An entry's own account_id should take precedence over var.account_id."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_entry_with_empty_events" {
  command = plan

  variables {
    webhooks = {
      run_notifications = {
        name   = "run-notifications"
        url    = "https://my-endpoint.example.com"
        events = []
      }
    }
  }

  expect_failures = [var.webhooks]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_webhooks" {
  command = plan

  assert {
    condition     = length(scalr_webhook.this) == 0
    error_message = "An empty webhooks map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no webhooks are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
