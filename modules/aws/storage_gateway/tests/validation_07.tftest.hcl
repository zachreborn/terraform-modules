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



run "rejects_nfs_object_acl_that_is_not_a_canned_acl" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
        object_acl   = "everyone-full-control"
      }
    }
  }

  expect_failures = [var.s3_nfs_file_shares]
}

# A key without kms_encrypted is silently ignored by AWS in favour of SSE-S3, which
# would leave the caller believing their customer key is in use.
run "rejects_smb_share_kms_key_without_kms_encrypted" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
        kms_key_arn  = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
      }
    }
  }

  expect_failures = [var.s3_smb_file_shares]
}

run "rejects_nfs_share_kms_key_without_kms_encrypted" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn  = "arn:aws:s3:::corp-gateway-data/archive"
        client_list   = ["10.0.0.0/16"]
        kms_encrypted = false
        kms_key_arn   = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
      }
    }
  }

  expect_failures = [var.s3_nfs_file_shares]
}

run "accepts_the_three_year_cloudwatch_retention" {
  command = plan

  variables {
    cloudwatch_retention_in_days = 1096
  }

  assert {
    condition     = length(module.cloudwatch_log_group) == 1
    error_message = "Expected 1096 days (three years) to be accepted; CloudWatch Logs supports it."
  }
}

run "rejects_positive_timezone_offset_past_the_endpoint_minute" {
  command = plan

  variables {
    gateway_timezone = "GMT+14:59"
  }

  expect_failures = [var.gateway_timezone]
}

run "rejects_negative_timezone_offset_past_the_endpoint_minute" {
  command = plan

  variables {
    gateway_timezone = "GMT-12:59"
  }

  expect_failures = [var.gateway_timezone]
}

run "accepts_a_lowercase_gateway_id_in_the_gateway_arn" {
  command = plan

  variables {
    gateway_arn        = "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-12a3456b"
    gateway_ip_address = null
  }

  assert {
    condition     = output.gateway_id == "sgw-12a3456b"
    error_message = "Expected the gateway_arn validation to accept a lowercase hexadecimal gateway ID."
  }
}

run "rejects_gateway_name_longer_than_the_api_maximum" {
  command = plan

  variables {
    # 300 characters, comfortably past the documented 255-character maximum.
    gateway_name = join("", [for i in range(30) : "0123456789"])
  }

  expect_failures = [var.gateway_name]
}

###########################
# Prerequisite preconditions
###########################

run "rejects_create_iam_role_for_an_access_point_backed_share" {
  command = plan

  variables {
    gateway_type    = "FILE_S3"
    create_iam_role = true
    s3_bucket_arns  = ["arn:aws:s3:::corp-gateway-data"]

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:us-east-1:123456789012:accesspoint/corp-ap"
      }
    }
  }

  expect_failures = [data.aws_iam_policy_document.s3_access]
}

run "rejects_fsx_association_without_domain_join" {
  command = plan

  variables {
    gateway_type                  = "FILE_FSX_SMB"
    smb_active_directory_settings = null

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