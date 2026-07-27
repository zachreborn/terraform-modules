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
}

run "valid_baseline_does_not_fail" {
  command = plan

  assert {
    condition     = aws_storagegateway_gateway.this[0].arn != null
    error_message = "Expected the valid baseline to plan successfully."
  }
}

###########################
# gateway_arn
###########################

run "rejects_malformed_gateway_arn" {
  command = plan

  variables {
    gateway_arn        = "sgw-12A3456B"
    gateway_ip_address = null
  }

  expect_failures = [var.gateway_arn]
}

run "rejects_gateway_arn_for_the_wrong_service" {
  command = plan

  variables {
    gateway_arn        = "arn:aws:fsx:us-east-1:123456789012:gateway/sgw-12A3456B"
    gateway_ip_address = null
  }

  expect_failures = [var.gateway_arn]
}

run "rejects_gateway_arn_with_a_short_account_id" {
  command = plan

  variables {
    gateway_arn        = "arn:aws:storagegateway:us-east-1:12345:gateway/sgw-12A3456B"
    gateway_ip_address = null
  }

  expect_failures = [var.gateway_arn]
}

run "accepts_a_gateway_arn_in_a_non_commercial_partition" {
  command = plan

  variables {
    gateway_arn        = "arn:aws-us-gov:storagegateway:us-gov-west-1:123456789012:gateway/sgw-12A3456B"
    gateway_ip_address = null
  }

  assert {
    condition     = output.gateway_arn == "arn:aws-us-gov:storagegateway:us-gov-west-1:123456789012:gateway/sgw-12A3456B"
    error_message = "Expected the gateway_arn validation to accept partitions other than aws."
  }
}

###########################
# gateway_type
###########################

run "rejects_invalid_gateway_type" {
  command = plan

  variables {
    gateway_type = "STORED"
  }

  expect_failures = [var.gateway_type]
}

run "accepts_file_s3_gateway_type" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].gateway_type == "FILE_S3"
    error_message = "Expected FILE_S3 to be an accepted gateway_type."
  }
}

###########################
# smb_security_strategy
###########################

run "rejects_invalid_smb_security_strategy" {
  command = plan

  variables {
    smb_security_strategy = "MandatoryTls"
  }

  expect_failures = [var.smb_security_strategy]
}

###########################
# S3 file share enums
###########################

run "rejects_invalid_s3_smb_file_share_authentication" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn   = "arn:aws:s3:::corp-gateway-data/finance"
        authentication = "Kerberos"
      }
    }
  }

  expect_failures = [var.s3_smb_file_shares]
}

run "rejects_invalid_s3_nfs_file_share_squash" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
        squash       = "SomeSquash"
      }
    }
  }

  expect_failures = [var.s3_nfs_file_shares]
}

###########################
# CloudWatch retention
###########################

run "rejects_invalid_cloudwatch_retention_in_days" {
  command = plan

  variables {
    cloudwatch_retention_in_days = 45
  }

  expect_failures = [var.cloudwatch_retention_in_days]
}

run "accepts_zero_cloudwatch_retention_for_indefinite_logs" {
  command = plan

  variables {
    cloudwatch_retention_in_days = 0
  }

  assert {
    condition     = length(module.cloudwatch_log_group) == 1
    error_message = "Expected a retention of 0 (retain indefinitely) to be accepted."
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

run "rejects_maintenance_hour_of_day_out_of_range" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day = 24
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
    }
  }

  expect_failures = [var.maintenance_start_time]
}

run "rejects_maintenance_day_of_week_out_of_range" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day = 3
      day_of_week = 7
    }
  }

  expect_failures = [var.maintenance_start_time]
}

run "rejects_maintenance_day_of_month_out_of_range" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day  = 3
      day_of_month = 29
    }
  }

  expect_failures = [var.maintenance_start_time]
}

run "rejects_maintenance_window_with_both_day_of_week_and_day_of_month" {
  command = plan

  variables {
    maintenance_start_time = {
      hour_of_day  = 3
      day_of_week  = 6
      day_of_month = 15
    }
  }

  expect_failures = [var.maintenance_start_time]
}

###########################
# Resource preconditions
###########################

run "rejects_gateway_creation_without_activation_key_or_ip_address" {
  command = plan

  variables {
    activation_key     = null
    gateway_ip_address = null
  }

  expect_failures = [aws_storagegateway_gateway.this]
}

run "rejects_create_iam_role_without_bucket_arns" {
  command = plan

  variables {
    create_iam_role = true
    s3_bucket_arns  = []
  }

  expect_failures = [data.aws_iam_policy_document.s3_access]
}

run "rejects_smb_file_share_with_no_resolvable_role" {
  command = plan

  variables {
    gateway_type = "FILE_S3"

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
      }
    }
  }

  expect_failures = [aws_storagegateway_smb_file_share.this]
}

run "rejects_nfs_file_share_with_no_resolvable_role" {
  command = plan

  variables {
    gateway_type = "FILE_S3"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
      }
    }
  }

  expect_failures = [aws_storagegateway_nfs_file_share.this]
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that a validation or precondition in the module is wrong, and fix the root cause
# in variables.tf / main.tf, then re-run `tofu test` until it passes for the right reason.
