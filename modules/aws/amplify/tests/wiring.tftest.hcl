mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_resource "aws_sns_topic" {
    defaults = {
      id  = "arn:aws:sns:us-east-1:123456789012:my-app-amplify-notifications"
      arn = "arn:aws:sns:us-east-1:123456789012:my-app-amplify-notifications"
    }
  }

  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn = "arn:aws:events:us-east-1:123456789012:rule/my-app-amplify-notifications"
    }
  }
}

run "notifications_disabled_creates_no_child_modules" {
  command = plan

  variables {
    name     = "my-app"
    branches = {}
  }

  assert {
    condition     = length(module.amplify_notifications_sns) == 0
    error_message = "Expected no sns child module instance when enable_notifications is false."
  }

  assert {
    condition     = length(module.amplify_notifications_event) == 0
    error_message = "Expected no cloudwatch/event child module instance when enable_notifications is false."
  }
}

run "notifications_enabled_with_create_sns_topic_wires_both_child_modules" {
  command = plan

  variables {
    name                 = "my-app"
    branches             = {}
    enable_notifications = true
    notification_emails  = ["ops@example.com"]
  }

  assert {
    condition     = length(module.amplify_notifications_sns) == 1
    error_message = "Expected the sns child module to be instantiated when create_sns_topic is true (the default)."
  }

  assert {
    condition     = length(module.amplify_notifications_event) == 1
    error_message = "Expected the cloudwatch/event child module to be instantiated when enable_notifications is true."
  }

  assert {
    condition     = module.amplify_notifications_sns[0].topic_name == "my-app-amplify-notifications"
    error_message = "Expected the sns child module to be named '<app_name>-amplify-notifications'."
  }

  assert {
    condition     = output.sns_topic_arn == module.amplify_notifications_sns[0].topic_arn
    error_message = "Expected the module's sns_topic_arn output to reuse the sns child module's topic_arn output."
  }

  assert {
    condition     = output.notification_event_rule_arn == module.amplify_notifications_event[0].arn
    error_message = "Expected the module's notification_event_rule_arn output to reuse the cloudwatch/event child module's arn output."
  }

  assert {
    condition     = module.amplify_notifications_sns[0].subscription_arns["ops@example.com"] != null
    error_message = "Expected notification_emails to be wired into the sns child module's subscriptions map, keyed by email."
  }

  assert {
    condition     = strcontains(module.amplify_notifications_event[0].rule_name, "amplify-notifications")
    error_message = "Expected the cloudwatch event rule name to be derived from the app name."
  }
}

run "notifications_enabled_with_external_topic_bypasses_sns_module_but_still_wires_event_module" {
  command = plan

  variables {
    name                 = "my-app"
    branches             = {}
    enable_notifications = true
    create_sns_topic     = false
    sns_topic_arn        = "arn:aws:sns:us-east-1:123456789012:external-topic"
  }

  assert {
    condition     = length(module.amplify_notifications_sns) == 0
    error_message = "Expected no sns child module instance when create_sns_topic is false."
  }

  assert {
    condition     = length(module.amplify_notifications_event) == 1
    error_message = "Expected the cloudwatch/event child module to still be instantiated using the caller-supplied topic."
  }

  assert {
    condition     = output.sns_topic_arn == "arn:aws:sns:us-east-1:123456789012:external-topic"
    error_message = "Expected sns_topic_arn output to pass through the caller-supplied sns_topic_arn."
  }

  assert {
    condition     = module.amplify_notifications_event[0].target_arn == "arn:aws:sns:us-east-1:123456789012:external-topic"
    error_message = "Expected the EventBridge target to point at the caller-supplied external SNS topic."
  }
}

# NOTE: the SNS topic policy JSON (local.notification_sns_policy) is applied via the
# aws_sns_topic_policy resource *inside* the nested sns child module, and that resource is
# not exposed as a child-module output, so it cannot be asserted on directly from this
# wrapper module's test scope. The account_id/region-derived ARN math that feeds it is
# still exercised indirectly by the runs above (which all plan successfully with
# enable_notifications = true and the mocked aws_caller_identity/aws_region data sources).

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the wiring between this module and its sns / cloudwatch/event child modules
# has a bug, and fix the root cause in main.tf, then re-run `tofu test` until it passes for
# the right reason.
