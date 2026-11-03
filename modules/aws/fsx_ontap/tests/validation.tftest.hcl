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