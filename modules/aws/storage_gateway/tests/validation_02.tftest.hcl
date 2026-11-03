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



run "rejects_invalid_s3_smb_file_share_case_sensitivity" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn     = "arn:aws:s3:::corp-gateway-data/finance"
        case_sensitivity = "CaseInsensitive"
      }
    }
  }

  expect_failures = [var.s3_smb_file_shares]
}

run "rejects_invalid_s3_smb_file_share_default_storage_class" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn          = "arn:aws:s3:::corp-gateway-data/finance"
        default_storage_class = "GLACIER"
      }
    }
  }

  expect_failures = [var.s3_smb_file_shares]
}

run "rejects_invalid_s3_nfs_file_share_default_storage_class" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn          = "arn:aws:s3:::corp-gateway-data/archive"
        client_list           = ["10.0.0.0/16"]
        default_storage_class = "DEEP_ARCHIVE"
      }
    }
  }

  expect_failures = [var.s3_nfs_file_shares]
}

###########################
# gateway_timezone
###########################

run "rejects_malformed_gateway_timezone" {
  command = plan

  variables {
    gateway_timezone = "UTC-7"
  }

  expect_failures = [var.gateway_timezone]
}

# Real-world offsets run from GMT-12:00 to GMT+14:00, so the two ends are asymmetric.
run "rejects_negative_gateway_timezone_offset_beyond_twelve_hours" {
  command = plan

  variables {
    gateway_timezone = "GMT-13:00"
  }

  expect_failures = [var.gateway_timezone]
}

run "rejects_positive_gateway_timezone_offset_beyond_fourteen_hours" {
  command = plan

  variables {
    gateway_timezone = "GMT+15:00"
  }

  expect_failures = [var.gateway_timezone]
}

run "accepts_a_positive_gateway_timezone_offset" {
  command = plan

  variables {
    gateway_timezone = "GMT+5:30"
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].gateway_timezone == "GMT+5:30"
    error_message = "Expected a GMT+hh:mm offset to be accepted."
  }
}

# GMT+13:00 (Samoa/Tonga) and GMT+14:00 (Line Islands) are real zones the AWS console
# offers; an offset cap of 12 would wrongly reject them.
run "accepts_the_maximum_positive_gateway_timezone_offset" {
  command = plan

  variables {
    gateway_timezone = "GMT+14:00"
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].gateway_timezone == "GMT+14:00"
    error_message = "Expected GMT+14:00 to be accepted; it is a real time zone offset."
  }
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