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

run "valid_baseline_does_not_fail" {
  command = plan

  assert {
    condition     = aws_fsx_ontap_file_system.this.id != null
    error_message = "Expected the valid baseline to plan successfully."
  }
}

# ---- Variable validation failures ----

run "rejects_invalid_automatic_backup_retention_days" {
  command = plan
  variables { automatic_backup_retention_days = 91 }
  expect_failures = [var.automatic_backup_retention_days]
}

run "rejects_invalid_daily_automatic_backup_start_time" {
  command = plan
  variables { daily_automatic_backup_start_time = "25:00" }
  expect_failures = [var.daily_automatic_backup_start_time]
}

run "rejects_invalid_deployment_type" {
  command = plan
  variables { deployment_type = "TRIPLE_AZ_1" }
  expect_failures = [var.deployment_type]
}

run "rejects_invalid_disk_iops_configuration_mode" {
  command = plan
  variables {
    disk_iops_configuration = {
      mode = "SOMETIMES"
    }
  }
  expect_failures = [var.disk_iops_configuration]
}

run "rejects_user_provisioned_disk_iops_without_iops" {
  command = plan
  variables {
    disk_iops_configuration = {
      mode = "USER_PROVISIONED"
    }
  }
  expect_failures = [var.disk_iops_configuration]
}

run "rejects_invalid_ha_pairs" {
  command = plan
  variables { ha_pairs = 13 }
  expect_failures = [var.ha_pairs]
}

run "rejects_invalid_storage_capacity" {
  command = plan
  variables { storage_capacity = 512 }
  expect_failures = [var.storage_capacity]
}

run "rejects_invalid_storage_type" {
  command = plan
  variables { storage_type = "HDD" }
  expect_failures = [var.storage_type]
}

run "rejects_throughput_capacity_outside_the_api_range" {
  command = plan
  variables { throughput_capacity = 4 }
  expect_failures = [var.throughput_capacity]
}

# Values inside the API range but not valid for the deployment type are caught by the
# precondition rather than the variable validation, because the valid set depends on
# deployment_type and ha_pairs.
run "rejects_throughput_capacity_not_valid_for_the_deployment_type" {
  command = plan
  variables { throughput_capacity = 100 }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_gen2_throughput_on_a_gen1_deployment_type" {
  command = plan
  variables {
    deployment_type     = "MULTI_AZ_1"
    throughput_capacity = 3072
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_gen1_throughput_on_a_gen2_deployment_type" {
  command = plan
  variables {
    deployment_type     = "MULTI_AZ_2"
    throughput_capacity = 512
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

# 384 is valid only for MULTI_AZ_2. The previous flat validation rejected it outright, which
# made a supported configuration unreachable.
run "accepts_multi_az_2_only_throughput_value" {
  command = plan
  variables {
    deployment_type     = "MULTI_AZ_2"
    throughput_capacity = 384
  }

  assert {
    condition     = aws_fsx_ontap_file_system.this.throughput_capacity == 384
    error_message = "Expected 384 MB/s to be accepted on MULTI_AZ_2."
  }
}

run "rejects_invalid_throughput_capacity_per_ha_pair" {
  command = plan
  variables {
    throughput_capacity             = null
    throughput_capacity_per_ha_pair = 100
  }
  expect_failures = [var.throughput_capacity_per_ha_pair]
}

run "rejects_per_ha_pair_throughput_not_valid_for_the_deployment_type" {
  command = plan
  variables {
    deployment_type                 = "SINGLE_AZ_2"
    subnet_ids                      = ["subnet-0a1b2c3d"]
    route_table_ids                 = null
    throughput_capacity             = null
    throughput_capacity_per_ha_pair = 512
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

# A multi-HA-pair total must divide evenly into a valid per-pair value. 3072 / 2 = 1536,
# which SINGLE_AZ_2 supports.
run "accepts_a_multi_ha_pair_total_that_divides_into_a_valid_per_pair_value" {
  command = plan
  variables {
    deployment_type     = "SINGLE_AZ_2"
    subnet_ids          = ["subnet-0a1b2c3d"]
    route_table_ids     = null
    ha_pairs            = 2
    throughput_capacity = 3072
  }

  assert {
    condition     = aws_fsx_ontap_file_system.this.ha_pairs == 2
    error_message = "Expected a 2 HA pair file system with a valid total throughput to plan."
  }
}

run "rejects_a_total_that_does_not_divide_evenly_by_ha_pairs" {
  command = plan
  variables {
    deployment_type     = "SINGLE_AZ_2"
    subnet_ids          = ["subnet-0a1b2c3d"]
    route_table_ids     = null
    ha_pairs            = 5
    throughput_capacity = 3072
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_multiple_ha_pairs_on_a_deployment_type_that_does_not_support_them" {
  command = plan
  variables {
    ha_pairs            = 2
    throughput_capacity = 512
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_invalid_weekly_maintenance_start_time" {
  command = plan
  variables { weekly_maintenance_start_time = "8:99:00" }
  expect_failures = [var.weekly_maintenance_start_time]
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

# ---- Precondition failures (main.tf lifecycle) ----

run "rejects_byo_kms_key_without_kms_key_id" {
  command = plan
  variables {
    create_kms_key = false
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_both_throughput_options_set" {
  command = plan
  variables {
    throughput_capacity             = 512
    throughput_capacity_per_ha_pair = 512
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_neither_throughput_option_set" {
  command = plan
  variables {
    throughput_capacity             = null
    throughput_capacity_per_ha_pair = null
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_multi_az_with_single_subnet" {
  command = plan
  variables {
    subnet_ids = ["subnet-0a1b2c3d"]
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_single_az_with_two_subnets" {
  command = plan
  variables {
    deployment_type = "SINGLE_AZ_1"
    subnet_ids      = ["subnet-0a1b2c3d", "subnet-4e5f6a7b"]
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

# route_table_ids and endpoint_ip_address_range are documented as "(Multi-AZ only)" by the
# CreateFileSystemOntapConfiguration API reference; AWS returns a 400 for either on a
# SINGLE_AZ deployment type.
run "rejects_route_table_ids_on_single_az" {
  command = plan
  variables {
    deployment_type     = "SINGLE_AZ_1"
    subnet_ids          = ["subnet-0a1b2c3d"]
    preferred_subnet_id = "subnet-0a1b2c3d"
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_endpoint_ip_address_range_on_single_az" {
  command = plan
  variables {
    deployment_type           = "SINGLE_AZ_1"
    subnet_ids                = ["subnet-0a1b2c3d"]
    preferred_subnet_id       = "subnet-0a1b2c3d"
    route_table_ids           = null
    endpoint_ip_address_range = "203.0.113.0/24"
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_non_hex_subnet_id" {
  command = plan
  variables { subnet_ids = ["subnet-0a1b2c3d", "subnet-nothexvalue"] }
  expect_failures = [var.subnet_ids]
}

run "rejects_malformed_preferred_subnet_id" {
  command = plan
  variables { preferred_subnet_id = "sn-0a1b2c3d" }
  expect_failures = [var.preferred_subnet_id]
}

run "rejects_malformed_route_table_id" {
  command = plan
  variables { route_table_ids = ["route-table-0123456789abcdef0"] }
  expect_failures = [var.route_table_ids]
}

run "rejects_malformed_security_group_id" {
  command = plan
  variables { security_group_ids = ["sg-nothexvalue"] }
  expect_failures = [var.security_group_ids]
}

run "rejects_malformed_kms_key_id" {
  command = plan
  variables {
    create_kms_key = false
    kms_key_id     = "alias/corp-ontap"
  }
  expect_failures = [var.kms_key_id]
}

run "rejects_endpoint_ip_address_range_that_is_not_a_cidr" {
  command = plan
  variables { endpoint_ip_address_range = "198.19.0.1-198.19.0.64" }
  expect_failures = [var.endpoint_ip_address_range]
}

run "rejects_short_fsx_admin_password" {
  command = plan
  variables { fsx_admin_password = "short7c" } # gitleaks:allow
  expect_failures = [var.fsx_admin_password]
}

run "rejects_short_svm_admin_password" {
  command = plan
  variables {
    storage_virtual_machines = {
      smb = {
        svm_admin_password = "short7c" # gitleaks:allow
      }
    }
  }
  expect_failures = [var.storage_virtual_machines]
}

# Active Directory caps a computer object name at 15 characters.
run "rejects_netbios_name_longer_than_fifteen_characters" {
  command = plan
  variables {
    storage_virtual_machines = {
      smb = {
        svm_admin_password = "testpass1" # gitleaks:allow
        active_directory_configuration = {
          netbios_name = "CORP-ONTAP-SVM-01"
          self_managed_active_directory_configuration = {
            dns_ips     = ["10.11.1.100"]
            domain_name = "corp.example.com"
            username    = "FSxServiceAccount"
            password    = "testpass1" # gitleaks:allow
          }
        }
      }
    }
  }
  expect_failures = [var.storage_virtual_machines]
}

run "rejects_preferred_subnet_id_outside_subnet_ids" {
  command = plan
  variables {
    preferred_subnet_id = "subnet-99999999"
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

# A mistyped storage_virtual_machine_key must surface as this precondition rather than a
# bare "Invalid index" raised while the volume's arguments are evaluated, which is why
# main.tf resolves the SVM through lookup() instead of indexing the resource directly.
run "rejects_volume_referencing_an_unknown_storage_virtual_machine_key" {
  command = plan
  variables {
    storage_virtual_machines = {
      smb = {
        svm_admin_password = "testpass" # gitleaks:allow
      }
    }
    volumes = {
      data = {
        storage_virtual_machine_key = "typo"
        junction_path               = "/data"
        size_in_megabytes           = 1024
      }
    }
  }
  expect_failures = [aws_fsx_ontap_volume.this]
}

# Do NOT delete, skip, or loosen an expect_failures case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# validation {} / precondition {} block in variables.tf / main.tf has a bug, or the test's
# inputs are wrong -- find and fix the root cause, then re-run `tofu test` until it passes
# for the right reason.
