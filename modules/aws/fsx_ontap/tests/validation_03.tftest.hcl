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

# A valid MULTI_AZ_1 baseline so that only the variable/precondition under test fails.
variables {
  name                = "corp-ontap"
  storage_capacity    = 2048
  deployment_type     = "MULTI_AZ_1"
  subnet_ids          = ["subnet-0a1b2c3d", "subnet-4e5f6a7b"]
  preferred_subnet_id = "subnet-0a1b2c3d"
  route_table_ids     = ["rtb-0123456789abcdef0"]
  throughput_capacity = 512
}



run "rejects_invalid_kms_key_deletion_window_in_days" {
  command = plan
  variables { kms_key_deletion_window_in_days = 6 }
  expect_failures = [var.kms_key_deletion_window_in_days]
}

run "rejects_invalid_svm_root_volume_security_style" {
  command = plan
  variables {
    storage_virtual_machines = {
      smb = {
        root_volume_security_style = "POSIX"
      }
    }
  }
  expect_failures = [var.storage_virtual_machines]
}

run "rejects_invalid_volume_security_style" {
  command = plan
  variables {
    volumes = {
      data = {
        storage_virtual_machine_key = "smb"
        size_in_megabytes           = 1024
        security_style              = "POSIX"
      }
    }
  }
  expect_failures = [var.volumes]
}

run "rejects_invalid_volume_ontap_volume_type" {
  command = plan
  variables {
    volumes = {
      data = {
        storage_virtual_machine_key = "smb"
        size_in_megabytes           = 1024
        ontap_volume_type           = "LS"
      }
    }
  }
  expect_failures = [var.volumes]
}

run "rejects_invalid_volume_tiering_policy_name" {
  command = plan
  variables {
    volumes = {
      data = {
        storage_virtual_machine_key = "smb"
        size_in_megabytes           = 1024
        tiering_policy = {
          name = "SOMETIMES"
        }
      }
    }
  }
  expect_failures = [var.volumes]
}

run "rejects_volume_with_no_size" {
  command = plan
  variables {
    volumes = {
      data = {
        storage_virtual_machine_key = "smb"
      }
    }
  }
  expect_failures = [var.volumes]
}

run "rejects_volume_with_both_sizes" {
  command = plan
  variables {
    volumes = {
      data = {
        storage_virtual_machine_key = "smb"
        size_in_megabytes           = 1024
        size_in_bytes               = "1099511627776"
      }
    }
  }
  expect_failures = [var.volumes]
}

run "rejects_invalid_volume_style" {
  command = plan
  variables {
    volumes = {
      data = {
        storage_virtual_machine_key = "smb"
        size_in_megabytes           = 1024
        volume_style                = "FLEXCACHE"
      }
    }
  }
  expect_failures = [var.volumes]
}

run "rejects_invalid_snaplock_type" {
  command = plan
  variables {
    volumes = {
      data = {
        storage_virtual_machine_key = "smb"
        size_in_megabytes           = 1024
        snaplock_configuration = {
          snaplock_type = "IMMUTABLE"
        }
      }
    }
  }
  expect_failures = [var.volumes]
}

run "rejects_invalid_snaplock_privileged_delete" {
  command = plan
  variables {
    volumes = {
      data = {
        storage_virtual_machine_key = "smb"
        size_in_megabytes           = 1024
        snaplock_configuration = {
          snaplock_type     = "ENTERPRISE"
          privileged_delete = "MAYBE"
        }
      }
    }
  }
  expect_failures = [var.volumes]
}