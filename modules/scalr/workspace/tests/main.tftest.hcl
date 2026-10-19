mock_provider "scalr" {
  mock_resource "scalr_workspace" {
    defaults = {
      id            = "ws-mock00000000"
      has_resources = false
      created_by = [
        {
          email     = "creator@example.com"
          full_name = "Creator Name"
          username  = "creator"
        }
      ]
    }
  }
}

run "baseline_minimal_workspace_plans_successfully" {
  command = plan

  variables {
    workspaces = {
      minimal = {
        environment_id = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_workspace.this) == 1
    error_message = "Expected exactly one workspace to be planned."
  }

  assert {
    condition     = output.ids["minimal"] == "ws-mock00000000"
    error_message = "Expected the ids output to surface the mocked workspace ID for the minimal workspace."
  }

  assert {
    condition     = output.has_resources["minimal"] == false
    error_message = "Expected the has_resources output to surface the mocked value (false) for the minimal workspace."
  }

  assert {
    condition     = output.created_by["minimal"][0].username == "creator"
    error_message = "Expected the created_by output to surface the mocked creator username for the minimal workspace."
  }

  assert {
    condition     = scalr_workspace.this["minimal"].name == "minimal"
    error_message = "Expected the workspace name to default to the entry's map key."
  }
}

run "workspace_with_two_provider_configurations_plans_successfully" {
  command = plan

  variables {
    workspaces = {
      multi_provider = {
        environment_id = "env-xxxxxxxxxx"
        provider_configuration = [
          { id = "pcfg-aaaaaaaaaa", alias = "us_east1" },
          { id = "pcfg-bbbbbbbbbb", alias = "us_east2" },
        ]
      }
    }
  }

  assert {
    condition     = length(scalr_workspace.this["multi_provider"].provider_configuration) == 2
    error_message = "Expected two provider_configuration blocks to be planned."
  }
}

run "workspace_without_provider_configuration_renders_no_blocks" {
  command = plan

  variables {
    workspaces = {
      no_provider = {
        environment_id = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_workspace.this["no_provider"].provider_configuration) == 0
    error_message = "Expected zero provider_configuration blocks when provider_configuration is omitted."
  }
}

run "workspace_with_vcs_repo_hooks_and_terragrunt_plans_successfully" {
  command = plan

  variables {
    workspaces = {
      full = {
        environment_id  = "env-xxxxxxxxxx"
        vcs_provider_id = "vcs-xxxxxxxxxx"

        vcs_repo = {
          identifier       = "org/repo"
          branch           = "main"
          trigger_prefixes = ["stage", "prod"]
        }

        hooks = {
          pre_plan   = "echo pre-plan"
          post_apply = "echo post-apply"
        }

        terragrunt = {
          version     = "0.55.0"
          use_run_all = true
        }
      }
    }
  }

  assert {
    condition     = length(scalr_workspace.this["full"].vcs_repo) == 1
    error_message = "Expected the vcs_repo block to render."
  }

  assert {
    condition     = scalr_workspace.this["full"].vcs_repo[0].identifier == "org/repo"
    error_message = "Expected the vcs_repo block to render with the given identifier."
  }

  assert {
    condition     = length(scalr_workspace.this["full"].hooks) == 1
    error_message = "Expected the hooks block to render."
  }

  assert {
    condition     = scalr_workspace.this["full"].hooks[0].pre_plan == "echo pre-plan"
    error_message = "Expected the hooks block to render with the given pre_plan hook."
  }

  assert {
    condition     = length(scalr_workspace.this["full"].terragrunt) == 1
    error_message = "Expected the terragrunt block to render."
  }

  assert {
    condition     = scalr_workspace.this["full"].terragrunt[0].version == "0.55.0"
    error_message = "Expected the terragrunt block to render with the given version."
  }
}

run "workspace_without_vcs_repo_hooks_or_terragrunt_renders_no_blocks" {
  command = plan

  variables {
    workspaces = {
      bare = {
        environment_id = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_workspace.this["bare"].vcs_repo) == 0
    error_message = "Expected zero vcs_repo blocks when vcs_repo is omitted."
  }

  assert {
    condition     = length(scalr_workspace.this["bare"].hooks) == 0
    error_message = "Expected zero hooks blocks when hooks is omitted."
  }

  assert {
    condition     = length(scalr_workspace.this["bare"].terragrunt) == 0
    error_message = "Expected zero terragrunt blocks when terragrunt is omitted."
  }
}

run "operations_selects_mode_when_execution_mode_unset" {
  command = plan

  variables {
    workspaces = {
      state_only = {
        environment_id = "env-xxxxxxxxxx"
        operations     = false
      }
    }
  }

  # execution_mode is unset by default, so a caller can set the deprecated operations field without
  # the module forcing a conflicting execution_mode = "remote". The plan succeeding (a populated ids
  # output) proves the combination is accepted; operations is asserted to confirm it is wired
  # through. (execution_mode is optional+computed, so its unset value is not deterministic under
  # mock_provider and is intentionally not asserted here.)
  assert {
    condition     = output.ids["state_only"] != null
    error_message = "A workspace setting operations with execution_mode left unset should plan successfully."
  }

  assert {
    condition     = scalr_workspace.this["state_only"].operations == false
    error_message = "operations should be forwarded to the resource."
  }
}

###########################################################
# Provider v3.20.0 arguments: remote_state_sharing and runner_image_version_id
###########################################################

run "remote_state_sharing_false_is_wired_through" {
  command = plan

  variables {
    workspaces = {
      private_state = {
        environment_id       = "env-xxxxxxxxxx"
        remote_state_sharing = false
      }
    }
  }

  assert {
    condition     = scalr_workspace.this["private_state"].remote_state_sharing == false
    error_message = "remote_state_sharing = false should be forwarded to the resource."
  }

  assert {
    condition     = output.remote_state_sharing["private_state"] == false
    error_message = "The remote_state_sharing output should surface the effective value (false)."
  }
}

run "remote_state_sharing_true_is_wired_through" {
  command = plan

  variables {
    workspaces = {
      shared_state = {
        environment_id       = "env-xxxxxxxxxx"
        remote_state_sharing = true
      }
    }
  }

  assert {
    condition     = scalr_workspace.this["shared_state"].remote_state_sharing == true
    error_message = "remote_state_sharing = true should be forwarded to the resource."
  }

  assert {
    condition     = output.remote_state_sharing["shared_state"] == true
    error_message = "The remote_state_sharing output should surface the effective value (true)."
  }
}

run "runner_image_version_id_is_wired_through" {
  command = plan

  variables {
    workspaces = {
      pinned_runner = {
        environment_id          = "env-xxxxxxxxxx"
        runner_image_version_id = "cimgv-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = scalr_workspace.this["pinned_runner"].runner_image_version_id == "cimgv-xxxxxxxxxx"
    error_message = "runner_image_version_id should be forwarded to the resource."
  }
}

run "runner_image_version_id_is_unset_by_default" {
  command = plan

  variables {
    workspaces = {
      default_runner = {
        environment_id = "env-xxxxxxxxxx"
      }
    }
  }

  # runner_image_version_id is optional and NOT computed, so leaving it out must leave it null and let
  # the account default runner image apply.
  assert {
    condition     = scalr_workspace.this["default_runner"].runner_image_version_id == null
    error_message = "runner_image_version_id should stay null when omitted."
  }
}

###########################################################
# Backward compatibility: deprecated remote_state_consumers
###########################################################

run "deprecated_remote_state_consumers_is_still_wired_through" {
  command = plan

  variables {
    workspaces = {
      legacy_all = {
        environment_id         = "env-xxxxxxxxxx"
        remote_state_consumers = ["*"]
      }
      legacy_specific = {
        environment_id         = "env-xxxxxxxxxx"
        remote_state_consumers = ["ws-aaaaaaaaaa", "ws-bbbbbbbbbb"]
      }
    }
  }

  assert {
    condition     = scalr_workspace.this["legacy_all"].remote_state_consumers == toset(["*"])
    error_message = "The deprecated remote_state_consumers = [\"*\"] should still be forwarded to the resource."
  }

  assert {
    condition     = scalr_workspace.this["legacy_specific"].remote_state_consumers == toset(["ws-aaaaaaaaaa", "ws-bbbbbbbbbb"])
    error_message = "The deprecated remote_state_consumers list should still be forwarded to the resource."
  }
}

run "conflict_check_is_per_entry_so_different_entries_may_use_either_style" {
  command = plan

  variables {
    workspaces = {
      legacy = {
        environment_id         = "env-xxxxxxxxxx"
        remote_state_consumers = ["ws-aaaaaaaaaa"]
      }
      modern = {
        environment_id       = "env-xxxxxxxxxx"
        remote_state_sharing = false
      }
    }
  }

  assert {
    condition     = length(scalr_workspace.this) == 2
    error_message = "One entry using the deprecated remote_state_consumers and another using remote_state_sharing should both plan."
  }

  assert {
    condition     = scalr_workspace.this["modern"].remote_state_sharing == false
    error_message = "The entry using remote_state_sharing should keep its own value."
  }

  assert {
    condition     = scalr_workspace.this["legacy"].remote_state_consumers == toset(["ws-aaaaaaaaaa"])
    error_message = "The entry using remote_state_consumers should keep its own value."
  }
}

run "empty_workspaces_map_plans_no_workspaces" {
  command = plan

  assert {
    condition     = length(scalr_workspace.this) == 0 && length(output.ids) == 0 && length(output.remote_state_sharing) == 0
    error_message = "An empty workspaces map should plan no workspaces and produce empty outputs."
  }
}
