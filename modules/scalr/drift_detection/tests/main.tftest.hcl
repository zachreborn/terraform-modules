# Native OpenTofu tests for modules/scalr/drift_detection
#
# Run offline with:
#   tofu -chdir=modules/scalr/drift_detection init -backend=false
#   tofu -chdir=modules/scalr/drift_detection test

mock_provider "scalr" {
  mock_resource "scalr_drift_detection" {
    defaults = {
      id = "dds-xxxxxxxxxx"
    }
  }
}

###########################################################
# Valid baseline: no workspace_filters
###########################################################

run "valid_baseline_plans" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
      }
    }
  }

  assert {
    condition     = length(scalr_drift_detection.this) == 1
    error_message = "Expected exactly one drift detection scheduler to be planned."
  }

  assert {
    condition     = output.ids["prod_weekly"] != null
    error_message = "ids output should contain the 'prod_weekly' key."
  }

  assert {
    condition     = scalr_drift_detection.this["prod_weekly"].run_mode == "refresh-only"
    error_message = "run_mode should default to 'refresh-only' when omitted."
  }
}

###########################################################
# Conditional branch coverage: workspace_filters present/absent
###########################################################

run "plan_succeeds_with_name_patterns_filter" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        run_mode       = "plan"
        workspace_filters = {
          name_patterns = ["prod", "stage-*"]
        }
      }
    }
  }

  assert {
    condition     = scalr_drift_detection.this["prod_weekly"].workspace_filters.name_patterns != null
    error_message = "workspace_filters.name_patterns should be set when provided."
  }
}

run "plan_succeeds_with_environment_types_filter" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "daily"
        workspace_filters = {
          environment_types = ["production", "staging"]
        }
      }
    }
  }

  assert {
    condition     = scalr_drift_detection.this["prod_weekly"].workspace_filters.environment_types != null
    error_message = "workspace_filters.environment_types should be set when provided."
  }
}

run "plan_succeeds_with_tags_filter" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "daily"
        workspace_filters = {
          tags = ["critical"]
        }
      }
    }
  }

  assert {
    condition     = scalr_drift_detection.this["prod_weekly"].workspace_filters.tags != null
    error_message = "workspace_filters.tags should be set when provided."
  }
}

###########################################################
# Validation: expect_failures
###########################################################

run "rejects_invalid_check_period" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "monthly"
      }
    }
  }

  expect_failures = [var.drift_detections]
}

run "rejects_invalid_run_mode" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        run_mode       = "apply"
      }
    }
  }

  expect_failures = [var.drift_detections]
}

run "rejects_multiple_workspace_filter_types" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        workspace_filters = {
          name_patterns = ["prod"]
          tags          = ["critical"]
        }
      }
    }
  }

  expect_failures = [var.drift_detections]
}

run "rejects_invalid_environment_type" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        workspace_filters = {
          environment_types = ["production", "not-a-real-type"]
        }
      }
    }
  }

  expect_failures = [var.drift_detections]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_drift_detections" {
  command = plan

  assert {
    condition     = length(scalr_drift_detection.this) == 0
    error_message = "An empty drift_detections map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no drift detections are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
