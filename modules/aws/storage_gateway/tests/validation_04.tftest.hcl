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