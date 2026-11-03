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