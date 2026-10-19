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
# time_window (provider v3.20.0): unset and every allowed window
###########################################################

run "time_window_is_unset_by_default" {
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
    condition     = scalr_drift_detection.this["prod_weekly"].time_window == null
    error_message = "time_window should stay null when omitted so checks are not bound to a window."
  }
}

run "every_allowed_time_window_is_wired_through" {
  command = plan

  variables {
    drift_detections = {
      w0000 = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "daily"
        time_window    = "00:00-04:00"
      }
      w0400 = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "daily"
        time_window    = "04:00-08:00"
      }
      w0800 = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "daily"
        time_window    = "08:00-12:00"
      }
      w1200 = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "daily"
        time_window    = "12:00-16:00"
      }
      w1600 = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "daily"
        time_window    = "16:00-20:00"
      }
      w2000 = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "daily"
        time_window    = "20:00-24:00"
      }
    }
  }

  assert {
    condition     = length(scalr_drift_detection.this) == 6
    error_message = "Expected one drift detection scheduler per allowed time window."
  }

  assert {
    condition     = scalr_drift_detection.this["w0000"].time_window == "00:00-04:00"
    error_message = "time_window 00:00-04:00 should be forwarded to the resource."
  }

  assert {
    condition     = scalr_drift_detection.this["w0400"].time_window == "04:00-08:00"
    error_message = "time_window 04:00-08:00 should be forwarded to the resource."
  }

  assert {
    condition     = scalr_drift_detection.this["w0800"].time_window == "08:00-12:00"
    error_message = "time_window 08:00-12:00 should be forwarded to the resource."
  }

  assert {
    condition     = scalr_drift_detection.this["w1200"].time_window == "12:00-16:00"
    error_message = "time_window 12:00-16:00 should be forwarded to the resource."
  }

  assert {
    condition     = scalr_drift_detection.this["w1600"].time_window == "16:00-20:00"
    error_message = "time_window 16:00-20:00 should be forwarded to the resource."
  }

  assert {
    condition     = scalr_drift_detection.this["w2000"].time_window == "20:00-24:00"
    error_message = "time_window 20:00-24:00 should be forwarded to the resource."
  }
}

run "time_window_combines_with_run_mode_and_workspace_filters" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        run_mode       = "plan"
        time_window    = "00:00-04:00"
        workspace_filters = {
          name_patterns = ["prod", "stage-*"]
        }
      }
    }
  }

  assert {
    condition     = scalr_drift_detection.this["prod_weekly"].time_window == "00:00-04:00"
    error_message = "time_window should be forwarded alongside run_mode and workspace_filters."
  }

  assert {
    condition     = scalr_drift_detection.this["prod_weekly"].run_mode == "plan"
    error_message = "run_mode should still be forwarded when time_window is set."
  }

  assert {
    condition     = scalr_drift_detection.this["prod_weekly"].workspace_filters.name_patterns != null
    error_message = "workspace_filters should still render when time_window is set."
  }
}

# A non-empty map where only some entries set time_window exercises both sides of the validation's null
# handling. Terraform evaluates every operand of `||`, so the validation uses a conditional; this proves the
# omitted-field path stays valid next to entries that do set it.
run "time_window_may_be_set_on_some_entries_and_omitted_on_others" {
  command = plan

  variables {
    drift_detections = {
      with_window = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "daily"
        time_window    = "04:00-08:00"
      }
      without_window = {
        environment_id = "env-yyyyyyyyyy"
        check_period   = "weekly"
      }
    }
  }

  assert {
    condition     = length(scalr_drift_detection.this) == 2
    error_message = "Both the entry that sets time_window and the entry that omits it should plan."
  }

  assert {
    condition     = scalr_drift_detection.this["with_window"].time_window == "04:00-08:00"
    error_message = "The entry that sets time_window should keep its value."
  }

  assert {
    condition     = scalr_drift_detection.this["without_window"].time_window == null
    error_message = "The entry that omits time_window should leave it null."
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

run "rejects_time_window_that_is_not_one_of_the_six_utc_windows" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        time_window    = "01:00-05:00"
      }
    }
  }

  expect_failures = [var.drift_detections]
}

run "rejects_time_window_spanning_more_than_one_window" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        time_window    = "00:00-08:00"
      }
    }
  }

  expect_failures = [var.drift_detections]
}

run "rejects_time_window_with_midnight_written_as_00_00_end" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        time_window    = "20:00-00:00"
      }
    }
  }

  expect_failures = [var.drift_detections]
}

run "rejects_time_window_with_spaces_around_the_dash" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        time_window    = "00:00 - 04:00"
      }
    }
  }

  expect_failures = [var.drift_detections]
}

run "rejects_empty_time_window" {
  command = plan

  variables {
    drift_detections = {
      prod_weekly = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        time_window    = ""
      }
    }
  }

  expect_failures = [var.drift_detections]
}

run "rejects_invalid_time_window_when_other_entries_are_valid" {
  command = plan

  variables {
    drift_detections = {
      fine = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        time_window    = "04:00-08:00"
      }
      broken = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
        time_window    = "25:00-26:00"
      }
    }
  }

  expect_failures = [var.drift_detections]
}

run "rejects_invalid_time_window_when_other_entries_omit_it" {
  command = plan

  variables {
    drift_detections = {
      omits = {
        environment_id = "env-xxxxxxxxxx"
        check_period   = "weekly"
      }
      broken = {
        environment_id = "env-yyyyyyyyyy"
        check_period   = "weekly"
        time_window    = "25:00-26:00"
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
