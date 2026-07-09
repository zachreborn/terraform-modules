mock_provider "aws" {
  mock_resource "aws_workspaces_workspace" {
    defaults = {
      id = "ws-9z9zmbkhv"
    }
  }

  mock_data "aws_workspaces_bundle" {
    defaults = {
      id = "wsb-bh8rsxt14"
    }
  }
}

run "valid_baseline_with_bundle_id_does_not_fail" {
  command = plan

  variables {
    enable_default_kms_key = false
    workspaces = {
      jdoe = {
        directory_id          = "d-1234567890"
        user_name             = "jdoe"
        bundle_id             = "wsb-bh8rsxt14"
        volume_encryption_key = "arn:aws:kms:us-east-1:123456789012:key/example"
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_workspace.this) == 1
    error_message = "Expected exactly one workspace to be planned."
  }
}

run "valid_baseline_with_bundle_name_does_not_fail" {
  command = plan

  variables {
    enable_default_kms_key = false
    workspaces = {
      jdoe = {
        directory_id          = "d-1234567890"
        user_name             = "jdoe"
        bundle_name           = "Amazon Linux 2"
        volume_encryption_key = "arn:aws:kms:us-east-1:123456789012:key/example"
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_workspace.this) == 1
    error_message = "Expected exactly one workspace to be planned."
  }
}

run "rejects_entry_with_both_bundle_id_and_bundle_name" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_id    = "wsb-bh8rsxt14"
        bundle_name  = "Amazon Linux 2"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_entry_with_neither_bundle_id_nor_bundle_name" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_invalid_running_mode" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_id    = "wsb-bh8rsxt14"
        workspace_properties = {
          running_mode = "INVALID"
        }
      }
    }
  }

  expect_failures = [var.workspaces]
}
