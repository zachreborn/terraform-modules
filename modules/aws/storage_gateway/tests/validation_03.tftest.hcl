mock_provider "aws" {
  mock_resource "aws_storagegateway_gateway" {
    defaults = {
      id  = "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-12A3456B"
      arn = "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-12A3456B"
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
      id = "alias/storage_gateway-abcd1234"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      id  = "/aws/storagegateway/abcd1234"
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/storagegateway/abcd1234"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::123456789012:role/storage-gateway-s3-abcd1234"
      name = "storage-gateway-s3-abcd1234"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/storage-gateway-s3-abcd1234"
    }
  }

  # See the note in baseline.tftest.hcl: the mock provider's random string for `json`
  # is rejected by the aws provider as "not a JSON object".
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
}

variables {
  gateway_name       = "corp-file-gateway"
  gateway_ip_address = "10.0.1.50"

  # SMB shares default to ActiveDirectory authentication and FSx associations are
  # served over SMB, so both require a domain-joined gateway. Supplied globally here
  # so each run exercises the validation it is named for rather than this precondition.
  smb_active_directory_settings = {
    domain_name = "corp.example.com"
    username    = "svc_join"
    password    = "testpass" # gitleaks:allow
  }
}



###########################
# KMS key deletion window
###########################

run "rejects_kms_key_deletion_window_below_minimum" {
  command = plan

  variables {
    kms_key_deletion_window_in_days = 6
  }

  expect_failures = [var.kms_key_deletion_window_in_days]
}

run "rejects_kms_key_deletion_window_above_maximum" {
  command = plan

  variables {
    kms_key_deletion_window_in_days = 31
  }

  expect_failures = [var.kms_key_deletion_window_in_days]
}

###########################
# maintenance_start_time
###########################

# Each case below is otherwise a complete, valid schedule so that exactly the rule
# under test is what fails. AWS requires hour, minute, and one cadence field.
run "rejects_maintenance_hour_of_day_out_of_range" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day    = 24
      minute_of_hour = 0
      day_of_week    = 1
    }
  }

  expect_failures = [var.maintenance_start_time]
}

run "rejects_maintenance_minute_of_hour_out_of_range" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day    = 3
      minute_of_hour = 60
      day_of_week    = 1
    }
  }

  expect_failures = [var.maintenance_start_time]
}

run "rejects_maintenance_day_of_week_out_of_range" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day    = 3
      minute_of_hour = 0
      day_of_week    = 7
    }
  }

  expect_failures = [var.maintenance_start_time]
}

run "rejects_maintenance_day_of_month_out_of_range" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day    = 3
      minute_of_hour = 0
      day_of_month   = 29
    }
  }

  expect_failures = [var.maintenance_start_time]
}

run "rejects_maintenance_window_with_both_day_of_week_and_day_of_month" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day    = 3
      minute_of_hour = 0
      day_of_week    = 6
      day_of_month   = 15
    }
  }

  expect_failures = [var.maintenance_start_time]
}

# AWS rejects an incomplete schedule outright, so neither cadence field is as
# invalid as both.
run "rejects_maintenance_window_with_neither_day_of_week_nor_day_of_month" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day    = 3
      minute_of_hour = 30
    }
  }

  expect_failures = [var.maintenance_start_time]
}

run "accepts_a_monthly_maintenance_window" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day    = 3
      minute_of_hour = 30
      day_of_month   = 28
    }
  }

  assert {
    condition     = one(aws_storagegateway_gateway.this[0].maintenance_start_time).day_of_month == "28"
    error_message = "Expected a monthly maintenance window to be accepted and passed through."
  }
}

###########################
# ARN formats
###########################

run "rejects_malformed_role_arn" {
  command = plan

  variables {
    role_arn = "arn:aws:iam:us-east-1:123456789012:role/byo-gateway-role"
  }

  expect_failures = [var.role_arn]
}