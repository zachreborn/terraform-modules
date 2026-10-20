# Native OpenTofu tests for modules/scalr/workspace/remote_state_consumer
#
# Run offline with:
#   tofu -chdir=modules/scalr/workspace/remote_state_consumer init -backend=false
#   tofu -chdir=modules/scalr/workspace/remote_state_consumer test

mock_provider "scalr" {
  mock_resource "scalr_workspace_remote_state_consumer" {
    defaults = {
      id = "ws-mocksource00/ws-mockconsumer"
    }
  }
}

###########################################################
# Valid baseline
###########################################################

run "valid_baseline_plans_one_consumer" {
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

  assert {
    condition     = scalr_workspace_remote_state_consumer.this["app_reads_network_state"].workspace_id == "ws-xxxxxxxxxx"
    error_message = "workspace_id should be passed through from var.workspace_remote_state_consumers."
  }

  assert {
    condition     = scalr_workspace_remote_state_consumer.this["app_reads_network_state"].consumer_id == "ws-yyyyyyyyyy"
    error_message = "consumer_id should be passed through from var.workspace_remote_state_consumers."
  }

  assert {
    condition     = output.ids["app_reads_network_state"] == "ws-mocksource00/ws-mockconsumer"
    error_message = "output.ids should expose the mocked resource ID for each entry."
  }

  assert {
    condition     = output.links["app_reads_network_state"].workspace_id == "ws-xxxxxxxxxx"
    error_message = "output.links should expose the resolved workspace_id for each entry."
  }

  assert {
    condition     = output.links["app_reads_network_state"].consumer_id == "ws-yyyyyyyyyy"
    error_message = "output.links should expose the resolved consumer_id for each entry."
  }

  assert {
    condition     = output.links["app_reads_network_state"].id == "ws-mocksource00/ws-mockconsumer"
    error_message = "output.links should expose the resource ID for each entry."
  }
}

###########################################################
# for_each branch coverage: several consumers, one source
###########################################################

run "one_source_workspace_with_multiple_consumers_plans_one_resource_per_entry" {
  command = plan

  variables {
    workspace_remote_state_consumers = {
      app_reads_network = {
        workspace_id = "ws-network0000"
        consumer_id  = "ws-app0000000"
      }
      data_reads_network = {
        workspace_id = "ws-network0000"
        consumer_id  = "ws-data000000"
      }
      app_reads_security = {
        workspace_id = "ws-security000"
        consumer_id  = "ws-app0000000"
      }
    }
  }

  assert {
    condition     = length(scalr_workspace_remote_state_consumer.this) == 3
    error_message = "Expected one remote state consumer resource per map entry."
  }

  assert {
    condition = (
      scalr_workspace_remote_state_consumer.this["app_reads_network"].workspace_id == "ws-network0000"
      && scalr_workspace_remote_state_consumer.this["data_reads_network"].workspace_id == "ws-network0000"
    )
    error_message = "Two consumers of the same source workspace should both carry that source workspace_id."
  }

  assert {
    condition = (
      scalr_workspace_remote_state_consumer.this["app_reads_network"].consumer_id == "ws-app0000000"
      && scalr_workspace_remote_state_consumer.this["data_reads_network"].consumer_id == "ws-data000000"
      && scalr_workspace_remote_state_consumer.this["app_reads_security"].consumer_id == "ws-app0000000"
    )
    error_message = "Each entry should keep its own consumer_id; the same consumer may read several source workspaces."
  }

  assert {
    condition     = length(output.ids) == 3 && length(output.links) == 3
    error_message = "ids and links outputs should each contain one element per entry."
  }

  assert {
    condition     = toset(keys(output.ids)) == toset(["app_reads_network", "data_reads_network", "app_reads_security"])
    error_message = "output.ids should be keyed by the caller-chosen logical names."
  }
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_plans_no_consumers" {
  command = plan

  assert {
    condition     = length(scalr_workspace_remote_state_consumer.this) == 0
    error_message = "An unset (default empty) workspace_remote_state_consumers should plan zero consumers."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no consumers are configured."
  }

  assert {
    condition     = length(output.links) == 0
    error_message = "links output should be empty when no consumers are configured."
  }
}

run "explicit_null_input_falls_back_to_the_empty_default" {
  command = plan

  variables {
    workspace_remote_state_consumers = null
  }

  assert {
    condition     = length(scalr_workspace_remote_state_consumer.this) == 0
    error_message = "A null workspace_remote_state_consumers should be treated as the empty default (nullable = false)."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
