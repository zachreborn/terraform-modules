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
  name       = "corp-file-share"
  subnet_ids = ["subnet-0a1b2c3d"]
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
  }

  assert {
    condition     = aws_fsx_windows_file_system.this.id != null
    error_message = "Expected the valid baseline to plan successfully."
  }
}

run "rejects_invalid_automatic_backup_retention_days" {
  command = plan

  variables {
    active_directory_id             = "d-0123456789"
    automatic_backup_retention_days = 91
  }

  expect_failures = [var.automatic_backup_retention_days]
}

run "rejects_invalid_daily_automatic_backup_start_time" {
  command = plan

  variables {
    active_directory_id               = "d-0123456789"
    daily_automatic_backup_start_time = "25:00"
  }

  expect_failures = [var.daily_automatic_backup_start_time]
}

run "rejects_invalid_deployment_type" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    deployment_type     = "TRIPLE_AZ_1"
  }

  expect_failures = [var.deployment_type]
}

run "rejects_invalid_disk_iops_configuration_mode" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    disk_iops_configuration = {
      mode = "SOMETIMES"
    }
  }

  expect_failures = [var.disk_iops_configuration]
}

run "rejects_user_provisioned_disk_iops_without_iops" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    disk_iops_configuration = {
      mode = "USER_PROVISIONED"
    }
  }

  expect_failures = [var.disk_iops_configuration]
}

run "rejects_invalid_storage_capacity" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    storage_capacity    = 16
  }

  expect_failures = [var.storage_capacity]
}

run "rejects_invalid_storage_type" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    storage_type        = "NVME"
  }

  expect_failures = [var.storage_type]
}

run "rejects_invalid_throughput_capacity_non_power_of_two" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    throughput_capacity = 100
  }

  expect_failures = [var.throughput_capacity]
}

run "rejects_invalid_weekly_maintenance_start_time" {
  command = plan

  variables {
    active_directory_id           = "d-0123456789"
    weekly_maintenance_start_time = "8:99:00"
  }

  expect_failures = [var.weekly_maintenance_start_time]
}

run "rejects_invalid_kms_key_deletion_window_in_days" {
  command = plan

  variables {
    active_directory_id             = "d-0123456789"
    kms_key_deletion_window_in_days = 6
  }

  expect_failures = [var.kms_key_deletion_window_in_days]
}

run "rejects_invalid_file_access_audit_log_level" {
  command = plan

  variables {
    active_directory_id         = "d-0123456789"
    file_access_audit_log_level = "MAYBE"
  }

  expect_failures = [var.file_access_audit_log_level]
}

run "rejects_invalid_file_share_access_audit_log_level" {
  command = plan

  variables {
    active_directory_id               = "d-0123456789"
    file_share_access_audit_log_level = "MAYBE"
  }

  expect_failures = [var.file_share_access_audit_log_level]
}

run "rejects_invalid_cloudwatch_retention_in_days" {
  command = plan

  variables {
    active_directory_id          = "d-0123456789"
    cloudwatch_retention_in_days = 42
  }

  expect_failures = [var.cloudwatch_retention_in_days]
}

run "rejects_self_managed_ad_with_no_credential_method" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips     = ["10.0.0.111"]
      domain_name = "corp.example.com"
    }
  }

  expect_failures = [var.self_managed_active_directory]
}

run "rejects_self_managed_ad_with_conflicting_credential_methods" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips                            = ["10.0.0.111"]
      domain_name                        = "corp.example.com"
      domain_join_service_account_secret = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fsx-join-abcdef"
      username                           = "FSxServiceAccount"
    }
  }

  expect_failures = [var.self_managed_active_directory]
}

run "rejects_self_managed_ad_with_both_password_and_password_wo" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips     = ["10.0.0.111"]
      domain_name = "corp.example.com"
      username    = "FSxServiceAccount"
      password    = "testpass"  # gitleaks:allow
      password_wo = "testpass2" # gitleaks:allow
    }
  }

  expect_failures = [var.self_managed_active_directory]
}

run "rejects_self_managed_ad_password_wo_without_version" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips     = ["10.0.0.111"]
      domain_name = "corp.example.com"
      username    = "FSxServiceAccount"
      password_wo = "testpass" # gitleaks:allow
    }
  }

  expect_failures = [var.self_managed_active_directory]
}

run "rejects_both_active_directory_options_set" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    self_managed_active_directory = {
      dns_ips     = ["10.0.0.111"]
      domain_name = "corp.example.com"
      username    = "FSxServiceAccount"
      password    = "testpass" # gitleaks:allow
    }
  }

  expect_failures = [aws_fsx_windows_file_system.this]
}

run "rejects_neither_active_directory_option_set" {
  command = plan

  expect_failures = [aws_fsx_windows_file_system.this]
}

run "rejects_byo_kms_key_without_kms_key_id" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    create_kms_key      = false
  }

  expect_failures = [aws_fsx_windows_file_system.this]
}

run "rejects_hdd_storage_below_minimum_capacity" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    storage_type        = "HDD"
    storage_capacity    = 1000
    deployment_type     = "SINGLE_AZ_2"
  }

  expect_failures = [aws_fsx_windows_file_system.this]
}

run "rejects_multi_az_with_single_subnet" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    deployment_type     = "MULTI_AZ_1"
    preferred_subnet_id = "subnet-0a1b2c3d"
  }

  expect_failures = [aws_fsx_windows_file_system.this]
}

run "rejects_single_az_with_two_subnets" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    subnet_ids          = ["subnet-0a1b2c3d", "subnet-4e5f6g7h"]
  }

  expect_failures = [aws_fsx_windows_file_system.this]
}

# Do NOT delete, skip, or loosen an expect_failures case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# validation {} / precondition {} block in variables.tf / main.tf has a bug, or the test's
# inputs are wrong -- find and fix the root cause, then re-run `tofu test` until it passes
# for the right reason.
