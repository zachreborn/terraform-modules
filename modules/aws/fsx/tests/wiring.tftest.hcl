mock_provider "aws" {
  mock_resource "aws_fsx_windows_file_system" {
    defaults = {
      id  = "fs-0123456789abcdef0"
      arn = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      id     = "1234abcd-12ab-34cd-56ef-1234567890ab"
      key_id = "1234abcd-12ab-34cd-56ef-1234567890ab"
      arn    = "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    }
  }

  mock_resource "aws_kms_alias" {
    defaults = {
      id = "alias/fsx_windows-abcd1234"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      id  = "/aws/fsx/windows_audit_abcd1234"
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/fsx/windows_audit_abcd1234"
    }
  }
}

variables {
  name                = "corp-file-share"
  subnet_ids          = ["subnet-0a1b2c3d"]
  active_directory_id = "d-0123456789"
}

run "generated_kms_key_flows_to_file_system_and_audit_log_group" {
  command = plan

  assert {
    condition     = length(module.kms_key) == 1
    error_message = "Expected the kms child module to be instantiated by default."
  }

  assert {
    condition     = length(module.audit_log_group) == 1
    error_message = "Expected the cloudwatch/log_group child module to be instantiated by default."
  }

  assert {
    condition     = output.kms_key_arn == module.kms_key[0].arn
    error_message = "Expected the module's kms_key_arn output to reuse the kms child module's arn output."
  }

  assert {
    condition     = output.kms_key_id == module.kms_key[0].key_id
    error_message = "Expected the module's kms_key_id output to reuse the kms child module's key_id output."
  }

  assert {
    condition     = output.audit_log_group_arn == module.audit_log_group[0].arn
    error_message = "Expected the module's audit_log_group_arn output to reuse the cloudwatch/log_group child module's arn output."
  }
}

run "byo_kms_key_bypasses_kms_module_but_still_flows_to_audit_log_group" {
  command = plan

  variables {
    create_kms_key = false
    kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "Expected no kms child module instance when create_kms_key is false."
  }

  assert {
    condition     = length(module.audit_log_group) == 1
    error_message = "Expected the cloudwatch/log_group child module to still be instantiated using the caller-supplied key."
  }

  assert {
    condition     = output.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
    error_message = "Expected the caller-supplied kms_key_id to flow through as the kms_key_arn output, which is also wired into the audit log group's kms_key_id."
  }
}

run "kms_key_settings_pass_through_to_child_module" {
  command = plan

  variables {
    kms_key_deletion_window_in_days = 10
    kms_key_enable_key_rotation     = false
    kms_key_description             = "custom description"
    kms_key_name_prefix             = "custom_prefix"
  }

  assert {
    condition     = length(module.kms_key) == 1
    error_message = "Expected the kms child module to be created with the custom settings."
  }

  assert {
    condition     = module.kms_key[0].arn != null
    error_message = "Expected the kms child module to expose a non-null arn."
  }
}

run "cloudwatch_settings_pass_through_to_child_module" {
  command = plan

  variables {
    cloudwatch_name_prefix       = "/aws/fsx/custom_prefix_"
    cloudwatch_retention_in_days = 30
  }

  assert {
    condition     = length(module.audit_log_group) == 1
    error_message = "Expected the cloudwatch/log_group child module to be created with the custom settings."
  }

  assert {
    condition     = module.audit_log_group[0].arn != null
    error_message = "Expected the cloudwatch/log_group child module to expose a non-null arn."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the wiring between this module and its kms / cloudwatch/log_group child
# modules has a bug, and fix the root cause in main.tf, then re-run `tofu test` until it
# passes for the right reason.
