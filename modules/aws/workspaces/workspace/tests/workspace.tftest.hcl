mock_provider "aws" {
  mock_resource "aws_workspaces_workspace" {
    defaults = {
      id            = "ws-9z9zmbkhv"
      ip_address    = "10.0.1.123"
      computer_name = "IP-1234ABCD"
      state         = "AVAILABLE"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:123456789012:key/mock-key-id"
      key_id = "mock-key-id"
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

run "bundle_id_passes_through_when_set" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_id    = "wsb-explicit-id"
      }
    }
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].bundle_id == "wsb-explicit-id"
    error_message = "Literal bundle_id should pass through unchanged."
  }
}

run "bundle_name_resolves_through_data_source_lookup" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_name  = "Amazon Linux 2"
      }
    }
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].bundle_id == "wsb-bh8rsxt14"
    error_message = "bundle_name should resolve to the mocked data source lookup result."
  }

  assert {
    condition     = data.aws_workspaces_bundle.lookup["Amazon Linux 2|AMAZON"].owner == "AMAZON"
    error_message = "bundle_owner should default to AMAZON."
  }
}

run "bundle_lookups_are_deduplicated_across_many_entries" {
  command = plan

  variables {
    workspaces = {
      jdoe   = { directory_id = "d-1234567890", user_name = "jdoe", bundle_name = "Amazon Linux 2" }
      asmith = { directory_id = "d-1234567890", user_name = "asmith", bundle_name = "Amazon Linux 2" }
      bwayne = { directory_id = "d-1234567890", user_name = "bwayne", bundle_name = "Amazon Linux 2" }
    }
  }

  assert {
    condition     = length(data.aws_workspaces_bundle.lookup) == 1
    error_message = "Three entries sharing the same bundle_name/bundle_owner should only trigger one data source lookup, not one per entry."
  }

  assert {
    condition     = alltrue([for k, v in aws_workspaces_workspace.this : v.bundle_id == "wsb-bh8rsxt14"])
    error_message = "Every entry sharing the deduplicated bundle should still resolve to the same bundle_id."
  }
}

run "default_kms_key_created_when_an_entry_needs_it" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_id    = "wsb-bh8rsxt14"
      }
    }
  }

  assert {
    condition     = length(module.default_kms_key) == 1
    error_message = "Exactly one default KMS key module instance should be created."
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].volume_encryption_key == module.default_kms_key["this"].arn
    error_message = "The shared default KMS key ARN should be used when volume_encryption_key is unset."
  }

  assert {
    condition     = output.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/mock-key-id"
    error_message = "kms_key_arn output should reflect the mocked default KMS key ARN."
  }
}

run "default_kms_key_not_created_when_every_entry_supplies_its_own_key" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id          = "d-1234567890"
        user_name             = "jdoe"
        bundle_id             = "wsb-bh8rsxt14"
        volume_encryption_key = "arn:aws:kms:us-east-1:123456789012:key/caller-supplied"
      }
    }
  }

  assert {
    condition     = length(module.default_kms_key) == 0
    error_message = "No default KMS key module instance should be created when every entry supplies its own key."
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].volume_encryption_key == "arn:aws:kms:us-east-1:123456789012:key/caller-supplied"
    error_message = "The caller-supplied volume_encryption_key should be used."
  }

  assert {
    condition     = output.kms_key_arn == null
    error_message = "kms_key_arn output should be null when no default key is created."
  }
}

run "default_kms_key_not_created_when_entry_disables_both_encryption_flags" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id                   = "d-1234567890"
        user_name                      = "jdoe"
        bundle_id                      = "wsb-bh8rsxt14"
        root_volume_encryption_enabled = false
        user_volume_encryption_enabled = false
      }
    }
  }

  assert {
    condition     = length(module.default_kms_key) == 0
    error_message = "No default KMS key module instance should be created when the only entry has both encryption flags disabled."
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].volume_encryption_key == null
    error_message = "volume_encryption_key should be null when both encryption flags are disabled, even though enable_default_kms_key defaults to true."
  }

  assert {
    condition     = output.kms_key_arn == null
    error_message = "kms_key_arn output should be null when no entry actually needs a key."
  }
}

run "default_kms_key_disabled_via_flag" {
  command = plan

  variables {
    enable_default_kms_key = false
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_id    = "wsb-bh8rsxt14"
      }
    }
  }

  assert {
    condition     = length(module.default_kms_key) == 0
    error_message = "No default KMS key module instance should be created when enable_default_kms_key is false."
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].volume_encryption_key == null
    error_message = "volume_encryption_key should be null so AWS falls back to its own default key."
  }
}

run "workspace_properties_defaults_are_applied" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_id    = "wsb-bh8rsxt14"
      }
    }
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].workspace_properties[0].compute_type_name == "STANDARD"
    error_message = "compute_type_name should default to STANDARD."
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].workspace_properties[0].running_mode == "AUTO_STOP"
    error_message = "running_mode should default to AUTO_STOP."
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].workspace_properties[0].running_mode_auto_stop_timeout_in_minutes == 60
    error_message = "running_mode_auto_stop_timeout_in_minutes should default to 60."
  }
}

run "running_mode_auto_stop_timeout_is_null_for_always_on" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_id    = "wsb-bh8rsxt14"
        workspace_properties = {
          running_mode = "ALWAYS_ON"
        }
      }
    }
  }

  # The provider schema represents this optional nested-block attribute's "unset" state as 0, not null,
  # so setting it to null (rather than the module's AUTO_STOP-oriented default of 60) for ALWAYS_ON makes
  # the config-time value match what AWS itself reports (0), eliminating the perpetual 0 -> 60 diff.
  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].workspace_properties[0].running_mode_auto_stop_timeout_in_minutes == 0
    error_message = "running_mode_auto_stop_timeout_in_minutes must resolve to 0 (not 60) for ALWAYS_ON to avoid a perpetual diff against AWS's reported value."
  }
}

run "tags_merge_module_and_entry_tags" {
  command = plan

  variables {
    tags = {
      terraform = "true"
    }
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_id    = "wsb-bh8rsxt14"
        tags = {
          team = "it"
        }
      }
    }
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].tags["terraform"] == "true"
    error_message = "Module-level tags should be present."
  }

  assert {
    condition     = aws_workspaces_workspace.this["jdoe"].tags["team"] == "it"
    error_message = "Per-desktop tags should be present."
  }
}

run "outputs_expose_keyed_maps" {
  command = plan

  variables {
    workspaces = {
      jdoe = {
        directory_id = "d-1234567890"
        user_name    = "jdoe"
        bundle_id    = "wsb-bh8rsxt14"
      }
    }
  }

  assert {
    condition     = output.ids["jdoe"] == "ws-9z9zmbkhv"
    error_message = "ids output should reflect the mocked ID."
  }

  assert {
    condition     = output.ip_addresses["jdoe"] == aws_workspaces_workspace.this["jdoe"].ip_address
    error_message = "ip_addresses output should reflect the resource's ip_address attribute."
  }

  assert {
    condition     = output.computer_names["jdoe"] == "IP-1234ABCD"
    error_message = "computer_names output should reflect the mocked computer name."
  }

  assert {
    condition     = output.states["jdoe"] == "AVAILABLE"
    error_message = "states output should reflect the mocked state."
  }

  assert {
    condition     = output.bundle_ids["jdoe"] == "wsb-bh8rsxt14"
    error_message = "bundle_ids output should reflect the resolved bundle ID."
  }
}
