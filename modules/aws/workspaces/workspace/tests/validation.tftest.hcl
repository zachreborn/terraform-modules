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

run "rejects_entry_with_both_directory_id_and_directory_key" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id  = "d-1234567890"
        directory_key = "corp"
        user_name     = "jdoe"
        bundle_id     = "wsb-bh8rsxt14"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_entry_with_neither_directory_id_nor_directory_key" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        user_name = "jdoe"
        bundle_id = "wsb-bh8rsxt14"
      }
    }
  }

  expect_failures = [var.workspaces]
}

run "rejects_invalid_directory_key_reference" {
  command = plan

  variables {
    enable_default_kms_key = false
    workspaces = {
      jdoe = {
        directory_key         = "does_not_exist"
        user_name             = "jdoe"
        bundle_id             = "wsb-bh8rsxt14"
        volume_encryption_key = "arn:aws:kms:us-east-1:123456789012:key/example"
      }
    }
  }

  expect_failures = [aws_workspaces_workspace.this]
}

run "resolves_valid_directory_key_via_directory_id_lookup" {
  command = plan

  variables {
    enable_default_kms_key = false
    directory_id_lookup = {
      corp = "d-1234567890"
    }
    workspaces = {
      jdoe = {
        directory_key         = "corp"
        user_name             = "jdoe"
        bundle_id             = "wsb-bh8rsxt14"
        volume_encryption_key = "arn:aws:kms:us-east-1:123456789012:key/example"
      }
    }
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].directory_id == "d-1234567890"
    error_message = "directory_key should resolve to the looked-up directory_id."
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

run "explicit_null_workspace_properties_falls_back_to_default" {
  command = plan

  # Terraform replaces an explicit null with the declared default for an optional(type, default)
  # attribute -- identical to omitting it entirely -- so this must not fail and must apply the same
  # defaults as omitting it. enable_default_kms_key = false + volume_encryption_key avoids exercising
  # the default_kms_key/aws_iam_policy_document path, which this test file doesn't mock.
  variables {
    enable_default_kms_key = false
    workspaces = {
      jdoe = {
        directory_id          = "d-1234567890"
        user_name             = "jdoe"
        bundle_id             = "wsb-bh8rsxt14"
        volume_encryption_key = "arn:aws:kms:us-east-1:123456789012:key/example"
        workspace_properties  = null
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_workspace.this) == 1
    error_message = "Expected exactly one workspace to be planned."
  }
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
