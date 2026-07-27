mock_provider "aws" {
  mock_resource "aws_fsx_ontap_file_system" {
    defaults = {
      id                    = "fs-0123456789abcdef0"
      arn                   = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
      dns_name              = "management.fs-0123456789abcdef0.fsx.us-east-1.amazonaws.com"
      network_interface_ids = ["eni-0123456789abcdef0", "eni-0fedcba9876543210"]
      owner_id              = "123456789012"
      vpc_id                = "vpc-0123456789abcdef0"
    }
  }

  mock_resource "aws_fsx_ontap_storage_virtual_machine" {
    defaults = {
      id   = "svm-0123456789abcdef0"
      arn  = "arn:aws:fsx:us-east-1:123456789012:storage-virtual-machine/fs-0123456789abcdef0/svm-0123456789abcdef0"
      uuid = "abcd1234-abcd-1234-abcd-abcd1234abcd"
    }
  }

  mock_resource "aws_fsx_ontap_volume" {
    defaults = {
      id   = "fsvol-0123456789abcdef0"
      arn  = "arn:aws:fsx:us-east-1:123456789012:volume/fs-0123456789abcdef0/fsvol-0123456789abcdef0"
      uuid = "efab5678-efab-5678-efab-efab5678efab"
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
  subnet_ids          = ["subnet-0a1b2c3d", "subnet-4e5f6a7b"]
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

run "file_system_attributes_flow_to_outputs" {
  command = plan

  assert {
    condition     = output.id == "fs-0123456789abcdef0"
    error_message = "Expected the id output to expose the file system's id attribute."
  }

  assert {
    condition     = output.arn == "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
    error_message = "Expected the arn output to expose the file system's arn attribute."
  }

  assert {
    condition     = output.dns_name == "management.fs-0123456789abcdef0.fsx.us-east-1.amazonaws.com"
    error_message = "Expected the dns_name output to expose the file system's dns_name attribute."
  }

  assert {
    condition     = output.owner_id == "123456789012"
    error_message = "Expected the owner_id output to expose the file system's owner_id attribute."
  }

  assert {
    condition     = output.vpc_id == "vpc-0123456789abcdef0"
    error_message = "Expected the vpc_id output to expose the file system's vpc_id attribute."
  }

  # Compared via join rather than a tuple literal: the provider types this attribute as
  # list(string), which never compares equal to an HCL tuple even with identical elements.
  assert {
    condition     = join(",", output.network_interface_ids) == "eni-0123456789abcdef0,eni-0fedcba9876543210"
    error_message = "Expected the network_interface_ids output to expose the file system's network_interface_ids attribute."
  }

  assert {
    condition     = output.endpoints == aws_fsx_ontap_file_system.this.endpoints
    error_message = "Expected the endpoints output to expose the file system's endpoints attribute."
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

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].storage_virtual_machine_id == aws_fsx_ontap_storage_virtual_machine.this["smb"].id
    error_message = "Expected the data volume to be wired to the smb SVM's id via storage_virtual_machine_key."
  }

  assert {
    condition     = aws_fsx_ontap_storage_virtual_machine.this["smb"].file_system_id == aws_fsx_ontap_file_system.this.id
    error_message = "Expected the smb SVM to be wired to the file system created by this module."
  }

  # Every SVM and volume output is keyed by the caller's logical name and carries the
  # corresponding resource attribute, so callers can index them by that same name.
  assert {
    condition     = output.storage_virtual_machine_arns["smb"] == aws_fsx_ontap_storage_virtual_machine.this["smb"].arn
    error_message = "Expected the storage_virtual_machine_arns output to expose the smb SVM's arn."
  }

  assert {
    condition     = output.storage_virtual_machine_uuids["smb"] == aws_fsx_ontap_storage_virtual_machine.this["smb"].uuid
    error_message = "Expected the storage_virtual_machine_uuids output to expose the smb SVM's uuid."
  }

  assert {
    condition     = output.storage_virtual_machine_endpoints["smb"] == aws_fsx_ontap_storage_virtual_machine.this["smb"].endpoints
    error_message = "Expected the storage_virtual_machine_endpoints output to expose the smb SVM's endpoints."
  }

  assert {
    condition     = output.storage_virtual_machine_ids["smb"] == aws_fsx_ontap_storage_virtual_machine.this["smb"].id
    error_message = "Expected the storage_virtual_machine_ids output to expose the smb SVM's id."
  }

  assert {
    condition     = output.volume_arns["data"] == aws_fsx_ontap_volume.this["data"].arn
    error_message = "Expected the volume_arns output to expose the data volume's arn."
  }

  assert {
    condition     = output.volume_uuids["data"] == aws_fsx_ontap_volume.this["data"].uuid
    error_message = "Expected the volume_uuids output to expose the data volume's uuid."
  }

  assert {
    condition     = output.volume_ids["data"] == aws_fsx_ontap_volume.this["data"].id
    error_message = "Expected the volume_ids output to expose the data volume's id."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the wiring between this module and its kms child module (or the SVM/volume
# resources) has a bug, and fix the root cause in main.tf, then re-run `tofu test` until it
# passes for the right reason.
