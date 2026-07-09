mock_provider "aws" {
  mock_resource "aws_workspaces_ip_group" {
    defaults = {
      id = "wsipg-488lrtl3k"
    }
  }

  mock_resource "aws_workspaces_directory" {
    defaults = {
      id = "d-9067783251"
    }
  }

  mock_resource "aws_workspaces_workspace" {
    defaults = {
      id            = "ws-9z9zmbkhv"
      ip_address    = "10.0.1.123"
      computer_name = "IP-1234ABCD"
      state         = "AVAILABLE"
    }
  }

  mock_resource "aws_workspaces_connection_alias" {
    defaults = {
      id = "rft-8012925589"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:us-east-1:123456789012:key/mock-key-id"
    }
  }

  mock_resource "aws_kms_alias" {
    defaults = {
      arn = "arn:aws:kms:us-east-1:123456789012:alias/workspaces"
    }
  }

  mock_data "aws_workspaces_bundle" {
    defaults = {
      id = "wsb-bh8rsxt14"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "service_role_enabled_by_default_creates_role" {
  command = plan

  assert {
    condition     = output.service_role_arn != null
    error_message = "service_role_arn should be non-null when enable_service_role defaults to true."
  }

  assert {
    condition     = length(module.service_role) == 1
    error_message = "Exactly one service_role submodule instance should be created by default."
  }
}

run "disabling_service_role_creates_no_role" {
  command = plan

  variables {
    enable_service_role = false
  }

  assert {
    condition     = output.service_role_arn == null
    error_message = "service_role_arn should be null when enable_service_role is false."
  }

  assert {
    condition     = length(module.service_role) == 0
    error_message = "No service_role submodule instance should be created."
  }
}

run "ip_group_keys_resolve_into_directory_ip_group_ids" {
  command = plan

  variables {
    ip_groups = {
      corporate_offices = {
        rules = [
          { source = "192.0.2.0/24" },
        ]
      }
    }
    directories = {
      corp = {
        directory_id  = "d-1234567890"
        ip_group_keys = ["corporate_offices"]
      }
    }
  }

  assert {
    condition     = output.directory_ids["corp"] != null
    error_message = "The directory referencing ip_group_keys should resolve using the wrapper's internal wiring."
  }
}

run "directory_key_resolves_into_workspace_directory_id" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
      }
    }
    workspaces = {
      jdoe = {
        directory_key = "corp"
        user_name     = "jdoe"
        bundle_id     = "wsb-bh8rsxt14"
      }
    }
  }

  assert {
    condition     = output.workspace_ids["jdoe"] != null
    error_message = "The workspace referencing directory_key should resolve using the wrapper's internal wiring."
  }
}

run "literal_directory_id_still_works_without_directory_key" {
  command = plan

  variables {
    enable_service_role = false
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_id    = "wsb-bh8rsxt14"
      }
    }
  }

  assert {
    condition     = output.workspace_ids["jdoe"] != null
    error_message = "A literal directory_id should still work without a directory_key."
  }
}

# Note: entries with both/neither of directory_id and directory_key, an invalid directory_key, and an
# invalid ip_group_keys entry are all rejected by the workspace/directory submodules' own variable
# validation and resource preconditions (see modules/aws/workspaces/workspace/tests/validation.tftest.hcl
# and modules/aws/workspaces/directory/tests/validation.tftest.hcl). They aren't re-tested here because
# those failures happen inside the nested submodules, which isn't a checkable object expect_failures can
# reference from this wrapper's tests.
run "full_kitchen_sink_example_plans_successfully" {
  command = plan

  variables {
    ip_groups = {
      corporate_offices = {
        rules = [
          { source = "192.0.2.0/24", description = "HQ" },
        ]
      }
    }

    directories = {
      corp = {
        directory_id  = "d-1234567890"
        subnet_ids    = ["subnet-aaaa1111", "subnet-bbbb2222"]
        ip_group_keys = ["corporate_offices"]
      }
    }

    connection_aliases = {
      primary = {
        connection_string = "workspaces.example.com"
      }
    }

    workspaces = {
      jdoe = {
        directory_key = "corp"
        user_name     = "jdoe"
        bundle_name   = "Value with Windows 10 (English)"
      }
      asmith = {
        directory_key = "corp"
        user_name     = "asmith"
        bundle_name   = "Amazon Linux 2"
      }
    }

    tags = {
      team = "it"
    }
  }

  assert {
    condition     = length(output.directory_ids) == 1
    error_message = "Expected 1 directory to be planned."
  }

  assert {
    condition     = length(output.workspace_ids) == 2
    error_message = "Expected 2 desktops to be planned."
  }

  assert {
    condition     = length(output.connection_alias_ids) == 1
    error_message = "Expected 1 connection alias to be planned."
  }

  assert {
    condition     = length(output.ip_group_ids) == 1
    error_message = "Expected 1 IP group to be planned."
  }
}
