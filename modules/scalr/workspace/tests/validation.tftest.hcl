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
