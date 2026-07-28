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
  subnet_ids          = ["subnet-0a1b2c3d", "subnet-4e5f6a7b"]
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

# SINGLE_AZ_2 is the only deployment type built from more than one HA pair, and its valid
# per-HA-pair throughput values are 1536, 3072, and 6144. The earlier version of this case
# paired ha_pairs = 2 with MULTI_AZ_1 and 512 MB/s, which AWS rejects with a 400.
run "throughput_per_ha_pair_plans_successfully" {
  command = plan

  variables {
    deployment_type                 = "SINGLE_AZ_2"
    subnet_ids                      = ["subnet-0a1b2c3d"]
    route_table_ids                 = null
    throughput_capacity             = null
    throughput_capacity_per_ha_pair = 1536
    ha_pairs                        = 2
  }

  assert {
    condition     = aws_fsx_ontap_file_system.this.id != null
    error_message = "Expected a file system using throughput_capacity_per_ha_pair to plan successfully."
  }

  assert {
    condition     = aws_fsx_ontap_file_system.this.throughput_capacity_per_ha_pair == 1536
    error_message = "Expected the per-HA-pair throughput to flow to the file system."
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

# automatic_backup_retention_days = 0 is the provider's documented way to disable automatic
# backups; daily_automatic_backup_start_time should not carry its default alongside that.
run "disabling_automatic_backups_clears_the_start_time" {
  command = plan

  variables {
    automatic_backup_retention_days = 0
  }

  assert {
    condition     = aws_fsx_ontap_file_system.this.automatic_backup_retention_days == 0
    error_message = "Expected automatic_backup_retention_days to reach the file system as 0."
  }

  # daily_automatic_backup_start_time is optional+computed on the provider, so an explicit
  # null in the config still counts as "configured" for mocking purposes -- mock_resource
  # defaults only apply to attributes omitted entirely, and the framework rejects trying to
  # override a configured (even if null) attribute. That means the exact mocked value can't
  # be pinned down here, but a regression that passes the 23:59 default straight through
  # instead of nulling it out is still caught by this inequality check.
  assert {
    condition     = aws_fsx_ontap_file_system.this.daily_automatic_backup_start_time != "23:59"
    error_message = "Expected daily_automatic_backup_start_time to not be passed through as its 23:59 default when automatic backups are disabled."
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

# The four run blocks below exercise every optional block this module adds for §1 provider
# coverage on a successful plan, not just via expect_failures in validation.tftest.hcl. A
# validation test proves a guard rejects bad input; it does not prove the block renders
# correctly when the input is good.

run "svm_with_active_directory_configuration_plans_successfully" {
  command = plan

  variables {
    storage_virtual_machines = {
      smb = {
        svm_admin_password = "testpass1" # gitleaks:allow
        active_directory_configuration = {
          netbios_name = "CORP-ONTAP"
          self_managed_active_directory_configuration = {
            dns_ips                                = ["192.0.2.10", "192.0.2.11"]
            domain_name                            = "corp.example.com"
            username                               = "FSxServiceAccount"
            password                               = "testpass1" # gitleaks:allow
            file_system_administrators_group       = "FSx Admins"
            organizational_unit_distinguished_name = "OU=FSx,DC=corp,DC=example,DC=com"
          }
        }
      }
    }
  }

  assert {
    condition     = aws_fsx_ontap_storage_virtual_machine.this["smb"].active_directory_configuration[0].netbios_name == "CORP-ONTAP"
    error_message = "Expected netbios_name to reach the storage_virtual_machine resource."
  }

  assert {
    condition     = aws_fsx_ontap_storage_virtual_machine.this["smb"].active_directory_configuration[0].self_managed_active_directory_configuration[0].domain_name == "corp.example.com"
    error_message = "Expected the self-managed AD domain_name to reach the storage_virtual_machine resource."
  }

  assert {
    condition     = aws_fsx_ontap_storage_virtual_machine.this["smb"].active_directory_configuration[0].self_managed_active_directory_configuration[0].file_system_administrators_group == "FSx Admins"
    error_message = "Expected the optional file_system_administrators_group to reach the storage_virtual_machine resource."
  }
}

run "flexgroup_volume_with_aggregate_configuration_plans_successfully" {
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
        size_in_bytes               = "1099511627776"
        volume_style                = "FLEXGROUP"
        aggregate_configuration = {
          aggregates                 = ["aggr1", "aggr2"]
          constituents_per_aggregate = 4
        }
      }
    }
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].size_in_bytes == "1099511627776"
    error_message = "Expected size_in_bytes to reach the volume resource on the FlexGroup path."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].volume_style == "FLEXGROUP"
    error_message = "Expected volume_style to reach the volume resource."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].aggregate_configuration[0].constituents_per_aggregate == 4
    error_message = "Expected aggregate_configuration.constituents_per_aggregate to reach the volume resource."
  }

  assert {
    condition     = join(",", aws_fsx_ontap_volume.this["data"].aggregate_configuration[0].aggregates) == "aggr1,aggr2"
    error_message = "Expected aggregate_configuration.aggregates to reach the volume resource."
  }
}

run "worm_volume_with_snaplock_configuration_plans_successfully" {
  command = plan

  variables {
    storage_virtual_machines = {
      smb = {
        svm_admin_password = "testpass" # gitleaks:allow
      }
    }
    volumes = {
      archive = {
        storage_virtual_machine_key = "smb"
        size_in_megabytes           = 1024
        snaplock_configuration = {
          snaplock_type              = "ENTERPRISE"
          privileged_delete          = "DISABLED"
          audit_log_volume           = false
          volume_append_mode_enabled = true
          autocommit_period = {
            type  = "DAYS"
            value = 5
          }
          retention_period = {
            default_retention = {
              type  = "YEARS"
              value = 1
            }
            maximum_retention = {
              type  = "YEARS"
              value = 5
            }
            minimum_retention = {
              type  = "DAYS"
              value = 1
            }
          }
        }
      }
    }
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["archive"].snaplock_configuration[0].snaplock_type == "ENTERPRISE"
    error_message = "Expected snaplock_type to reach the volume resource."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["archive"].snaplock_configuration[0].autocommit_period[0].value == 5
    error_message = "Expected autocommit_period to reach the volume resource."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["archive"].snaplock_configuration[0].retention_period[0].default_retention[0].value == 1
    error_message = "Expected retention_period.default_retention to reach the volume resource."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["archive"].snaplock_configuration[0].retention_period[0].maximum_retention[0].value == 5
    error_message = "Expected retention_period.maximum_retention to reach the volume resource."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["archive"].snaplock_configuration[0].retention_period[0].minimum_retention[0].value == 1
    error_message = "Expected retention_period.minimum_retention to reach the volume resource."
  }
}

run "volume_with_name_override_and_tiering_policy_plans_successfully" {
  command = plan

  variables {
    storage_virtual_machines = {
      smb = {
        svm_admin_password = "testpass" # gitleaks:allow
      }
    }
    volumes = {
      data = {
        name                        = "sales-volume"
        storage_virtual_machine_key = "smb"
        size_in_megabytes           = 1024
        snapshot_policy             = "default"
        copy_tags_to_backups        = true
        storage_efficiency_enabled  = false
        final_backup_tags = {
          retain = "true"
        }
        tiering_policy = {
          name           = "AUTO"
          cooling_period = 31
        }
      }
    }
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].name == "sales-volume"
    error_message = "Expected the explicit name override to take precedence over the map key."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].snapshot_policy == "default"
    error_message = "Expected snapshot_policy to reach the volume resource."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].copy_tags_to_backups == true
    error_message = "Expected copy_tags_to_backups to reach the volume resource."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].storage_efficiency_enabled == false
    error_message = "Expected storage_efficiency_enabled to reach the volume resource."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].final_backup_tags["retain"] == "true"
    error_message = "Expected final_backup_tags to reach the volume resource."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].tiering_policy[0].name == "AUTO"
    error_message = "Expected tiering_policy.name to reach the volume resource."
  }

  assert {
    condition     = aws_fsx_ontap_volume.this["data"].tiering_policy[0].cooling_period == 31
    error_message = "Expected tiering_policy.cooling_period to reach the volume resource."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the module code has a bug and fix the root cause in main.tf / variables.tf /
# outputs.tf, then re-run `tofu test` until it passes for the right reason.
