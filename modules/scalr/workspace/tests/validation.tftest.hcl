mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    workspaces = {
      baseline = {
        environment_id = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_workspace.this) == 1
    error_message = "Expected exactly one workspace to be planned."
  }
}

run "rejects_invalid_auto_queue_runs" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id  = "env-xxxxxxxxxx"
        auto_queue_runs = "not_a_real_value"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_invalid_execution_mode" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id = "env-xxxxxxxxxx"
        execution_mode = "not_a_real_value"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_invalid_iac_platform" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id = "env-xxxxxxxxxx"
        iac_platform   = "not_a_real_value"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_invalid_type" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id = "env-xxxxxxxxxx"
        type           = "not_a_real_value"
      }
    }
  }

  expect_failures = [var.workspaces]
}

###########################################################
# remote_state_consumers (deprecated) conflicts with remote_state_sharing
###########################################################

run "rejects_remote_state_consumers_together_with_remote_state_sharing_false" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id         = "env-xxxxxxxxxx"
        remote_state_consumers = ["ws-aaaaaaaaaa"]
        remote_state_sharing   = false
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_remote_state_consumers_together_with_remote_state_sharing_true" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id         = "env-xxxxxxxxxx"
        remote_state_consumers = ["*"]
        remote_state_sharing   = true
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_empty_remote_state_consumers_together_with_remote_state_sharing" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id         = "env-xxxxxxxxxx"
        remote_state_consumers = []
        remote_state_sharing   = false
      }
    }
  }

  # The provider treats an empty set as set, so it still conflicts with remote_state_sharing.
  expect_failures = [var.workspaces]
}

run "rejects_conflicting_entry_even_when_other_entries_are_valid" {
  command = plan

  variables {
    workspaces = {
      fine = {
        environment_id       = "env-xxxxxxxxxx"
        remote_state_sharing = false
      }
      broken = {
        environment_id         = "env-xxxxxxxxxx"
        remote_state_consumers = ["ws-aaaaaaaaaa"]
        remote_state_sharing   = true
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "accepts_remote_state_sharing_alone" {
  command = plan

  variables {
    workspaces = {
      modern = {
        environment_id       = "env-xxxxxxxxxx"
        remote_state_sharing = false
      }
    }
  }

  assert {
    condition     = length(scalr_workspace.this) == 1
    error_message = "remote_state_sharing without remote_state_consumers should plan successfully."
  }
}

run "accepts_deprecated_remote_state_consumers_alone" {
  command = plan

  variables {
    workspaces = {
      legacy = {
        environment_id         = "env-xxxxxxxxxx"
        remote_state_consumers = ["ws-aaaaaaaaaa"]
      }
    }
  }

  assert {
    condition     = length(scalr_workspace.this) == 1
    error_message = "The deprecated remote_state_consumers without remote_state_sharing should keep planning successfully (backward compatibility)."
  }
}

###########################################################
# runner_image_version_id must match the cimgv- ID format
###########################################################

run "accepts_runner_image_version_id_in_cimgv_format" {
  command = plan

  variables {
    workspaces = {
      pinned = {
        environment_id          = "env-xxxxxxxxxx"
        runner_image_version_id = "cimgv-v0abc123def456"
      }
    }
  }

  assert {
    condition     = length(scalr_workspace.this) == 1
    error_message = "A runner_image_version_id in the cimgv-<RANDOM STRING> format should plan successfully."
  }
}

run "rejects_runner_image_version_id_with_wrong_prefix" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id          = "env-xxxxxxxxxx"
        runner_image_version_id = "cimg-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_runner_image_version_id_that_is_a_different_resource_id" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id          = "env-xxxxxxxxxx"
        runner_image_version_id = "ws-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_runner_image_version_id_with_prefix_only" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id          = "env-xxxxxxxxxx"
        runner_image_version_id = "cimgv-"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_empty_runner_image_version_id" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id          = "env-xxxxxxxxxx"
        runner_image_version_id = ""
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_runner_image_version_id_with_trailing_whitespace" {
  command = plan

  variables {
    workspaces = {
      broken = {
        environment_id          = "env-xxxxxxxxxx"
        runner_image_version_id = "cimgv-xxxxxxxxxx "
      }
    }
  }

  expect_failures = [var.workspaces]
}

