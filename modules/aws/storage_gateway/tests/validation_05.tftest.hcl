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