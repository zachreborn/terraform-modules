# Native OpenTofu tests for modules/scalr/integrations/event_bridge
#
# Run offline with:
#   tofu -chdir=modules/scalr/integrations/event_bridge init -backend=false
#   tofu -chdir=modules/scalr/integrations/event_bridge test

mock_provider "scalr" {
  mock_resource "scalr_event_bridge_integration" {
    defaults = {
      id                = "in-xxxxxxxxxx"
      event_source_arn  = "arn:aws:events:us-east-1:111267354555:event-source/aws.partner/scalr.com/via-provider-aws-bridge"
      event_source_name = "aws.partner/scalr.com/via-provider-aws-bridge"
    }
  }
}

run "valid_baseline_plans" {
  command = plan

  variables {
    event_bridge_integrations = {
      default = {
        name           = "via-provider-aws-bridge"
        aws_account_id = "111267354555"
        region         = "us-east-1"
      }
    }
  }

  assert {
    condition     = length(scalr_event_bridge_integration.this) == 1
    error_message = "Expected exactly one EventBridge integration to be planned."
  }

  assert {
    condition     = output.ids["default"] != null
    error_message = "ids output should contain the 'default' key."
  }

  assert {
    condition     = output.event_source_arns["default"] != null
    error_message = "event_source_arns output should expose the event_source_arn attribute."
  }

  assert {
    condition     = output.event_source_names["default"] != null
    error_message = "event_source_names output should expose the event_source_name attribute."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_entry_with_malformed_account_id" {
  command = plan

  variables {
    event_bridge_integrations = {
      default = {
        name           = "via-provider-aws-bridge"
        aws_account_id = "not-an-account-id"
        region         = "us-east-1"
      }
    }
  }

  expect_failures = [var.event_bridge_integrations]
}

run "rejects_entry_with_short_account_id" {
  command = plan

  variables {
    event_bridge_integrations = {
      default = {
        name           = "via-provider-aws-bridge"
        aws_account_id = "12345"
        region         = "us-east-1"
      }
    }
  }

  expect_failures = [var.event_bridge_integrations]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_integrations" {
  command = plan

  assert {
    condition     = length(scalr_event_bridge_integration.this) == 0
    error_message = "An empty event_bridge_integrations map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no integrations are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
