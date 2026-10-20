# Validation tests for modules/scalr/workspace/remote_state_consumer
#
# One `run` block per way each `validation {}` block in variables.tf can fail, plus a valid baseline.

mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      app_reads_network_state = {
        workspace_id = "ws-xxxxxxxxxx"
        consumer_id  = "ws-yyyyyyyyyy"
      }
    }
  }

  assert {
    condition     = length(scalr_workspace_remote_state_consumer.this) == 1
    error_message = "Expected exactly one remote state consumer to be planned."
  }
}

###########################################################
# A workspace cannot consume its own state
###########################################################

run "rejects_workspace_consuming_its_own_state" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      self_reference = {
        workspace_id = "ws-xxxxxxxxxx"
        consumer_id  = "ws-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.workspace_remote_state_consumers]
}

run "rejects_self_reference_hidden_among_valid_entries" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      valid_entry = {
        workspace_id = "ws-aaaaaaaaaa"
        consumer_id  = "ws-bbbbbbbbbb"
      }
      self_reference = {
        workspace_id = "ws-cccccccccc"
        consumer_id  = "ws-cccccccccc"
      }
    }
  }

  expect_failures = [var.workspace_remote_state_consumers]
}

###########################################################
# IDs must not be blank (mirrors the provider's own check)
###########################################################

run "rejects_empty_workspace_id" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      broken = {
        workspace_id = ""
        consumer_id  = "ws-yyyyyyyyyy"
      }
    }
  }

  expect_failures = [var.workspace_remote_state_consumers]
}

run "rejects_whitespace_only_consumer_id" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      broken = {
        workspace_id = "ws-xxxxxxxxxx"
        consumer_id  = "   "
      }
    }
  }

  expect_failures = [var.workspace_remote_state_consumers]
}

###########################################################
# Null IDs are rejected with the module's own message, not a raw function error
###########################################################

run "rejects_null_workspace_id" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      broken = {
        workspace_id = null
        consumer_id  = "ws-yyyyyyyyyy"
      }
    }
  }

  expect_failures = [var.workspace_remote_state_consumers]
}

run "rejects_null_consumer_id" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      broken = {
        workspace_id = "ws-xxxxxxxxxx"
        consumer_id  = null
      }
    }
  }

  expect_failures = [var.workspace_remote_state_consumers]
}

run "rejects_null_ids_in_several_entries_next_to_a_valid_one" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      valid_entry = {
        workspace_id = "ws-aaaaaaaaaa"
        consumer_id  = "ws-bbbbbbbbbb"
      }
      null_source_one = {
        workspace_id = null
        consumer_id  = "ws-cccccccccc"
      }
      null_source_two = {
        workspace_id = null
        consumer_id  = "ws-cccccccccc"
      }
    }
  }

  expect_failures = [var.workspace_remote_state_consumers]
}

###########################################################
# The same workspace_id/consumer_id pair must not be listed twice
###########################################################

run "rejects_duplicate_workspace_consumer_pair_under_different_keys" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      first = {
        workspace_id = "ws-xxxxxxxxxx"
        consumer_id  = "ws-yyyyyyyyyy"
      }
      second = {
        workspace_id = "ws-xxxxxxxxxx"
        consumer_id  = "ws-yyyyyyyyyy"
      }
    }
  }

  expect_failures = [var.workspace_remote_state_consumers]
}

run "accepts_reversed_pair_because_it_is_a_different_grant" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      a_reads_b = {
        workspace_id = "ws-aaaaaaaaaa"
        consumer_id  = "ws-bbbbbbbbbb"
      }
      b_reads_a = {
        workspace_id = "ws-bbbbbbbbbb"
        consumer_id  = "ws-aaaaaaaaaa"
      }
    }
  }

  assert {
    condition     = length(scalr_workspace_remote_state_consumer.this) == 2
    error_message = "A->B and B->A are distinct grants and must both be accepted."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
