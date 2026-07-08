mock_provider "aws" {
  mock_resource "aws_fsx_ontap_file_system" {
    defaults = {
      id                    = "fs-0123456789abcdef0"
      arn                   = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
      dns_name              = "fs-0123456789abcdef0.fsx.us-east-1.amazonaws.com"
      network_interface_ids = ["eni-0123456789abcdef0"]
      owner_id              = "123456789012"
      vpc_id                = "vpc-0123456789abcdef0"
    }
  }

  mock_resource "aws_fsx_ontap_storage_virtual_machine" {
    defaults = {
      id   = "svm-0123456789abcdef0"
      arn  = "arn:aws:fsx:us-east-1:123456789012:storage-virtual-machine/fs-0123456789abcdef0/svm-0123456789abcdef0"
      uuid = "abcd1234-12ab-34cd-56ef-1234567890ab"
    }
  }

  mock_resource "aws_fsx_ontap_volume" {
    defaults = {
      id   = "fsvol-0123456789abcdef0"
      arn  = "arn:aws:fsx:us-east-1:123456789012:volume/fs-0123456789abcdef0/fsvol-0123456789abcdef0"
      uuid = "efgh5678-12ab-34cd-56ef-1234567890ab"
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

run "multi_az_baseline_plans_successfully" {
  command = plan

  assert {
    condition     = aws_fsx_ontap_file_system.this.id != null
    error_message = "Expected exactly one FSx ONTAP file system to be planned."
  }

  assert {
    condition     = output.arn != null
    error_message = "Expected the arn output to be set."
  }

  assert {
    condition     = output.kms_key_arn != null
    error_message = "Expected a KMS key to be created and its ARN exposed by default."
  }
}

run "single_az_baseline_plans_successfully" {
  command = plan

  variables {
    deployment_type     = "SINGLE_AZ_1"
    subnet_ids          = ["subnet-0a1b2c3d"]
    preferred_subnet_id = "subnet-0a1b2c3d"
    route_table_ids     = null
  }

  assert {
    condition     = aws_fsx_ontap_file_system.this.id != null
    error_message = "Expected a SINGLE_AZ_1 file system to plan successfully."
  }
}

run "throughput_per_ha_pair_plans_successfully" {
  command = plan

  variables {
    throughput_capacity             = null
    throughput_capacity_per_ha_pair = 512
    ha_pairs                        = 2
  }

  assert {
    condition     = aws_fsx_ontap_file_system.this.id != null
    error_message = "Expected a file system using throughput_capacity_per_ha_pair to plan successfully."
  }
}

run "user_provisioned_disk_iops_plans_successfully" {
  command = plan

  variables {
    disk_iops_configuration = {
      mode = "USER_PROVISIONED"
      iops = 12288
    }
  }

  assert {
    condition     = aws_fsx_ontap_file_system.this.id != null
    error_message = "Expected a file system with user-provisioned IOPS to plan successfully."
  }
}

run "byo_kms_key_skips_kms_module" {
  command = plan

  variables {
    create_kms_key = false
    kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "Expected no KMS key module instance when create_kms_key is false."
  }

  assert {
    condition     = output.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
    error_message = "Expected kms_key_arn output to equal the caller-supplied kms_key_id."
  }

  assert {
    condition     = output.kms_key_id == null
    error_message = "Expected kms_key_id output to be null when a caller-supplied key is used."
  }
}

run "svm_and_volume_plan_successfully" {
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
    condition     = length(aws_fsx_ontap_storage_virtual_machine.this) == 1
    error_message = "Expected one Storage Virtual Machine to be planned."
  }

  assert {
    condition     = length(aws_fsx_ontap_volume.this) == 1
    error_message = "Expected one volume to be planned."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the module code has a bug and fix the root cause in main.tf / variables.tf /
# outputs.tf, then re-run `tofu test` until it passes for the right reason.
