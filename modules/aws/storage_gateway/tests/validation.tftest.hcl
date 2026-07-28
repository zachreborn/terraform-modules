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
# ARN formats
###########################

run "rejects_malformed_role_arn" {
  command = plan

  variables {
    role_arn = "arn:aws:iam:us-east-1:123456789012:role/byo-gateway-role"
  }

  expect_failures = [var.role_arn]
}

run "rejects_non_role_iam_arn" {
  command = plan

  variables {
    role_arn = "arn:aws:iam::123456789012:user/somebody"
  }

  expect_failures = [var.role_arn]
}

run "rejects_bucket_arn_with_a_prefix" {
  command = plan

  variables {
    create_iam_role = true
    s3_bucket_arns  = ["arn:aws:s3:::corp-gateway-data/finance"]
  }

  expect_failures = [var.s3_bucket_arns]
}

run "rejects_bucket_arn_with_a_trailing_slash" {
  command = plan

  variables {
    create_iam_role = true
    s3_bucket_arns  = ["arn:aws:s3:::corp-gateway-data/"]
  }

  expect_failures = [var.s3_bucket_arns]
}

run "rejects_malformed_cloudwatch_log_group_arn" {
  command = plan

  variables {
    cloudwatch_log_group_arn = "arn:aws:logs:us-east-1:123456789012:/existing/gateway-logs"
  }

  expect_failures = [var.cloudwatch_log_group_arn]
}

run "rejects_kms_alias_for_the_log_group_key" {
  command = plan

  variables {
    create_kms_key = false
    kms_key_id     = "alias/my-log-key"
  }

  expect_failures = [var.kms_key_id]
}

run "rejects_malformed_file_system_association_location_arn" {
  command = plan

  variables {
    file_system_associations = {
      corp = {
        location_arn = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-nothex!"
        username     = "svc_gateway"
        password     = "testpass" # gitleaks:allow
      }
    }
  }

  expect_failures = [var.file_system_associations]
}

run "rejects_malformed_share_role_arn" {
  command = plan

  variables {
    gateway_type = "FILE_S3"

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
        role_arn     = "not-an-arn"
      }
    }
  }

  expect_failures = [var.s3_smb_file_shares]
}

# A share may be encrypted with an alias rather than a key ID, but it must be given in ARN
# form: the provider runs its own ARN check and rejects a bare alias/<name> even though the
# CreateSMBFileShare API accepts one.
run "accepts_a_kms_alias_arn_on_a_share" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn  = "arn:aws:s3:::corp-gateway-data/finance"
        kms_encrypted = true
        kms_key_arn   = "arn:aws:kms:us-east-1:123456789012:alias/corp-gateway"
      }
    }
  }

  assert {
    condition     = aws_storagegateway_smb_file_share.this["finance"].kms_key_arn == "arn:aws:kms:us-east-1:123456789012:alias/corp-gateway"
    error_message = "Expected a KMS alias ARN to be accepted as a share's kms_key_arn."
  }
}

run "rejects_a_bare_kms_alias_on_a_share" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn  = "arn:aws:s3:::corp-gateway-data/finance"
        kms_encrypted = true
        kms_key_arn   = "alias/corp-gateway"
      }
    }
  }

  expect_failures = [var.s3_smb_file_shares]
}

# The CreateSMBFileShare API documents an access point ARN as a valid LocationARN alongside a
# bucket ARN, so the validation must not assume the bucket form.
run "accepts_an_access_point_arn_as_a_share_location" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn    = "arn:aws:s3:us-east-1:123456789012:accesspoint/corp-ap/finance/"
        file_share_name = "finance"
      }
    }
  }

  assert {
    condition     = aws_storagegateway_smb_file_share.this["finance"].location_arn == "arn:aws:s3:us-east-1:123456789012:accesspoint/corp-ap/finance/"
    error_message = "Expected an S3 access point ARN to be accepted as a share location_arn."
  }
}

# The API accepts a bare access point alias, but the provider's own ARN check rejects it, so
# the module rejects it during plan with an actionable message rather than at apply.
run "rejects_an_access_point_alias_as_a_share_location" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn    = "test-ap-ab123cdef4gehijklmn5opqrstuvuse1a-s3alias"
        file_share_name = "finance"
      }
    }
  }

  expect_failures = [var.s3_smb_file_shares]
}

###########################
# Other formats
###########################

run "rejects_object_acl_that_is_not_a_canned_acl" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
        object_acl   = "bucket-owner-write"
      }
    }
  }

  expect_failures = [var.s3_smb_file_shares]
}

run "accepts_aws_exec_read_object_acl" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
        object_acl   = "aws-exec-read"
      }
    }
  }

  assert {
    condition     = aws_storagegateway_nfs_file_share.this["archive"].object_acl == "aws-exec-read"
    error_message = "Expected aws-exec-read to be an accepted object_acl."
  }
}

run "rejects_nfs_client_list_entry_that_is_not_an_ip_or_cidr" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["clients.corp.example.com"]
      }
    }
  }

  expect_failures = [var.s3_nfs_file_shares]
}

run "accepts_a_single_ipv4_address_in_the_nfs_client_list" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.1.25"]
      }
    }
  }

  assert {
    condition     = contains(aws_storagegateway_nfs_file_share.this["archive"].client_list, "10.0.1.25")
    error_message = "Expected a bare IPv4 address to be accepted in client_list."
  }
}

run "rejects_malformed_gateway_ip_address" {
  command = plan

  variables {
    gateway_ip_address = "10.0.1.256"
  }

  expect_failures = [var.gateway_ip_address]
}

run "rejects_single_character_gateway_name" {
  command = plan

  variables {
    gateway_name = "g"
  }

  expect_failures = [var.gateway_name]
}

run "rejects_activation_key_longer_than_the_api_maximum" {
  command = plan

  variables {
    gateway_ip_address = null
    activation_key     = "ABCDE-12345-FGHIJ-67890-KLMNO-PQRST-UVWXY-Z1234-56789"
  }

  expect_failures = [var.activation_key]
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

# The provider declares activation_key and gateway_ip_address ExactlyOneOf, so supplying
# both is as invalid as supplying neither.
run "rejects_supplying_both_activation_key_and_gateway_ip_address" {
  command = plan

  variables {
    activation_key     = "ABCDE-12345-FGHIJ-67890-KLMNO"
    gateway_ip_address = "206.7.1.205"
  }

  expect_failures = [aws_storagegateway_gateway.this]
}

###########################
# gateway_type pairing
###########################

run "rejects_file_system_association_on_an_s3_gateway" {
  command = plan

  variables {
    gateway_type = "FILE_S3"

    file_system_associations = {
      corp = {
        location_arn = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
        username     = "svc_gateway"
        password     = "testpass" # gitleaks:allow
      }
    }
  }

  expect_failures = [aws_storagegateway_file_system_association.this]
}

run "rejects_s3_smb_share_on_an_fsx_gateway" {
  command = plan

  variables {
    gateway_type = "FILE_FSX_SMB"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
      }
    }
  }

  expect_failures = [aws_storagegateway_smb_file_share.this]
}

run "rejects_s3_nfs_share_on_an_fsx_gateway" {
  command = plan

  variables {
    gateway_type = "FILE_FSX_SMB"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

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
