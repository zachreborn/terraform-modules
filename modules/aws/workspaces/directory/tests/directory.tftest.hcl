mock_provider "aws" {
  mock_resource "aws_workspaces_directory" {
    defaults = {
      id = "d-1234567890"
    }
  }
}

run "secure_defaults_are_applied_for_personal_directory" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
      }
    }
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].self_service_permissions[0].restart_workspace == true
    error_message = "restart_workspace should default to true."
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].self_service_permissions[0].rebuild_workspace == false
    error_message = "rebuild_workspace should default to false."
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].workspace_access_properties[0].device_type_web == "DENY"
    error_message = "device_type_web should default to DENY."
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].workspace_access_properties[0].device_type_zeroclient == "DENY"
    error_message = "device_type_zeroclient should default to DENY."
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].workspace_access_properties[0].device_type_windows == "ALLOW"
    error_message = "device_type_windows should default to ALLOW."
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].workspace_creation_properties[0].enable_internet_access == false
    error_message = "enable_internet_access should default to false."
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].workspace_creation_properties[0].enable_maintenance_mode == true
    error_message = "enable_maintenance_mode should default to true."
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].workspace_creation_properties[0].user_enabled_as_local_administrator == false
    error_message = "user_enabled_as_local_administrator should default to false."
  }
}

run "self_service_permissions_omitted_for_pools_directory" {
  command = plan

  variables {
    directories = {
      pool = {
        workspace_type                  = "POOLS"
        workspace_directory_name        = "Pool directory"
        workspace_directory_description = "WorkSpaces Pools directory"
        user_identity_type              = "CUSTOMER_MANAGED"
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_directory.this["pool"].self_service_permissions) == 0
    error_message = "self_service_permissions should not be set for a POOLS directory."
  }
}

run "enable_maintenance_mode_and_local_admin_are_forced_false_for_pools" {
  command = plan

  # Deliberately relies on the (PERSONAL-oriented) true default for enable_maintenance_mode, and also
  # explicitly requests user_enabled_as_local_administrator = true, to prove both are still coerced to
  # false for a POOLS entry -- aws_workspaces_directory's real CustomizeDiff hard-errors on either being
  # true when workspace_type = POOLS, which the mock provider used elsewhere in this file cannot exercise.
  variables {
    directories = {
      pool = {
        workspace_type                  = "POOLS"
        workspace_directory_name        = "Pool directory"
        workspace_directory_description = "WorkSpaces Pools directory"
        user_identity_type              = "CUSTOMER_MANAGED"
        workspace_creation_properties = {
          user_enabled_as_local_administrator = true
        }
      }
    }
  }

  assert {
    condition     = aws_workspaces_directory.this["pool"].workspace_creation_properties[0].enable_maintenance_mode == false
    error_message = "enable_maintenance_mode must be forced to false for POOLS directories, even though its default is true."
  }

  assert {
    condition     = aws_workspaces_directory.this["pool"].workspace_creation_properties[0].user_enabled_as_local_administrator == false
    error_message = "user_enabled_as_local_administrator must be forced to false for POOLS directories, even when explicitly requested true."
  }
}

run "saml_and_certificate_based_auth_are_wired_through" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
        saml_properties = {
          status          = "ENABLED"
          user_access_url = "https://sso.example.com/"
        }
        certificate_based_auth_properties = {
          status                    = "ENABLED"
          certificate_authority_arn = "arn:aws:acm-pca:us-east-1:123456789012:certificate-authority/example"
        }
      }
    }
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].saml_properties[0].status == "ENABLED"
    error_message = "saml_properties.status should be wired through."
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].certificate_based_auth_properties[0].status == "ENABLED"
    error_message = "certificate_based_auth_properties.status should be wired through."
  }
}

run "tags_merge_module_and_entry_tags" {
  command = plan

  variables {
    tags = {
      terraform = "true"
    }
    directories = {
      corp = {
        directory_id = "d-1234567890"
        tags = {
          team = "it"
        }
      }
    }
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].tags["terraform"] == "true"
    error_message = "Module-level tags should be present."
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].tags["team"] == "it"
    error_message = "Per-directory tags should be present."
  }
}

run "outputs_expose_keyed_map" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
      }
    }
  }

  assert {
    condition     = output.ids["corp"] == "d-1234567890"
    error_message = "ids output should reflect the mocked ID."
  }
}
