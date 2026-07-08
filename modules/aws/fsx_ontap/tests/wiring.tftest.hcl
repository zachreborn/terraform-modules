mock_provider "aws" {
  mock_resource "aws_fsx_ontap_file_system" {
    defaults = {
      id  = "fs-0123456789abcdef0"
      arn = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
    }
  }

  mock_resource "aws_fsx_ontap_storage_virtual_machine" {
    defaults = {
      id = "svm-0123456789abcdef0"
    }
  }

  mock_resource "aws_fsx_ontap_volume" {
    defaults = {
      id = "fsvol-0123456789abcdef0"
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
      id = "alias/fsx_ontap-abcd1234"
    }
  }
}

variables {
  name                = "corp-ontap"
  storage_capacity    = 2048
  deployment_type     = "MULTI_AZ_1"
  subnet_ids          = ["subnet-0a1b2c3d", "subnet-4e5f6g7h"]
  preferred_subnet_id = "subnet-0a1b2c3d"
  route_table_ids     = ["rtb-0123456789abcdef0"]
  throughput_capacity = 512
}

run "generated_kms_key_flows_to_file_system_outputs" {
  command = plan

  assert {
    condition     = length(module.kms_key) == 1
    error_message = "Expected the kms child module to be instantiated by default."
  }

  assert {
    condition     = output.kms_key_arn == module.kms_key[0].arn
    error_message = "Expected the module's kms_key_arn output to reuse the kms child module's arn output."
  }

  assert {
    condition     = output.kms_key_id == module.kms_key[0].key_id
    error_message = "Expected the module's kms_key_id output to reuse the kms child module's key_id output."
  }
}

run "byo_kms_key_bypasses_kms_module" {
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
    condition     = output.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
    error_message = "Expected the caller-supplied kms_key_id to flow through as the kms_key_arn output."
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

run "volumes_are_wired_to_their_storage_virtual_machine" {
  command = plan

  variables {
    storage_virtual_machines = {
      smb = {
        svm_admin_password = "testpass" # gitleaks:allow
      }
    }
    volumes = {
      data = {
        storage_virtual_machine_key = "smb"
        junction_path               = "/data"
        size_in_megabytes           = 1024
      }
    }
  }

  assert {
    condition     = contains(keys(output.storage_virtual_machine_ids), "smb")
    error_message = "Expected the storage_virtual_machine_ids output to contain the smb SVM."
  }

  assert {
    condition     = contains(keys(output.volume_ids), "data")
    error_message = "Expected the volume_ids output to contain the data volume."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the wiring between this module and its kms child module (or the SVM/volume
# resources) has a bug, and fix the root cause in main.tf, then re-run `tofu test` until it
# passes for the right reason.
