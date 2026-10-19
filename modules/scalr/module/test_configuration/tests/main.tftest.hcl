# Native OpenTofu tests for modules/scalr/module/test_configuration
#
# Run offline with:
#   tofu -chdir=modules/scalr/module/test_configuration init -backend=false
#   tofu -chdir=modules/scalr/module/test_configuration test

mock_provider "scalr" {
  mock_resource "scalr_module_test_configuration" {
    defaults = {
      id = "tc-xxxxxxxxxx"
    }
  }
}

###########################################################
# Valid baseline and defaults
###########################################################

run "valid_baseline_plans_with_provider_defaults" {
  command = plan

  variables {
    module_test_configurations = {
      vpc = {
        module_id = "mod-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_module_test_configuration.this) == 1
    error_message = "Expected exactly one module test configuration to be planned."
  }

  assert {
    condition     = scalr_module_test_configuration.this["vpc"].module_id == "mod-xxxxxxxxxx"
    error_message = "module_id should be passed through unchanged."
  }

  assert {
    condition     = scalr_module_test_configuration.this["vpc"].enabled == true
    error_message = "enabled should default to true (matches the provider default)."
  }

  assert {
    condition     = scalr_module_test_configuration.this["vpc"].failure_behavior == "notify"
    error_message = "failure_behavior should default to 'notify' (matches the provider default)."
  }

  assert {
    condition     = scalr_module_test_configuration.this["vpc"].trigger_on_new_version_enabled == false
    error_message = "trigger_on_new_version_enabled should default to false (matches the provider default)."
  }

  assert {
    condition     = scalr_module_test_configuration.this["vpc"].trigger_on_pr_activity_enabled == false
    error_message = "trigger_on_pr_activity_enabled should default to false (matches the provider default)."
  }

  assert {
    condition     = output.ids["vpc"] == "tc-xxxxxxxxxx"
    error_message = "ids output should expose the (mocked) tc- ID under the logical key."
  }

  assert {
    condition     = output.test_configurations["vpc"].module_id == "mod-xxxxxxxxxx"
    error_message = "test_configurations output should expose the resolved module_id."
  }

  assert {
    condition     = output.test_configurations["vpc"].id == output.ids["vpc"]
    error_message = "test_configurations output id should match the ids output."
  }
}

###########################################################
# Optional-argument branch coverage
###########################################################

run "all_arguments_are_passed_through" {
  command = plan

  variables {
    module_test_configurations = {
      vpc = {
        module_id                      = "mod-xxxxxxxxxx"
        enabled                        = false
        failure_behavior               = "failure"
        trigger_on_new_version_enabled = true
        trigger_on_pr_activity_enabled = true
      }
    }
  }

  assert {
    condition     = scalr_module_test_configuration.this["vpc"].enabled == false
    error_message = "enabled = false should be passed through."
  }

  assert {
    condition     = scalr_module_test_configuration.this["vpc"].failure_behavior == "failure"
    error_message = "failure_behavior = 'failure' should be passed through."
  }

  assert {
    condition     = scalr_module_test_configuration.this["vpc"].trigger_on_new_version_enabled == true
    error_message = "trigger_on_new_version_enabled = true should be passed through."
  }

  assert {
    condition     = scalr_module_test_configuration.this["vpc"].trigger_on_pr_activity_enabled == true
    error_message = "trigger_on_pr_activity_enabled = true should be passed through."
  }

  assert {
    condition     = output.test_configurations["vpc"].enabled == false && output.test_configurations["vpc"].failure_behavior == "failure"
    error_message = "test_configurations output should reflect the non-default settings."
  }

  assert {
    condition     = output.test_configurations["vpc"].trigger_on_new_version_enabled == true && output.test_configurations["vpc"].trigger_on_pr_activity_enabled == true
    error_message = "test_configurations output should reflect both trigger flags."
  }
}

run "failure_behavior_notify_is_accepted_explicitly" {
  command = plan

  variables {
    module_test_configurations = {
      vpc = {
        module_id        = "mod-xxxxxxxxxx"
        failure_behavior = "notify"
      }
    }
  }

  assert {
    condition     = scalr_module_test_configuration.this["vpc"].failure_behavior == "notify"
    error_message = "failure_behavior = 'notify' should be accepted."
  }
}

run "multiple_modules_scale_with_one_call" {
  command = plan

  variables {
    module_test_configurations = {
      vpc = {
        module_id = "mod-aaaaaaaaaa"
      }
      rds = {
        module_id        = "mod-bbbbbbbbbb"
        failure_behavior = "failure"
      }
    }
  }

  assert {
    condition     = length(scalr_module_test_configuration.this) == 2
    error_message = "Expected two module test configurations for two entries."
  }

  assert {
    condition     = length(output.ids) == 2 && contains(keys(output.ids), "vpc") && contains(keys(output.ids), "rds")
    error_message = "ids output should be keyed by the logical names of both entries."
  }

  assert {
    condition     = scalr_module_test_configuration.this["rds"].module_id == "mod-bbbbbbbbbb"
    error_message = "Each entry should keep its own module_id."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_invalid_failure_behavior" {
  command = plan

  variables {
    module_test_configurations = {
      vpc = {
        module_id        = "mod-xxxxxxxxxx"
        failure_behavior = "ignore"
      }
    }
  }

  expect_failures = [var.module_test_configurations]
}

run "rejects_empty_module_id" {
  command = plan

  variables {
    module_test_configurations = {
      vpc = {
        module_id = ""
      }
    }
  }

  expect_failures = [var.module_test_configurations]
}

# An explicit null must fail validation cleanly instead of raising an evaluation error from trimspace(null).
run "rejects_null_module_id" {
  command = plan

  variables {
    module_test_configurations = {
      vpc = {
        module_id = null
      }
    }
  }

  expect_failures = [var.module_test_configurations]
}

run "rejects_whitespace_module_id" {
  command = plan

  variables {
    module_test_configurations = {
      vpc = {
        module_id = "   "
      }
    }
  }

  expect_failures = [var.module_test_configurations]
}

run "rejects_duplicate_module_id_across_entries" {
  command = plan

  variables {
    module_test_configurations = {
      first = {
        module_id = "mod-xxxxxxxxxx"
      }
      second = {
        module_id = "mod-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.module_test_configurations]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_test_configurations" {
  command = plan

  assert {
    condition     = length(scalr_module_test_configuration.this) == 0
    error_message = "An empty module_test_configurations map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no test configurations are configured."
  }

  assert {
    condition     = length(output.test_configurations) == 0
    error_message = "test_configurations output should be empty when no test configurations are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
